import '../lib/nexacon_sdk.dart';

/// Basic usage example for Nexacon Flutter SDK
/// This demonstrates the minimal setup required to make a P2P call
void main() async {
  // Step 1: Initialize the client with your API credentials
  final client = NexaconClient(
    apiKey: 'your_api_key',
    secretKey: 'your_secret_key',
    // baseUrl is optional - defaults to https://nxservice.quantumvision-tech.com/api/v1.0
  );

  try {
    // Step 2: Generate NX token for XMPP signaling and API authentication
    print('🔐 Generating NX token...');
    final nxResponse = await client.auth.getNxToken(
      username: '+255788811191',
    );
    print('✅ NX token generated');

    final nxtoken = nxResponse['token'];
    final nxid = nxResponse['jid'];
    final wsUrl = nxResponse['nxws'];

    // Step 3: IMPORTANT - Set the token on the client for API authentication
    // This is required to avoid 403 errors when making API calls
    client.setToken(nxtoken);

    // Step 4: Create CallManager for P2P calling
    print('📞 Initializing CallManager...');
    final callManager = await client.createCallManager(
      nxtoken: nxtoken,
      nxid: nxid,
      wsUrl: wsUrl,
      name: 'Your Name',
      onCallStateChanged: (state) {
        print('📱 Call state changed: $state');
      },
      onIncomingCall: (callerName) {
        print('📞 Incoming call from: $callerName');
        // Show incoming call UI here
      },
      onCallEnded: (reason) {
        print('📞 Call ended: $reason');
      },
      onError: (error) {
        print('❌ Call error: $error');
      },
    );
    print('✅ CallManager initialized');

    // Step 5: Initiate a P2P call
    print('📞 Initiating P2P call...');
    await callManager.initiateCall(
      to: '+255788811192',
      audio: true,
      video: false,
    );
    print('✅ Call initiated');

    // Wait for call to connect (in real app, use state callbacks)
    await Future.delayed(const Duration(seconds: 5));

    // Step 6: End call
    print('📞 Ending call...');
    await callManager.endCall();
    print('✅ Call ended');

    // Step 7: Cleanup resources
    callManager.dispose();
  } on NexaconException catch (e) {
    print('❌ Error: ${e.message}');
  } finally {
    // Always close the client when done
    client.close();
  }
}
