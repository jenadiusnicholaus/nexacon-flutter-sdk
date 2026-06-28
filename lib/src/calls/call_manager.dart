import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../core/client.dart';
import '../core/xmpp_manager.dart';
import 'calls.dart';
import 'webrtc.dart';
import 'signaling.dart';
import '../core/exceptions.dart';

/// Call state enum
enum CallState { idle, calling, incoming, connected, ended }

/// Call Manager - Orchestrates full P2P call flow
class CallManager {
  final NexaconClient _client;
  final XmppManager _nxManager;
  WebRTCService? _webrtcService;
  SignalingService? _signalingService;

  String? _currentRoomId;
  String? _currentCallId;
  String? _myJid;
  String? _myName;
  String? _peerJid;
  CallType? _callType;
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
    this._client,
    this._nxManager, {
    this.onCallStateChanged,
    this.onIncomingCall,
    this.onCallEnded,
    this.onError,
    this.onLocalStream,
    this.onRemoteStream,
  });

  /// Initialize the call manager with NX credentials
  /// Uses the global XmppManager for signaling
  Future<bool> initialize({
    required String nxid,
    required String nxtoken,
    required String wsUrl,
    String? name,
  }) async {
    _myJid = nxid;
    _myName = name ?? nxid.split('@')[0];

    // Connect via global XMPP manager
    final connected = await _nxManager.connect(
      jid: nxid,
      password: nxtoken,
      wsUrl: wsUrl,
    );

    if (!connected) {
      onError?.call('Failed to connect to NX server');
      return false;
    }

    // Listen for signaling messages from global XMPP
    _nxManager.signalingStream.listen((data) {
      try {
        final signalingMessage = SignalingMessage.fromJson(data);
        _handleSignalingMessage(signalingMessage);
      } catch (e) {
        print('Error parsing signaling message: $e');
      }
    });

    // Initialize signaling service with XMPP send capability
    _signalingService = SignalingService(
      onMessageReceived: _handleSignalingMessage,
      onSendMessage: (message) {
        // Send via global XMPP to peer
        if (_peerJid != null) {
          _nxManager.sendMessage(_peerJid!, message);
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

  /// Get call statistics stream
  Stream<Map<String, dynamic>>? get callStatsStream =>
      _webrtcService?.statsStream;

  /// Get latest call statistics snapshot
  Map<String, dynamic> get latestCallStats => _webrtcService?.latestStats ?? {};

  /// Set video quality
  void setVideoQuality({int width = 1280, int height = 720, int fps = 30}) {
    _webrtcService?.setVideoQuality(width: width, height: height, fps: fps);
  }

  /// Set audio bitrate (kbps)
  void setAudioBitrate(int kbps) {
    _webrtcService?.setAudioBitrate(kbps);
  }

  /// Set video bitrate (kbps)
  void setVideoBitrate(int kbps) {
    _webrtcService?.setVideoBitrate(kbps);
  }

  /// Start collecting call statistics
  void startCallStatsCollection({
    Duration interval = const Duration(seconds: 2),
  }) {
    _webrtcService?.startStatsCollection(interval: interval);
  }

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
      _callType = video ? CallType.video : CallType.audio;

      _currentRoomId = 'call_${DateTime.now().millisecondsSinceEpoch}';

      // Initiate call via API (sends FCM + XMPP)
      final response = await _client.calls.initiateP2PCall(
        to: to,
        room: _currentRoomId,
      );

      _currentCallId = response['call_id'];
      _peerJid = _normalizePeerJid(to);
      print('📡 Caller JID: $_myJid, Peer JID: $_peerJid (from: $to)');

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

  /// Inject incoming call state from push notification data.
  /// Use this when FCM/push payload already contains roomId and callerJid
  /// so there is no need to wait for the XMPP callInvitation signal.
  void prepareIncomingCall({
    required String roomId,
    required String callerJid,
    String callerName = 'Unknown',
  }) {
    if (_callState != CallState.idle) return;
    _currentRoomId = roomId;
    _peerJid = callerJid;
    _setCallState(CallState.incoming);
    onIncomingCall?.call(callerName);
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
  Future<void> acceptCall({bool audio = true, bool video = true}) async {
    if (_callState != CallState.incoming || _currentRoomId == null) {
      throw ValidationException('No incoming call to accept');
    }

    try {
      _callType = video ? CallType.video : CallType.audio;

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
    print('🔔 CallManager signaling: ${message.type} (state=$_callState)');
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
    // Update _peerJid to the actual sender's XMPP JID so webrtcOffer reaches them
    final actualFromJid = message.data['fromJid'] as String?;
    if (actualFromJid != null && actualFromJid.isNotEmpty) {
      print(
          '📡 Updating peer JID from callResponse: $_peerJid → $actualFromJid');
      _peerJid = actualFromJid;
    }

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

  /// Normalize a phone number or partial JID to a full XMPP JID.
  /// The Nexacon server strips country code prefixes (e.g. +255 → bare number).
  /// We detect the prefix length by comparing our own bound JID with the raw phone.
  String _normalizePeerJid(String to) {
    if (to.contains('@')) return to; // Already a full JID

    final domain = (_myJid != null && _myJid!.contains('@'))
        ? _myJid!.split('@')[1]
        : 'nxservice.quantumvision-tech.com';

    // Strip leading +
    var digits = to.replaceAll(RegExp(r'^\+'), '');

    // If we know our own JID local part, use its length to trim the peer digits.
    // This removes the country code prefix that the Nexacon server strips.
    if (_myJid != null && _myJid!.contains('@')) {
      final myLocal = _myJid!.split('@')[0];
      if (digits.length > myLocal.length) {
        digits = digits.substring(digits.length - myLocal.length);
      }
    }

    return '$digits@$domain';
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

    // Auto-record call analytics
    _recordCallAnalytics(reason);

    // Reset state after delay
    Future.delayed(const Duration(seconds: 1), () {
      _setCallState(CallState.idle);
      _currentRoomId = null;
      _currentCallId = null;
      _callType = null;
    });
  }

  /// Record call analytics automatically
  void _recordCallAnalytics(String reason) {
    if (_currentRoomId == null || _callType == null) return;

    // Determine status based on reason
    CallAnalyticsStatus status;
    if (reason.contains('rejected')) {
      status = CallAnalyticsStatus.declined;
    } else if (reason.contains('Failed') || reason.contains('failed')) {
      status = CallAnalyticsStatus.failed;
    } else if (reason.contains('cancelled')) {
      status = CallAnalyticsStatus.cancelled;
    } else if (reason.contains('missed')) {
      status = CallAnalyticsStatus.missed;
    } else {
      status = CallAnalyticsStatus.ended;
    }

    // Get duration (0 for failed/declined/cancelled/missed)
    final duration =
        status == CallAnalyticsStatus.ended ? callDuration.inSeconds : 0;

    // Record asynchronously (don't block cleanup)
    _client.calls.recordCall(
      room: _currentRoomId!,
      callType: _callType!,
      status: status,
      durationSeconds: duration,
      metadata: {'reason': reason},
    ).catchError((_) => <String, dynamic>{});
  }

  /// Set call state and notify listeners
  void _setCallState(CallState state) {
    _callState = state;
    onCallStateChanged?.call(state);
  }

  /// Cleanup resources
  void dispose() {
    _webrtcService?.endCall();
    _setCallState(CallState.idle);
    // Note: Don't disconnect XMPP manager here - it's shared
  }
}
