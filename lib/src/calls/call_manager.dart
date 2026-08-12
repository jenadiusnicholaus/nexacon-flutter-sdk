import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../core/client.dart';
import '../core/nx_connection_manager.dart';
import 'calls.dart';
import 'webrtc.dart';
import 'signaling.dart';
import '../core/nexacon_config.dart';
import '../core/exceptions.dart';
import '../core/nx_id_utils.dart';

/// Call state enum
enum CallState { idle, calling, incoming, connected, ended }

/// Call Manager - Orchestrates full P2P call flow
class CallManager {
  final NexaconClient _client;
  final NxConnectionManager _nxManager;
  WebRTCService? _webrtcService;
  SignalingService? _signalingService;

  String? _currentRoomId;
  String? _currentCallId;
  String? _myNxId;
  String? _myName;
  String? _peerNxId;
  CallType? _callType;
  CallState _callState = CallState.idle;
  Completer<void>? _callResponseCompleter;
  StreamSubscription<dynamic>? _signalingSubscription;

  // Callbacks
  final Function(CallState)? onCallStateChanged;
  final Function(String)? onIncomingCall;
  final Function(String)? onCallEnded;
  final Function(String)? onError;
  final Function(MediaStream)? onLocalStream;
  final Function(MediaStream)? onRemoteStream;
  final Function()? onOtherUserJoined;
  final Function()? onOtherUserLeft;

  CallManager(
    this._client,
    this._nxManager, {
    this.onCallStateChanged,
    this.onIncomingCall,
    this.onCallEnded,
    this.onError,
    this.onLocalStream,
    this.onRemoteStream,
    this.onOtherUserJoined,
    this.onOtherUserLeft,
  });

  /// Initialize the call manager with NX credentials
  /// Uses the global NX manager for signaling
  Future<bool> initialize({
    required String nxid,
    required String nxtoken,
    required String wsUrl,
    String? name,
  }) async {
    _myNxId = nxid;
    _myName = name ?? nxid.split('@')[0];

    // Connect via global NX manager
    final connected = await _nxManager.connect(
      nxid: nxid,
      password: nxtoken,
      wsUrl: wsUrl,
    );

    if (!connected) {
      onError?.call('Failed to connect to NX server');
      return false;
    }

    // Listen for signaling messages from global NX
    _signalingSubscription = _nxManager.signalingStream.listen((data) {
      try {
        print('📥 CallManager received from signaling stream: $data');
        final signalingMessage = SignalingMessage.fromJson(data);
        _handleSignalingMessage(signalingMessage);
      } catch (e) {
        print('Error parsing signaling message: $e');
      }
    });

    // Initialize signaling service with NX send capability
    _signalingService = SignalingService(
      onMessageReceived: _handleSignalingMessage,
      onSendMessage: (message) {
        if (_peerNxId == null || _peerNxId!.isEmpty) {
          print('❌ Cannot send signaling — peer NxID is not set');
          onError?.call('Cannot send signaling: peer not identified');
          return;
        }
        _nxManager.sendMessage(_peerNxId!, message);
      },
    );

    // Initialize WebRTC service
    _webrtcService = WebRTCService(
      onLocalStream: onLocalStream,
      onRemoteStream: (stream) {
        // Remote peer joined WebRTC
        onOtherUserJoined?.call();
        onRemoteStream?.call(stream);
      },
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
    Duration interval = NexaconConfig.statsInterval,
  }) {
    _webrtcService?.startStatsCollection(interval: interval);
  }

  /// Initiate an outgoing P2P call
  Future<void> initiateCall({
    required String to,
    bool audio = true,
    bool video = true,
    String? roomId,
  }) async {
    if (_callState != CallState.idle) {
      throw ValidationException('Call already in progress');
    }

    try {
      _setCallState(CallState.calling);
      _callType = video ? CallType.video : CallType.audio;

      _currentRoomId =
          roomId ?? 'call_${DateTime.now().millisecondsSinceEpoch}';

      // Initiate call via API (sends FCM + NX signaling)
      final response = await _client.calls.initiateP2PCall(
        to: to,
        room: _currentRoomId,
      );

      _currentCallId = response['call_id'];
      _peerNxId = NxIdUtils.resolve(to, myNxId: _myNxId);
      print(
        '📡 Caller NxID: $_myNxId, Peer NxID: $_peerNxId (from: $to, room: $_currentRoomId)',
      );

      // Send NX call invitation
      _signalingService?.sendMessage(
        _signalingService!.createCallInvitation(
          roomId: _currentRoomId!,
          callType: video ? 'video' : 'audio',
          fromNxId: _myNxId!,
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
  /// Use this when FCM/push payload already contains roomId and callerNxId
  /// so there is no need to wait for the NX callInvitation signal.
  void prepareIncomingCall({
    required String roomId,
    required String callerNxId,
    String callerName = 'Unknown',
  }) {
    _currentRoomId = roomId;
    _peerNxId = NxIdUtils.resolve(callerNxId, myNxId: _myNxId);
    print(
      '📲 prepareIncomingCall: room=$roomId peerNxId=$_peerNxId (from: $callerNxId)',
    );

    if (_callState == CallState.idle) {
      _setCallState(CallState.incoming);
      onIncomingCall?.call(callerName);
    } else if (_callState == CallState.incoming ||
        _callState == CallState.calling) {
      // Already handling this call via NX pre-warm — update peer/room from FCM
      print('📲 Updating incoming call state from notification');
    } else if (_callState == CallState.ended) {
      // Call was ended (likely by caller timeout) - reset to accept new incoming call
      print('📲 Call state is ended, resetting to accept incoming call');
      _setCallState(CallState.incoming);
      onIncomingCall?.call(callerName);
    } else {
      print('⚠️ prepareIncomingCall ignored — call state is $_callState');
    }
  }

  /// Handle incoming call invitation
  void handleIncomingCall(SignalingMessage message) {
    if (_callState != CallState.idle) {
      // If we're already accepting this call (via prepareIncomingCall from push
      // notification), just ignore the late NX invitation — don't send a reject.
      if (_callState == CallState.incoming || _callState == CallState.calling) {
        print(
          '📨 Ignoring late call_invitation — already accepting via notification',
        );
        return;
      }
      // Reject if genuinely in a different call
      final fromNxId = message.data['fromNxId'] ?? message.data['fromJid'];
      if (fromNxId != null) {
        _peerNxId = NxIdUtils.resolve(fromNxId as String, myNxId: _myNxId);
      }
      _signalingService?.sendMessage(
        _signalingService!.createCallResponse(
          roomId: message.data['roomId'],
          accepted: false,
        ),
      );
      return;
    }

    _currentRoomId = message.data['roomId'];
    final fromNxId = message.data['fromNxId'] ?? message.data['fromJid'];
    _peerNxId = fromNxId != null
        ? NxIdUtils.resolve(fromNxId as String, myNxId: _myNxId)
        : _peerNxId;
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

  /// Handle signaling message from NX server
  void _handleSignalingMessage(SignalingMessage message) {
    print('🔔 CallManager signaling: ${message.type} (state=$_callState)');
    print('🔔 Signaling data: ${message.data}');

    // For every message type except callInvitation, guard against stale signals
    // from previous calls that are queued/replayed by the NX server on
    // reconnect. If the roomId in the message doesn't match the current active
    // room, silently drop it.
    if (message.type != SignalingMessageType.callInvitation) {
      final incomingRoomId = message.data['roomId'] as String?;
      if (incomingRoomId != null &&
          _currentRoomId != null &&
          incomingRoomId != _currentRoomId) {
        print(
          '⚠️ Dropping stale ${message.type} for room=$incomingRoomId (current=$_currentRoomId)',
        );
        return;
      }
      if (incomingRoomId != null && _currentRoomId == null) {
        print(
          '⚠️ Dropping ${message.type} for room=$incomingRoomId — no active call',
        );
        return;
      }
    }

    switch (message.type) {
      case SignalingMessageType.callInvitation:
        handleIncomingCall(message);
        break;

      case SignalingMessageType.callResponse:
      case SignalingMessageType.callAccepted:
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

  /// Handle call response — completes the waiting completer (caller side)
  void _handleCallResponse(SignalingMessage message) {
    final senderNxId = (message.data['fromJid'] as String?)?.isNotEmpty == true
        ? message.data['fromJid'] as String
        : message.data['fromNxId'] as String?;
    if (senderNxId != null && senderNxId.isNotEmpty) {
      final formatted = NxIdUtils.resolve(senderNxId, myNxId: _myNxId);
      print('📡 Updating peer NxID from response: $_peerNxId → $formatted');
      _peerNxId = formatted;
    }

    final accepted = message.data['accepted'] != false;

    if (_callResponseCompleter != null &&
        !_callResponseCompleter!.isCompleted) {
      if (!accepted) {
        _callResponseCompleter!.completeError('Call rejected');
      } else {
        print('✅ Call accepted signal received — proceeding with WebRTC');
        _callResponseCompleter!.complete();
      }
    } else if (!accepted) {
      _endCall('Call rejected');
    } else if (accepted && _callState == CallState.calling) {
      // Late acceptance after completer cleared — still proceed if we're the caller
      print('✅ Late call acceptance received');
    }
  }

  /// Notify caller that remote party accepted (FCM/backend fallback path).
  void notifyRemoteAccepted() {
    print('📲 notifyRemoteAccepted — unblocking caller wait');
    if (_callResponseCompleter != null &&
        !_callResponseCompleter!.isCompleted) {
      _callResponseCompleter!.complete();
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
    final timeout = Timer(NexaconConfig.callResponseTimeout, () {
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
    // Cancel the signaling subscription immediately so this CallManager
    // cannot process any further messages (including stale signals from
    // previous calls replayed on a new NX session).
    _signalingSubscription?.cancel();
    _signalingSubscription = null;

    _webrtcService?.endCall();
    _setCallState(CallState.ended);
    onOtherUserLeft?.call();
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
    // Note: Don't disconnect NX manager here - it's shared
  }
}
