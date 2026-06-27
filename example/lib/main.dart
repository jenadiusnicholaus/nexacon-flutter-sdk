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
  final _apiKeyController = TextEditingController(text: 'your_api_key');
  final _secretKeyController = TextEditingController(text: 'your_secret_key');
  final _usernameController = TextEditingController(text: '+255788811191');
  final _recipientController = TextEditingController(text: '+255788811192');

  NexaconClient? _client;
  CallManager? _callManager;
  String _callState = 'idle';
  String _status = 'Not connected';

  @override
  void dispose() {
    _callManager?.dispose();
    _client?.close();
    _apiKeyController.dispose();
    _secretKeyController.dispose();
    _usernameController.dispose();
    _recipientController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() => _status = 'Initializing...');

    try {
      _client = NexaconClient(
        apiKey: _apiKeyController.text,
        secretKey: _secretKeyController.text,
      );

      final nxResponse = await _client!.auth.generateXMPPToken(
        username: _usernameController.text,
      );

      final nxtoken = nxResponse['token'];
      final nxid = nxResponse['jid'];
      final wsUrl = nxResponse['nxws'];

      // Set the token on the client for API authentication
      _client!.setToken(nxtoken);

      _callManager = await _client!.createCallManager(
        nxtoken: nxtoken,
        nxid: nxid,
        wsUrl: wsUrl,
        name: 'Example User',
        onCallStateChanged: (state) {
          setState(() => _callState = state.toString());
        },
        onIncomingCall: (callerName) {
          setState(() => _status = 'Incoming call from: $callerName');
        },
        onCallEnded: (reason) {
          setState(() => _status = 'Call ended: $reason');
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

  Future<void> _initiateCall() async {
    if (_callManager == null) {
      setState(() => _status = 'Please initialize first');
      return;
    }

    try {
      await _callManager!.initiateCall(
        to: _recipientController.text,
        audio: true,
        video: false,
      );
      setState(() => _status = 'Call initiated');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _endCall() async {
    if (_callManager == null) return;

    try {
      await _callManager!.endCall();
      setState(() => _status = 'Call ended');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
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
