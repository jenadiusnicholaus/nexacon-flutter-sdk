import '../lib/nexacon_sdk.dart';

/// Basic usage example for Nexacon Flutter SDK
/// This demonstrates the minimal setup required to make a P2P call
///
/// Best Practices:
/// 1. Always format phone numbers with country code (e.g., +255 for Tanzania)
/// 2. Always call client.setToken(nxtoken) after getting NX token to avoid 403 errors
/// 3. Handle call states properly (ringing, connecting, connected, ended)
/// 4. Use flags to prevent duplicate endCall calls
/// 5. Handle cancelCall failures by falling back to endCall
/// 6. Check connection state in onOtherUserLeft to prevent premature call ending
/// 7. Avoid duplicate operations - don't handle CallState.ended in onCallStateChanged
///    if you're also using onCallEnded callback to prevent race conditions
void main() async {
  // Step 1: Initialize the client with your API credentials
  final client = NexaconClient(
    apiKey: 'your_api_key',
    secretKey: 'your_secret_key',
    // baseUrl is optional - defaults to https://nxservice.quantumvision-tech.com/api/v1.0
  );

  try {
    // Step 2: Generate NX token for XMPP signaling and API authentication
    // IMPORTANT: Phone number must include country code for NX JID compatibility
    print('🔐 Generating NX token...');
    final nxResponse = await client.auth.getNxToken(
      username: '+255788811191', // Format: +<country_code><phone_number>
    );
    print('✅ NX token generated');

    final nxtoken = nxResponse['token'];
    final nxid = nxResponse['jid'];
    final wsUrl = nxResponse['nxws'];

    // Step 3: CRITICAL - Set the token on the client for API authentication
    // This is REQUIRED to avoid 403 errors when making API calls
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
        // Handle different states: ringing, connecting, connected, ended
        if (state == CallState.connected) {
          print('✅ Call is now connected');
        } else if (state == CallState.ended) {
          print('📞 Call has ended');
        }
      },
      onIncomingCall: (callerName) {
        print('📞 Incoming call from: $callerName');
        // Show incoming call UI here
        // Use callManager.acceptCall() to answer or callManager.rejectCall() to decline
      },
      onCallEnded: (reason) {
        print('📞 Call ended: $reason');
        // Clean up UI and navigate away from call screen
      },
      onError: (error) {
        print('❌ Call error: $error');
        // Show error to user and handle gracefully
      },
    );
    print('✅ CallManager initialized');

    // Step 5: Initiate a P2P call
    // IMPORTANT: Recipient phone number must also include country code
    print('📞 Initiating P2P call...');
    await callManager.initiateCall(
      to: '+255788811192', // Format: +<country_code><phone_number>
      audio: true,
      video: false,
    );
    print('✅ Call initiated - waiting for recipient to answer');

    // Wait for call to connect (in real app, use state callbacks)
    await Future.delayed(const Duration(seconds: 5));

    // Step 6: End call
    print('📞 Ending call...');
    await callManager.endCall();
    print('✅ Call ended');

    // Step 7: Cleanup resources
    // IMPORTANT: Always dispose CallManager when done to free WebRTC resources
    callManager.dispose();
  } on NexaconException catch (e) {
    print('❌ Error: ${e.message}');
    // Handle specific Nexacon errors (network, auth, etc.)
  } catch (e) {
    print('❌ Unexpected error: $e');
  } finally {
    // Always close the client when done to release connections
    client.close();
  }
}
