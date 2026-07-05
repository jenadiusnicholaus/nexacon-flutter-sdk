import 'dart:async';
import 'core/client.dart';
import 'calls/call_manager.dart';
import 'core/xmpp_manager.dart';

/// Simplified high-level API for Nexacon SDK
/// Handles all complexity internally - just 3 steps to make a call
class NexaconSDK {
  final String _apiKey;
  final String _secretKey;
  final String _baseUrl;

  NexaconClient? _client;
  CallManager? _callManager;
  XmppManager? _xmppManager;

  /// Get the underlying NexaconClient for advanced use cases
  /// (e.g., messaging, presence, rooms)
  NexaconClient? get client => _client;

  /// Get the NX manager for direct messaging access
  XmppManager? get xmppManager => _xmppManager;

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
  /// This also establishes NX connection for messaging.
  ///
  /// [username] Your username/phone number
  /// [name] Your display name (optional)
  /// [nxtoken] Optional - NX token if already fetched (avoids API call)
  /// [nxid] Optional - NX JID if already fetched
  /// [wsUrl] Optional - WebSocket URL if already fetched
  ///
  /// Returns the NX credentials (token, jid, wsUrl) that were used
  Future<Map<String, dynamic>> initialize({
    required String username,
    String? name,
    String? nxtoken,
    String? nxid,
    String? wsUrl,
  }) async {
    try {
      _client = NexaconClient(
        apiKey: _apiKey,
        secretKey: _secretKey,
        baseUrl: _baseUrl,
      );

      // Use provided credentials or fetch from API
      if (nxtoken == null || nxid == null || wsUrl == null) {
        print('🔐 Fetching NX token from API...');
        final nxResponse = await _client!.auth.getNxToken(username: username);
        nxtoken = nxResponse['token'];
        nxid = nxResponse['jid'];
        wsUrl = nxResponse['nxws'];
        print('✅ NX token fetched successfully');
      } else {
        print('✅ Using provided NX credentials (skipping API call)');
      }

      // Ensure wsUrl is not null
      if (wsUrl == null) {
        throw Exception('WebSocket URL is null');
      }

      if (wsUrl.startsWith('https://')) {
        wsUrl = wsUrl.replaceFirst('https://', 'wss://');
      }

      // Ensure nxtoken and nxid are not null
      if (nxtoken == null || nxid == null) {
        throw Exception('NX token or JID is null');
      }

      _client!.setToken(nxtoken);

      // Establish NX connection for messaging
      _xmppManager = _client!.nxManager;
      final nxConnected = await _xmppManager!.connect(
        jid: nxid,
        password: nxtoken,
        wsUrl: wsUrl,
      );

      if (!nxConnected) {
        throw Exception('Failed to establish NX connection');
      }

      print('✅ NX connection established for messaging');

      // Create CallManager for calls
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

      // Return the credentials used
      return {
        'token': nxtoken,
        'jid': nxid,
        'nxws': wsUrl,
      };
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
    String? roomId,
  }) async {
    try {
      // Reuse pre-warmed connection if available to avoid duplicate XMPP sessions
      if (_callManager == null) {
        await initialize(username: username, name: name);
      }

      await _callManager!.initiateCall(
        to: to,
        audio: audio,
        video: video,
        roomId: roomId,
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
  /// NX `callInvitation` signal before calling [acceptCall], avoiding
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
      // Reuse pre-warmed connection if available to avoid duplicate XMPP sessions
      if (_callManager == null) {
        await initialize(username: username, name: name);
      }
      await completer.future;
    } catch (e) {
      onError?.call('Failed to accept incoming call: $e');
      rethrow;
    } finally {
      timer.cancel();
    }
  }

  /// Accept an incoming call using data from a push notification payload.
  ///
  /// Use this when FCM/push already delivered the call data (roomId, callerNxId)
  /// so you don't need to wait for the NX callInvitation signal.
  /// This is the correct path when the app is opened from a push notification.
  ///
  /// For the NX-first path (app already in foreground), use [acceptWhenReady].
  ///
  /// [username] Your username/phone number
  /// [roomId] Room ID from the FCM push payload
  /// [callerNxId] Caller's NX ID from the FCM push payload
  /// [callerName] Caller display name (optional)
  /// [name] Your display name (optional)
  /// [audio] Enable audio (default: true)
  /// [video] Enable video (default: false)
  Future<void> acceptFromNotification({
    required String username,
    required String roomId,
    required String callerNxId,
    String? callerName,
    String? name,
    bool audio = true,
    bool video = false,
  }) async {
    try {
      print('📲 Accepting call from push notification: room=$roomId');
      // Reuse pre-warmed connection if already connected — do NOT call initialize()
      // again as it creates a duplicate NX session and drops signaling messages.
      if (_callManager == null) {
        await initialize(username: username, name: name);
      } else {
        print('♻️ Reusing existing NX connection for acceptFromNotification');
      }

      // Inject call state directly — no need to wait for NX signal
      _callManager!.prepareIncomingCall(
        roomId: roomId,
        callerNxId: callerNxId,
        callerName: callerName ?? 'Unknown',
      );

      await _callManager!.acceptCall(audio: audio, video: video);
      print('✅ Call accepted from notification');
    } catch (e) {
      onError?.call('Failed to accept call from notification: $e');
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

  /// Notify caller that the remote party accepted (FCM/backend fallback).
  void notifyRemoteAccepted() {
    _callManager?.notifyRemoteAccepted();
  }

  /// End the current call
  Future<void> endCall() async {
    if (_callManager == null) return;

    try {
      await _callManager!.endCall();
    } catch (e) {
      onError?.call('Failed to end call: $e');
    } finally {
      // Null out CallManager so next call always gets a fresh instance.
      // This prevents stale state from a previous call causing the second call
      // to fail or auto-end immediately after being accepted.
      _callManager = null;
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
