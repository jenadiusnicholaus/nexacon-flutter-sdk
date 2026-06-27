import 'core/client.dart';
import 'calls/call_manager.dart';

/// Simplified high-level API for Nexacon SDK
/// Handles all complexity internally - just 3 steps to make a call
class NexaconSDK {
  final String _apiKey;
  final String _secretKey;
  final String _baseUrl;

  NexaconClient? _client;
  CallManager? _callManager;

  // Callbacks
  Function(CallState)? onCallStateChanged;
  Function(String)? onIncomingCall;
  Function(String)? onCallEnded;
  Function(String)? onError;
  Function()? onLocalStream;
  Function()? onRemoteStream;

  /// Create NexaconSDK instance
  ///
  /// [apiKey] Your Nexacon API key
  /// [secretKey] Your Nexacon secret key
  /// [baseUrl] Optional - defaults to https://nxservice.quantumvision-tech.com/api/v1.0
  NexaconSDK({
    required String apiKey,
    required String secretKey,
    String baseUrl = 'https://nxservice.quantumvision-tech.com/api/v1.0',
  })  : _apiKey = apiKey,
        _secretKey = secretKey,
        _baseUrl = baseUrl;

  /// Start an outgoing call - handles all complexity internally
  ///
  /// [to] The recipient's username/phone number
  /// [username] Your username/phone number
  /// [name] Your display name (optional)
  /// [audio] Enable audio (default: true)
  /// [video] Enable video (default: false)
  Future<void> startCall({
    required String to,
    required String username,
    String? name,
    bool audio = true,
    bool video = false,
  }) async {
    try {
      // Step 1: Initialize client
      _client = NexaconClient(
        apiKey: _apiKey,
        secretKey: _secretKey,
        baseUrl: _baseUrl,
      );

      // Step 2: Get NX token and set it automatically
      final nxResponse = await _client!.auth.getNxToken(username: username);
      final nxtoken = nxResponse['token'];
      final nxid = nxResponse['jid'];
      String wsUrl = nxResponse['nxws'];

      // Convert https:// to wss:// for WebSocket
      if (wsUrl.startsWith('https://')) {
        wsUrl = wsUrl.replaceFirst('https://', 'wss://');
      }

      // Step 3: Set token on client (critical for API authentication)
      _client!.setToken(nxtoken);

      // Step 4: Create CallManager
      _callManager = await _client!.createCallManager(
        nxtoken: nxtoken,
        nxid: nxid,
        wsUrl: wsUrl,
        name: name ?? username,
        onCallStateChanged: (state) {
          onCallStateChanged?.call(state);
        },
        onIncomingCall: (callerName) {
          onIncomingCall?.call(callerName);
        },
        onCallEnded: (reason) {
          onCallEnded?.call(reason);
        },
        onError: (error) {
          onError?.call(error);
        },
        onLocalStream: (stream) {
          onLocalStream?.call();
        },
        onRemoteStream: (stream) {
          onRemoteStream?.call();
        },
      );

      // Step 5: Initiate call
      await _callManager!.initiateCall(
        to: to,
        audio: audio,
        video: video,
      );
    } catch (e) {
      onError?.call('Failed to start call: $e');
      rethrow;
    }
  }

  /// Accept an incoming call
  ///
  /// [audio] Enable audio (default: true)
  /// [video] Enable video (default: false)
  Future<void> acceptCall({
    bool audio = true,
    bool video = false,
  }) async {
    if (_callManager == null) {
      throw Exception('CallManager not initialized. Call startCall() first.');
    }

    try {
      await _callManager!.acceptCall(
        audio: audio,
        video: video,
      );
    } catch (e) {
      onError?.call('Failed to accept call: $e');
      rethrow;
    }
  }

  /// Reject an incoming call
  void rejectCall() {
    if (_callManager == null) {
      throw Exception('CallManager not initialized. Call startCall() first.');
    }
    _callManager!.rejectCall();
  }

  /// End the current call
  Future<void> endCall() async {
    if (_callManager == null) return;

    try {
      await _callManager!.endCall();
    } catch (e) {
      onError?.call('Failed to end call: $e');
    }
  }

  /// Toggle microphone mute
  void toggleMute(bool muted) {
    if (_callManager == null) return;
    _callManager!.webrtcService?.toggleAudio(!muted);
  }

  /// Toggle speaker
  void toggleSpeaker(bool enabled) {
    if (_callManager == null) return;
    _callManager!.webrtcService?.toggleSpeaker(enabled);
  }

  /// Toggle video
  void toggleVideo(bool enabled) {
    if (_callManager == null) return;
    _callManager!.webrtcService?.toggleVideo(enabled);
  }

  /// Switch camera (front/back)
  Future<void> switchCamera() async {
    if (_callManager == null) return;
    await _callManager!.webrtcService?.switchCamera();
  }

  /// Get current call duration
  Duration get callDuration {
    return _callManager?.callDuration ?? Duration.zero;
  }

  /// Cleanup resources
  Future<void> dispose() async {
    try {
      _callManager?.dispose();
      _callManager = null;
      _client?.close();
      _client = null;
    } catch (e) {
      onError?.call('Error disposing: $e');
    }
  }
}
