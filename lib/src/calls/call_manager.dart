import 'dart:async';
import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../core/client.dart';
import 'webrtc.dart';
import 'signaling.dart';
import '../xmpp/xmpp_client.dart';
import '../core/exceptions.dart';

/// Call state enum
enum CallState {
  idle,
  calling,
  incoming,
  connected,
  ended,
}

/// Call Manager - Orchestrates full P2P call flow
class CallManager {
  final NexaconClient _client;
  WebRTCService? _webrtcService;
  SignalingService? _signalingService;
  XmppClient? _xmppClient;

  String? _currentRoomId;
  String? _currentCallId;
  String? _myJid;
  String? _myName;
  String? _peerJid;
  CallState _callState = CallState.idle;
  Completer<void>? _callResponseCompleter;

  // Callbacks
  final Function(CallState)? onCallStateChanged;
  final Function(String)? onIncomingCall;
  final Function(String)? onCallEnded;
  final Function(String)? onError;
  final Function(MediaStream)? onLocalStream;
  final Function(MediaStream)? onRemoteStream;

  CallManager(
    this._client, {
    this.onCallStateChanged,
    this.onIncomingCall,
    this.onCallEnded,
    this.onError,
    this.onLocalStream,
    this.onRemoteStream,
  });

  /// Initialize the call manager with NX credentials
  /// This will connect to NX server and handle signaling internally
  Future<bool> initialize({
    required String nxid,
    required String nxtoken,
    required String wsUrl,
    String? name,
  }) async {
    _myJid = nxid;
    _myName = name ?? nxid.split('@')[0];

    // Initialize NX client
    _xmppClient = XmppClient();
    final connected = await _xmppClient!.connect(
      jid: nxid,
      password: nxtoken,
      wsUrl: wsUrl,
    );

    if (!connected) {
      onError?.call('Failed to connect to NX server');
      return false;
    }

    // Listen for NX messages
    _xmppClient!.messageStream.listen((message) {
      if (message.body != null) {
        try {
          final data = jsonDecode(message.body!);
          final signalingMessage = SignalingMessage.fromJson(data);
          _handleSignalingMessage(signalingMessage);
        } catch (e) {
          print('Error parsing NX message: $e');
        }
      }
    });

    // Initialize signaling service with NX send capability
    _signalingService = SignalingService(
      onMessageReceived: _handleSignalingMessage,
      onSendMessage: (message) {
        // Send via NX to peer
        if (_peerJid != null) {
          _xmppClient?.sendMessage(_peerJid!, message);
        }
      },
    );

    // Initialize WebRTC service
    _webrtcService = WebRTCService(
      onLocalStream: onLocalStream,
      onRemoteStream: onRemoteStream,
      onIceCandidate: (candidate) {
        // Send ICE candidate via signaling
        if (_currentRoomId != null) {
          _signalingService?.sendMessage(
            _signalingService!.createIceCandidate(
              roomId: _currentRoomId!,
              candidate: candidate['candidate'],
              sdpMid: candidate['sdpMid'],
              sdpMLineIndex: candidate['sdpMLineIndex'],
            ),
          );
        }
      },
      onCallEnded: (reason) {
        _endCall(reason);
      },
    );

    return true;
  }

  /// Get current call state
  CallState get callState => _callState;

  /// Get current room ID
  String? get currentRoomId => _currentRoomId;

  /// Get current call ID
  String? get currentCallId => _currentCallId;

  /// Get WebRTC service instance (for UI integration)
  WebRTCService? get webrtcService => _webrtcService;

  /// Get current call duration
  Duration get callDuration => _webrtcService?.callDuration ?? Duration.zero;

  /// Initiate an outgoing P2P call
  Future<void> initiateCall({
    required String to,
    bool audio = true,
    bool video = true,
  }) async {
    if (_callState != CallState.idle) {
      throw ValidationException('Call already in progress');
    }

    try {
      _setCallState(CallState.calling);

      _currentRoomId = 'call_${DateTime.now().millisecondsSinceEpoch}';

      // Initiate call via API (sends FCM + XMPP)
      final response = await _client.calls.initiateP2PCall(
        to: to,
        room: _currentRoomId,
      );

      _currentCallId = response['call_id'];
      _peerJid = to;

      // Send XMPP call invitation
      _signalingService?.sendMessage(
        _signalingService!.createCallInvitation(
          roomId: _currentRoomId!,
          callType: video ? 'video' : 'audio',
          fromJid: _myJid!,
          fromName: _myName!,
        ),
      );

      // Wait for callee to accept (timeout 60s)
      await _waitForCallResponse();

      // Callee accepted — now set up WebRTC and send offer
      await _setupWebRTCAndCreateOffer(audio: audio, video: video);
    } catch (e) {
      _setCallState(CallState.idle);
      onError?.call('Failed to initiate call: $e');
      rethrow;
    }
  }

  /// Set up WebRTC peer connection and create offer (caller side)
  Future<void> _setupWebRTCAndCreateOffer({
    bool audio = true,
    bool video = true,
  }) async {
    try {
      final credentials = await _client.calls.getWebRTCCredentials();
      final iceServers = (credentials['ice_servers'] as List<dynamic>?) ?? [];
      iceServers.add({'urls': 'stun:stun.l.google.com:19302'});

      await _webrtcService?.initializePeerConnection(
        iceServers.cast<Map<String, dynamic>>(),
      );

      await _webrtcService?.getUserMedia(audio: audio, video: video);
      await _webrtcService?.addLocalStream();

      final offer = await _webrtcService?.createOffer();
      if (offer != null) {
        _signalingService?.sendMessage(
          _signalingService!.createWebRTCOffer(
            roomId: _currentRoomId!,
            sdp: offer.sdp ?? '',
            sdpType: offer.type ?? 'offer',
          ),
        );
      }
    } catch (e) {
      _endCall('Failed to setup WebRTC: $e');
      onError?.call('Failed to setup WebRTC: $e');
    }
  }

  /// Handle incoming call invitation
  void handleIncomingCall(SignalingMessage message) {
    if (_callState != CallState.idle) {
      // Reject if already in a call
      _peerJid = message.data['fromJid'];
      _signalingService?.sendMessage(
        _signalingService!.createCallResponse(
          roomId: message.data['roomId'],
          accepted: false,
        ),
      );
      return;
    }

    _currentRoomId = message.data['roomId'];
    _peerJid = message.data['fromJid'];
    _setCallState(CallState.incoming);

    onIncomingCall?.call(message.data['fromName'] ?? 'Unknown');
  }

  /// Accept an incoming call
  Future<void> acceptCall({
    bool audio = true,
    bool video = true,
  }) async {
    if (_callState != CallState.incoming || _currentRoomId == null) {
      throw ValidationException('No incoming call to accept');
    }

    try {
      // Notify caller we accepted
      _signalingService?.sendMessage(
        _signalingService!.createCallResponse(
          roomId: _currentRoomId!,
          accepted: true,
        ),
      );

      _setCallState(CallState.calling);

      // Set up WebRTC as callee — offer will arrive via _handleWebRTCOffer
      final credentials = await _client.calls.getWebRTCCredentials();
      final iceServers = (credentials['ice_servers'] as List<dynamic>?) ?? [];
      iceServers.add({'urls': 'stun:stun.l.google.com:19302'});

      await _webrtcService?.initializePeerConnection(
        iceServers.cast<Map<String, dynamic>>(),
      );

      await _webrtcService?.getUserMedia(audio: audio, video: video);
      await _webrtcService?.addLocalStream();

      // Answer is created in _handleWebRTCOffer when offer arrives
    } catch (e) {
      _endCall('Failed to accept call: $e');
      onError?.call('Failed to accept call: $e');
      rethrow;
    }
  }

  /// Reject an incoming call
  void rejectCall() {
    if (_callState != CallState.incoming || _currentRoomId == null) {
      return;
    }

    _signalingService?.sendMessage(
      _signalingService!.createCallResponse(
        roomId: _currentRoomId!,
        accepted: false,
      ),
    );

    _setCallState(CallState.idle);
    _currentRoomId = null;
  }

  /// End the current call
  Future<void> endCall() async {
    if (_currentRoomId == null) return;

    // Send call end message
    _signalingService?.sendMessage(
      _signalingService!.createCallEnd(roomId: _currentRoomId!),
    );

    await _webrtcService?.endCall();
    _endCall('Call ended by user');
  }

  /// Toggle audio
  void toggleAudio(bool enabled) {
    _webrtcService?.toggleAudio(enabled);
  }

  /// Toggle video
  void toggleVideo(bool enabled) {
    _webrtcService?.toggleVideo(enabled);
  }

  /// Switch camera
  Future<void> switchCamera() async {
    await _webrtcService?.switchCamera();
  }

  /// Handle signaling message from XMPP
  void _handleSignalingMessage(SignalingMessage message) {
    switch (message.type) {
      case SignalingMessageType.callInvitation:
        handleIncomingCall(message);
        break;

      case SignalingMessageType.callResponse:
        _handleCallResponse(message);
        break;

      case SignalingMessageType.callEnd:
        _endCall('Call ended by remote party');
        break;

      case SignalingMessageType.webrtcOffer:
        _handleWebRTCOffer(message);
        break;

      case SignalingMessageType.webrtcAnswer:
        _handleWebRTCAnswer(message);
        break;

      case SignalingMessageType.webrtcIceCandidate:
        _handleIceCandidate(message);
        break;
    }
  }

  /// Handle call response — just completes the waiting completer
  void _handleCallResponse(SignalingMessage message) {
    if (_callResponseCompleter != null &&
        !_callResponseCompleter!.isCompleted) {
      if (message.data['accepted'] != true) {
        _callResponseCompleter!.completeError('Call rejected');
      } else {
        _callResponseCompleter!.complete();
      }
    } else if (message.data['accepted'] != true) {
      _endCall('Call rejected');
    }
  }

  /// Handle WebRTC offer
  Future<void> _handleWebRTCOffer(SignalingMessage message) async {
    try {
      await _webrtcService?.setRemoteDescription({
        'sdp': message.data['sdp'],
        'type': message.data['sdp_type'],
      });

      // Create and send answer
      final answer = await _webrtcService?.createAnswer();
      if (answer != null) {
        _signalingService?.sendMessage(
          _signalingService!.createWebRTCAnswer(
            roomId: _currentRoomId!,
            sdp: answer.sdp ?? '',
            sdpType: answer.type ?? 'answer',
          ),
        );
      }

      _setCallState(CallState.connected);
    } catch (e) {
      _endCall('Failed to handle offer: $e');
      onError?.call('Failed to handle offer: $e');
    }
  }

  /// Handle WebRTC answer
  Future<void> _handleWebRTCAnswer(SignalingMessage message) async {
    try {
      await _webrtcService?.setRemoteDescription({
        'sdp': message.data['sdp'],
        'type': message.data['sdp_type'],
      });

      _setCallState(CallState.connected);
    } catch (e) {
      _endCall('Failed to handle answer: $e');
      onError?.call('Failed to handle answer: $e');
    }
  }

  /// Handle ICE candidate
  Future<void> _handleIceCandidate(SignalingMessage message) async {
    try {
      await _webrtcService?.addIceCandidate({
        'candidate': message.data['candidate'],
        'sdpMid': message.data['sdpMid'],
        'sdpMLineIndex': message.data['sdpMLineIndex'],
      });
    } catch (e) {
      print('Failed to add ICE candidate: $e');
    }
  }

  /// Wait for call response (with timeout)
  Future<void> _waitForCallResponse() async {
    _callResponseCompleter = Completer<void>();
    final timeout = Timer(const Duration(seconds: 60), () {
      if (_callResponseCompleter != null &&
          !_callResponseCompleter!.isCompleted) {
        _callResponseCompleter!.completeError('Call response timeout');
      }
    });

    try {
      await _callResponseCompleter!.future;
    } finally {
      timeout.cancel();
      _callResponseCompleter = null;
    }
  }

  /// End call and cleanup
  void _endCall(String reason) {
    _webrtcService?.endCall();
    _setCallState(CallState.ended);
    onCallEnded?.call(reason);

    // Reset state after delay
    Future.delayed(const Duration(seconds: 1), () {
      _setCallState(CallState.idle);
      _currentRoomId = null;
      _currentCallId = null;
    });
  }

  /// Set call state and notify listeners
  void _setCallState(CallState state) {
    _callState = state;
    onCallStateChanged?.call(state);
  }

  /// Cleanup resources
  void dispose() {
    _webrtcService?.endCall();
    _xmppClient?.disconnect();
    _xmppClient?.dispose();
    _setCallState(CallState.idle);
  }
}
