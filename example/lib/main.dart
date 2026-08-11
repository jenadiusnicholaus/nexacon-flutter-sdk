import 'package:flutter/material.dart';
import 'package:nexacon_calls/nexacon_calls.dart';

/// Nexacon SDK Example Application
///
/// Best Practices:
/// 1. Always format phone numbers with country code (e.g., +255 for Tanzania)
/// 2. Use NexaconSDK (high-level) for the simplest integration — it handles
///    token management, NX connection, and CallManager lifecycle internally.
/// 3. After each call, NexaconSDK.endCall() automatically nulls the internal
///    CallManager — the next call always gets a fresh instance (safe for
///    consecutive back-to-back calls).
/// 4. Use _isOtherUserConnected (set only in onOtherUserJoined) to guard
///    onOtherUserLeft — never use _isCallConnected which is set too early.
/// 5. Always call _resetCallState() before starting or accepting a call to
///    clear any leftover flags from a previous call.
/// 6. Use flags (_isEndingCall, _isEndCallScheduled) to prevent duplicate
///    endCall invocations from concurrent callbacks.
/// 7. Always call sdk.dispose() when done to release WebRTC resources.
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexacon SDK Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const CallExamplePage(),
    );
  }
}

class CallExamplePage extends StatefulWidget {
  const CallExamplePage({super.key});

  @override
  State<CallExamplePage> createState() => _CallExamplePageState();
}

class _CallExamplePageState extends State<CallExamplePage> {
  // Text controllers for user input
  final _apiKeyController = TextEditingController(text: 'your_api_key');
  final _secretKeyController = TextEditingController(text: 'your_secret_key');
  final _usernameController = TextEditingController(text: '+255788811191');
  final _recipientController = TextEditingController(text: '+255788811192');

  // High-level SDK instance — create once, reuse across consecutive calls.
  // NexaconSDK.endCall() automatically nulls the internal CallManager so
  // the next call always gets a completely fresh instance.
  NexaconSDK? _sdk;

  // UI state
  String _callState = 'idle';
  String _status = 'Not connected';
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isVideoEnabled = true;
  Duration _callDuration = Duration.zero;

  // Track whether the WebRTC peer actually joined.
  // IMPORTANT: Use this (not _isCallConnected) to guard onOtherUserLeft.
  // _isCallConnected is set at call initiation — too early to be reliable.
  // _isOtherUserConnected is set only when onOtherUserJoined fires (real
  // WebRTC connection), making it the correct gate for ending a call.
  bool _isOtherUserConnected = false;

  // Prevent duplicate endCall invocations from concurrent callbacks.
  bool _isEndingCall = false;
  bool _isEndCallScheduled = false;

  @override
  void dispose() {
    _sdk?.dispose();
    _apiKeyController.dispose();
    _secretKeyController.dispose();
    _usernameController.dispose();
    _recipientController.dispose();
    super.dispose();
  }

  /// Create the NexaconSDK instance and wire up all callbacks.
  /// Call this once on app start — the same instance is reused for every
  /// subsequent call because endCall() resets internal state automatically.
  void _createSdk() {
    _sdk = NexaconSDK(
      apiKey: _apiKeyController.text,
      secretKey: _secretKeyController.text,
    );

    _sdk!.onCallStateChanged = (state) {
      setState(() {
        _callState = state.toString();
        if (state == CallState.connected) _updateCallDuration();
      });
    };

    _sdk!.onIncomingCall = (callerName) {
      setState(() => _status = 'Incoming call from: $callerName');
      _showIncomingCallDialog(callerName);
    };

    _sdk!.onCallEnded = (reason) {
      setState(() {
        _status = 'Call ended: $reason';
        _callDuration = Duration.zero;
        _callState = 'idle';
        _isEndingCall = false;
        _isOtherUserConnected = false;
      });
    };

    _sdk!.onOtherUserJoined = () {
      setState(() {
        _isOtherUserConnected = true;
        _status = 'Connected';
      });
    };

    _sdk!.onOtherUserLeft = () {
      // IMPORTANT: Only end the call if the peer actually connected via WebRTC.
      // Without this guard, stale NX signals from a previous call session
      // can trigger onOtherUserLeft on a brand-new call before the peer joins,
      // causing it to auto-end immediately after acceptance.
      if (!_isOtherUserConnected) {
        print('⚠️ onOtherUserLeft: peer never joined — ignoring');
        return;
      }

      if (_isEndCallScheduled) return;
      _isEndCallScheduled = true;
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!_isEndingCall) _endCall();
        _isEndCallScheduled = false;
      });
    };

    _sdk!.onError = (error) {
      setState(() => _status = 'Error: $error');
    };
  }

  /// Reset per-call UI state flags before every new call.
  /// IMPORTANT: Always call this before startCall / acceptFromNotification
  /// so flags from the previous call do not carry over.
  void _resetCallState() {
    setState(() {
      _isEndingCall = false;
      _isEndCallScheduled = false;
      _isOtherUserConnected = false;
      _callDuration = Duration.zero;
      _callState = 'idle';
    });
  }

  /// Initiate an outgoing call.
  /// NexaconSDK handles token auth, NX connection, and WebRTC internally.
  Future<void> _initiateCall() async {
    if (_sdk == null) _createSdk();
    _resetCallState();

    setState(() => _status = 'Calling...');
    try {
      await _sdk!.startCall(
        to: _recipientController.text, // Format: +<country_code><number>
        username: _usernameController.text,
        name: 'Example User',
        audio: true,
        video: _isVideoEnabled,
      );
      setState(() => _status = 'Ringing — waiting for answer');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  /// Accept an incoming call that arrived via FCM push notification.
  // ignore: unused_element
  Future<void> _acceptCallFromNotification({
    required String roomId,
    required String callerNxId,
  }) async {
    if (_sdk == null) _createSdk();
    _resetCallState();

    setState(() => _status = 'Accepting call...');
    try {
      await _sdk!.acceptFromNotification(
        username: _usernameController.text,
        roomId: roomId,
        callerNxId: callerNxId, // caller's phone / NX ID from FCM payload
        name: 'Example User',
        audio: true,
        video: _isVideoEnabled,
      );
      setState(() => _status = 'Call accepted');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  /// Accept an incoming call received while the app is in the foreground.
  Future<void> _acceptCall() async {
    if (_sdk == null) return;
    _resetCallState();

    try {
      await _sdk!.acceptCall(audio: true, video: _isVideoEnabled);
      setState(() => _status = 'Call accepted');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  /// Reject an incoming call.
  void _rejectCall() {
    _sdk?.rejectCall();
    setState(() => _status = 'Call rejected');
  }

  /// End the current call.
  /// After this, NexaconSDK resets internal state — the same _sdk instance
  /// is ready for the next consecutive call without any manual cleanup.
  Future<void> _endCall() async {
    if (_sdk == null) return;
    if (_isEndingCall) return;
    _isEndingCall = true;

    try {
      await _sdk!.endCall();
      setState(() {
        _status = 'Call ended';
        _callDuration = Duration.zero;
      });
    } catch (e) {
      setState(() => _status = 'Error: $e');
      _isEndingCall = false;
    }
  }

  void _toggleMute() {
    if (_sdk == null) return;
    setState(() {
      _isMuted = !_isMuted;
      _sdk!.toggleMute(_isMuted);
    });
  }

  void _toggleSpeaker() {
    if (_sdk == null) return;
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
      _sdk!.toggleSpeaker(_isSpeakerOn);
    });
  }

  void _toggleVideo() {
    if (_sdk == null) return;
    setState(() {
      _isVideoEnabled = !_isVideoEnabled;
      _sdk!.toggleVideo(_isVideoEnabled);
    });
  }

  Future<void> _switchCamera() async {
    try {
      await _sdk?.switchCamera();
    } catch (e) {
      setState(() => _status = 'Error switching camera: $e');
    }
  }

  /// Refresh call duration label every second while connected.
  void _updateCallDuration() {
    if (_callState == 'CallState.connected') {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _sdk != null) {
          setState(() => _callDuration = _sdk!.callDuration);
          _updateCallDuration();
        }
      });
    }
  }

  /// Show incoming call dialog
  void _showIncomingCallDialog(String callerName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Incoming Call'),
        content: Text('Call from: $callerName'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _rejectCall();
            },
            child: const Text('Reject'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _acceptCall();
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nexacon SDK Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configuration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _apiKeyController,
                      decoration: const InputDecoration(
                        labelText: 'API Key',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _secretKeyController,
                      decoration: const InputDecoration(
                        labelText: 'Secret Key',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Your Username',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _recipientController,
                      decoration: const InputDecoration(
                        labelText: 'Recipient',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'SDK is initialized automatically on first call.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Call Controls',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _initiateCall,
                            icon: const Icon(Icons.call),
                            label: const Text('Call'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _endCall,
                            icon: const Icon(Icons.call_end),
                            label: const Text('End'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // In-call controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton.filled(
                          onPressed: _toggleMute,
                          icon: Icon(_isMuted ? Icons.mic_off : Icons.mic),
                          tooltip: _isMuted ? 'Unmute' : 'Mute',
                          style: IconButton.styleFrom(
                            backgroundColor:
                                _isMuted ? Colors.red : Colors.grey,
                          ),
                        ),
                        IconButton.filled(
                          onPressed: _toggleSpeaker,
                          icon: Icon(_isSpeakerOn
                              ? Icons.volume_up
                              : Icons.volume_down),
                          tooltip: _isSpeakerOn ? 'Speaker On' : 'Speaker Off',
                        ),
                        IconButton.filled(
                          onPressed: _toggleVideo,
                          icon: Icon(_isVideoEnabled
                              ? Icons.videocam
                              : Icons.videocam_off),
                          tooltip: _isVideoEnabled
                              ? 'Disable Video'
                              : 'Enable Video',
                          style: IconButton.styleFrom(
                            backgroundColor:
                                _isVideoEnabled ? Colors.grey : Colors.red,
                          ),
                        ),
                        IconButton.filled(
                          onPressed: _switchCamera,
                          icon: const Icon(Icons.flip_camera_ios),
                          tooltip: 'Switch Camera',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('State: $_callState'),
                    const SizedBox(height: 4),
                    Text('Status: $_status'),
                    const SizedBox(height: 4),
                    if (_callDuration > Duration.zero)
                      Text(
                        'Duration: ${_callDuration.inMinutes}:${(_callDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
