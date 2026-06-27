import 'package:flutter/material.dart';
import 'package:nexacon_sdk/nexacon_sdk.dart';

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

  // SDK instances
  NexaconClient? _client;
  CallManager? _callManager;

  // UI state
  String _callState = 'idle';
  String _status = 'Not connected';
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isVideoEnabled = true;
  Duration _callDuration = Duration.zero;

  @override
  void dispose() {
    // Cleanup resources
    _callManager?.dispose();
    _client?.close();
    _apiKeyController.dispose();
    _secretKeyController.dispose();
    _usernameController.dispose();
    _recipientController.dispose();
    super.dispose();
  }

  /// Initialize the SDK and connect to the server
  Future<void> _initialize() async {
    setState(() => _status = 'Initializing...');

    try {
      // Step 1: Create the NexaconClient
      _client = NexaconClient(
        apiKey: _apiKeyController.text,
        secretKey: _secretKeyController.text,
      );

      // Step 2: Generate NX token for authentication
      final nxResponse = await _client!.auth.getNxToken(
        username: _usernameController.text,
      );

      final nxtoken = nxResponse['token'];
      final nxid = nxResponse['jid'];
      final wsUrl = nxResponse['nxws'];

      // Step 3: IMPORTANT - Set the token on the client for API authentication
      // This is required to avoid 403 errors when making API calls
      _client!.setToken(nxtoken);

      // Step 4: Create CallManager with callbacks
      _callManager = await _client!.createCallManager(
        nxtoken: nxtoken,
        nxid: nxid,
        wsUrl: wsUrl,
        name: 'Example User',
        onCallStateChanged: (state) {
          setState(() {
            _callState = state.toString();
            // Update call duration when connected
            if (state == CallState.connected) {
              _updateCallDuration();
            }
          });
        },
        onIncomingCall: (callerName) {
          setState(() => _status = 'Incoming call from: $callerName');
          _showIncomingCallDialog(callerName);
        },
        onCallEnded: (reason) {
          setState(() {
            _status = 'Call ended: $reason';
            _callDuration = Duration.zero;
          });
        },
        onError: (error) {
          setState(() => _status = 'Error: $error');
        },
      );

      setState(() => _status = 'Connected and ready');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  /// Initiate an outgoing call to the recipient
  Future<void> _initiateCall() async {
    if (_callManager == null) {
      setState(() => _status = 'Please initialize first');
      return;
    }

    try {
      await _callManager!.initiateCall(
        to: _recipientController.text,
        audio: true,
        video: _isVideoEnabled,
      );
      setState(() => _status = 'Call initiated');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  /// Accept an incoming call
  Future<void> _acceptCall() async {
    if (_callManager == null) return;

    try {
      await _callManager!.acceptCall(
        audio: true,
        video: _isVideoEnabled,
      );
      setState(() => _status = 'Call accepted');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  /// Reject an incoming call
  void _rejectCall() {
    if (_callManager == null) return;
    _callManager!.rejectCall();
    setState(() => _status = 'Call rejected');
  }

  /// End the current call
  Future<void> _endCall() async {
    if (_callManager == null) return;

    try {
      await _callManager!.endCall();
      setState(() {
        _status = 'Call ended';
        _callDuration = Duration.zero;
      });
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  /// Toggle microphone mute state
  void _toggleMute() {
    if (_callManager == null) return;
    setState(() {
      _isMuted = !_isMuted;
      _callManager!.webrtcService?.toggleAudio(!_isMuted);
    });
  }

  /// Toggle speaker state
  void _toggleSpeaker() {
    if (_callManager == null) return;
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
      _callManager!.webrtcService?.toggleSpeaker(_isSpeakerOn);
    });
  }

  /// Toggle video state
  void _toggleVideo() {
    if (_callManager == null) return;
    setState(() {
      _isVideoEnabled = !_isVideoEnabled;
      _callManager!.webrtcService?.toggleVideo(_isVideoEnabled);
    });
  }

  /// Switch between front and back camera
  Future<void> _switchCamera() async {
    if (_callManager == null) return;
    try {
      await _callManager!.webrtcService?.switchCamera();
    } catch (e) {
      setState(() => _status = 'Error switching camera: $e');
    }
  }

  /// Update call duration every second when connected
  void _updateCallDuration() {
    if (_callState == 'CallState.connected') {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _callManager != null) {
          setState(() {
            _callDuration = _callManager!.callDuration;
          });
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
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _initialize,
                      child: const Text('Initialize'),
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
