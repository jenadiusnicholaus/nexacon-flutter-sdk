import '../lib/nexacon_calls.dart';

/// Basic usage example for Nexacon Flutter SDK
/// This demonstrates the minimal setup required to make a P2P call
///
/// Best Practices:
/// 1. Always format phone numbers with country code (e.g., +255 for Tanzania)
/// 2. Handle call states properly (ringing, connecting, connected, ended)
/// 3. Use flags to prevent duplicate endCall calls
/// 4. Check connection state in onOtherUserLeft to prevent premature call ending
/// 5. Avoid duplicate operations - don't handle CallState.ended in onCallStateChanged
///    if you're also using onCallEnded callback to prevent race conditions
void main() async {
  // Step 1: Create SDK instance with your API credentials
  final sdk = NexaconSDK(
    apiKey: 'your_api_key',
    secretKey: 'your_secret_key',
  );

  // Step 2: Set up callbacks
  sdk.onCallStateChanged = (CallState state) {
    print('📱 Call state changed: $state');
    if (state == CallState.connected) {
      print('✅ Call is now connected');
    } else if (state == CallState.ended) {
      print('📞 Call has ended');
    }
  };
  sdk.onIncomingCall = (callerName) {
    print('📞 Incoming call from: $callerName');
    // Show incoming call UI here
    // Use sdk.acceptCall() to answer or sdk.rejectCall() to decline
  };
  sdk.onCallEnded = (reason) {
    print('📞 Call ended: $reason');
    // Clean up UI and navigate away from call screen
  };
  sdk.onOtherUserJoined = () {
    print('✅ Remote peer joined the call');
  };
  sdk.onOtherUserLeft = () {
    print('🚪 Remote peer left the call');
    // End call when peer leaves
  };
  sdk.onError = (error) {
    print('❌ Call error: $error');
    // Show error to user and handle gracefully
  };
  sdk.onLocalStream = () => print('📹 Local stream ready');
  sdk.onRemoteStream = () => print('📹 Remote stream ready');

  try {
    // Step 3: Initiate a P2P call
    // IMPORTANT: Phone numbers must include country code for NX ID compatibility
    print('📞 Initiating P2P call...');
    await sdk.startCall(
      to: '+255788811192', // recipient
      username: '+255788811191', // your username
      name: 'Your Name',
      audio: true,
      video: false,
    );
    print('✅ Call initiated - waiting for recipient to answer');

    // Wait for call to connect (in real app, use state callbacks)
    await Future.delayed(const Duration(seconds: 5));

    // Step 4: In-call controls
    sdk.toggleMute(true); // mute microphone
    sdk.toggleSpeaker(true); // enable speaker
    sdk.toggleVideo(true); // enable video
    await sdk.switchCamera(); // switch front/back camera

    // Step 5: End call
    print('📞 Ending call...');
    await sdk.endCall();
    print('✅ Call ended');
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    // Step 6: Cleanup resources
    await sdk.dispose();
  }
}
