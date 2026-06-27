import 'dart:async';
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

  /// Initialize SDK connection without starting a call.
  /// Use this for incoming calls: call [initialize] then [acceptCall].
  /// For outgoing calls, use [startCall] directly.
  ///
  /// [username] Your username/phone number
  /// [name] Your display name (optional)
  Future<void> initialize({
    required String username,
    String? name,
  }) async {
    try {
      _client = NexaconClient(
        apiKey: _apiKey,
        secretKey: _secretKey,
        baseUrl: _baseUrl,
      );

      final nxResponse = await _client!.auth.getNxToken(username: username);
      final nxtoken = nxResponse['token'];
      final nxid = nxResponse['jid'];
      String wsUrl = nxResponse['nxws'];

      if (wsUrl.startsWith('https://')) {
        wsUrl = wsUrl.replaceFirst('https://', 'wss://');
      }

      _client!.setToken(nxtoken);

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
    } catch (e) {
      onError?.call('Failed to initialize: $e');
      rethrow;
    }
  }

  /// Start an outgoing call - handles all complexity internally.
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
      await initialize(username: username, name: name);

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

  /// Accept an incoming call.
  /// Must only be called after [onIncomingCall] has fired (state is `incoming`).
  /// For a simpler flow use [acceptWhenReady] which waits automatically.
  ///
  /// [audio] Enable audio (default: true)
  /// [video] Enable video (default: false)
  Future<void> acceptCall({
    bool audio = true,
    bool video = false,
  }) async {
    if (_callManager == null) {
      throw Exception('CallManager not initialized. Call initialize() first.');
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

  /// Initialize and automatically accept the incoming call once the
  /// call invitation signal arrives from the caller.
  ///
  /// This is the correct way to handle incoming calls — it waits for the
  /// XMPP `callInvitation` signal before calling [acceptCall], avoiding
  /// the "No incoming call to accept" error.
  ///
  /// [username] Your username/phone number
  /// [name] Your display name (optional)
  /// [audio] Enable audio (default: true)
  /// [video] Enable video (default: false)
  /// [timeout] How long to wait for the call invitation (default: 30s)
  Future<void> acceptWhenReady({
    required String username,
    String? name,
    bool audio = true,
    bool video = false,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final completer = Completer<void>();

    // Save any existing onIncomingCall so we don't lose it
    final existingOnIncomingCall = onIncomingCall;

    // Override to intercept the incoming call signal
    onIncomingCall = (callerName) {
      existingOnIncomingCall?.call(callerName);
      // Restore original callback
      onIncomingCall = existingOnIncomingCall;
      // Now accept
      acceptCall(audio: audio, video: video).then((_) {
        if (!completer.isCompleted) completer.complete();
      }).catchError((e) {
        if (!completer.isCompleted) completer.completeError(e);
      });
    };

    final timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        onIncomingCall = existingOnIncomingCall;
        completer.completeError(
          Exception('No incoming call received within ${timeout.inSeconds}s'),
        );
      }
    });

    try {
      await initialize(username: username, name: name);
      await completer.future;
    } catch (e) {
      onError?.call('Failed to accept incoming call: $e');
      rethrow;
    } finally {
      timer.cancel();
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
