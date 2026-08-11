import '../lib/nexacon_calls.dart';

/// Basic usage example for Nexacon Flutter SDK
/// This demonstrates the minimal setup required to make a P2P call
/// using production patterns from real apps.
///
/// Best Practices:
/// 1. Always format phone numbers with country code (e.g., +255 for Tanzania)
/// 2. Request permissions BEFORE starting a call
/// 3. Use onOtherUserJoined to track when the peer actually connects
/// 4. Use onOtherUserLeft to end the call when the peer disconnects
/// 5. Pre-warm the connection for faster call setup
/// 6. Always call dispose() when done to free WebRTC resources
void main() async {
  final sdk = NexaconSDK(
    apiKey: 'your_api_key',
    secretKey: 'your_secret_key',
  );

  // Set up callbacks BEFORE making a call
  sdk.onCallStateChanged = (CallState state) {
    if (state == CallState.calling) {
      // Show ringing UI — waiting for recipient to answer
    } else if (state == CallState.connected) {
      // Start call duration timer
    }
  };
  sdk.onIncomingCall = (callerName) {
    // Incoming call received — show incoming call UI
  };
  sdk.onOtherUserJoined = () {
    // Remote peer's WebRTC stream arrived — stop ringing, show active call
  };
  sdk.onOtherUserLeft = () {
    // Remote peer left — end the call
    sdk.endCall();
  };
  sdk.onCallEnded = (reason) {
    // Clean up UI, show call summary
  };
  sdk.onError = (error) {
    // Show error to user
  };
  sdk.onLocalStream = () {
    // Local video/audio stream is ready — render preview
  };
  sdk.onRemoteStream = () {
    // Remote video/audio stream is ready — render remote view
  };

  try {
    // Step 1: Pre-warm the connection (optional but recommended)
    // Do this before the user taps call for faster setup
    await sdk.initialize(
      username: '+255788811191',
      name: 'John Doe',
    );

    // Step 2: Start an outgoing call
    // The SDK handles token generation, NX connection, and signaling automatically
    await sdk.startCall(
      to: '+255788811192', // recipient (with country code)
      username: '+255788811191', // your username (with country code)
      name: 'John Doe',
      audio: true,
      video: false,
    );

    // Step 3: In-call controls
    sdk.toggleMute(true); // mute microphone
    sdk.toggleSpeaker(true); // enable speaker
    sdk.toggleVideo(true); // enable video (for video calls)
    await sdk.switchCamera(); // switch front/back camera

    // Step 4: End the call
    await sdk.endCall();
  } catch (e) {
    // Handle errors gracefully
  } finally {
    // Step 5: Always dispose to free WebRTC resources
    await sdk.dispose();
  }
}

/// Format a phone number with Tanzania country code.
/// The SDK uses phone numbers as NX IDs — always include the country code.
String formatPhoneWithCountryCode(String phone) {
  final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
  if (digits.startsWith('255')) return '+$digits';
  if (digits.startsWith('0')) return '+255${digits.substring(1)}';
  return '+255$digits';
}

/// Example: Accepting an incoming call from a push notification (FCM)
Future<void> acceptCallFromNotification({
  required NexaconSDK sdk,
  required String phoneNumber,
  required String channelName,
  required String callerPhone,
  String? name,
}) async {
  // Pre-warm the connection as soon as the incoming call screen opens
  await sdk.initialize(username: phoneNumber, name: name);

  // Accept using FCM payload data — bypasses waiting for signaling
  await sdk.acceptFromNotification(
    username: phoneNumber,
    roomId: channelName,
    callerNxId: callerPhone,
    name: name,
    audio: true,
    video: false,
  );

  // If signaling is delayed, notify SDK that the remote party accepted
  sdk.notifyRemoteAccepted();
}

/// Example: Accepting an incoming call in the foreground
Future<void> acceptCallInForeground({
  required NexaconSDK sdk,
  required String phoneNumber,
  String? name,
}) async {
  // Pre-warm the connection
  await sdk.initialize(username: phoneNumber, name: name);

  // Wait for the NX call invitation signal, then auto-accept
  await sdk.acceptWhenReady(
    username: phoneNumber,
    name: name,
    audio: true,
    video: false,
  );
}
