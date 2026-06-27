import '../lib/nexacon_sdk.dart';

void main() async {
  // Initialize client
  final client = NexaconClient(
    apiKey: 'your_api_key',
    secretKey: 'your_secret_key',
    baseUrl: 'https://nxservice.quantumvision-tech.com/api/v1.0',
  );

  try {
    // Generate NX token for signaling
    print('Generating NX token...');
    final nxResponse = await client.auth.getNxToken(
      username: '+255788811191',
    );
    print('NX token generated');
    final nxtoken = nxResponse['token'];
    final nxid = nxResponse['jid'];
    final wsUrl = nxResponse['nxws'];

    // Create CallManager for P2P calling
    print('\nInitializing CallManager...');
    final callManager = await client.createCallManager(
      nxtoken: nxtoken,
      nxid: nxid,
      wsUrl: wsUrl,
      name: 'Your Name',
      onCallStateChanged: (state) {
        print('Call state changed: $state');
      },
      onIncomingCall: (callerName) {
        print('Incoming call from: $callerName');
      },
      onCallEnded: (reason) {
        print('Call ended: $reason');
      },
      onError: (error) {
        print('Call error: $error');
      },
    );
    print('CallManager initialized');

    // Initiate a P2P call
    print('\nInitiating P2P call...');
    await callManager.initiateCall(
      to: '+255788811192',
      audio: true,
      video: false,
    );
    print('Call initiated');

    // End call
    print('\nEnding call...');
    await callManager.endCall();
    print('Call ended');

    // Cleanup
    callManager.dispose();
  } on NexaconException catch (e) {
    print('Error: ${e.message}');
  } finally {
    client.close();
  }
}
