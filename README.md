# Nexacon Flutter SDK

A comprehensive Flutter SDK for Nexacon API, providing plug-and-play P2P calling with WebRTC and NX signaling, plus real-time messaging with presence and read receipts.

## Overview

Nexacon Flutter SDK enables developers to integrate peer-to-peer audio and video calling and real-time messaging into their Flutter applications with minimal setup. The SDK handles all complex signaling, WebRTC peer connections, ICE negotiation, XMPP messaging, and presence management internally.

## Features

- **P2P Calling**: Full WebRTC peer-to-peer audio/video calling with automatic signaling
- **Real-Time Messaging**: Instant messaging with presence, typing indicators, and read receipts
- **Automatic Reconnection**: Built-in connection management with exponential backoff
- **Cross-Platform**: Works on Android, iOS, Linux, macOS, Web, and Windows
- **Foldable Device Support**: Detect fold state changes on Android devices
- **Call Controls**: Mute, speaker toggle, camera switch, duration tracking
- **Professional Error Handling**: Detailed console logging and validation

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  nexacon_sdk: ^1.1.6
```

Install the dependency:

```bash
flutter pub get
```

## Platform Requirements

| Platform | Minimum Version      | Notes                              |
| -------- | -------------------- | ---------------------------------- |
| Android  | API 21 (Android 5.0) | Requires camera/audio permissions  |
| iOS      | 12.0                 | Requires camera/audio permissions  |
| Linux    | Any                  | Works out of the box               |
| macOS    | 10.14                | Requires camera/audio entitlements |
| Web      | Modern browsers      | Requires WebRTC support            |
| Windows  | Any                  | Works out of the box               |

## Quick Start Guide

### Step 1: Initialize the Client

```dart
import 'package:nexacon_sdk/nexacon_sdk.dart';

// Create a NexaconClient instance
final client = NexaconClient(
  apiKey: 'your_api_key',
  secretKey: 'your_secret_key',
  // baseUrl is optional - defaults to https://nxservice.quantumvision-tech.com/api/v1.0
);
```

### Step 2: Generate NX Token

The NX token is required for XMPP signaling and API authentication.

```dart
try {
  final nxResponse = await client.auth.getNxToken(
    username: '+255788811191',
  );

  final nxtoken = nxResponse['token'];
  final nxid = nxResponse['jid'];
  final wsUrl = nxResponse['nxws'];

  // IMPORTANT: Set the token on the client for API authentication
  client.setToken(nxtoken);

  print('✅ NX token retrieved successfully');
} catch (e) {
  print('❌ Failed to get NX token: $e');
}
```

### Step 3: Create CallManager

```dart
final callManager = await client.createCallManager(
  nxtoken: nxtoken,
  nxid: nxid,
  wsUrl: wsUrl,
  name: 'Your Display Name',
  onCallStateChanged: (state) {
    print('Call state: $state');
    // Update UI based on state
  },
  onIncomingCall: (callerName) {
    print('Incoming call from: $callerName');
    // Show incoming call UI
  },
  onCallEnded: (reason) {
    print('Call ended: $reason');
    // Handle call end
  },
  onError: (error) {
    print('Call error: $error');
    // Show error to user
  },
);
```

### Step 4: Make a Call

```dart
// Initiate an outgoing call
try {
  await callManager.initiateCall(
    to: '+255788811192',
    audio: true,
    video: false,
  );
  print('✅ Call initiated');
} catch (e) {
  print('❌ Failed to initiate call: $e');
}

// Accept an incoming call
try {
  await callManager.acceptCall(
    audio: true,
    video: false,
  );
  print('✅ Call accepted');
} catch (e) {
  print('❌ Failed to accept call: $e');
}

// End the current call
await callManager.endCall();
```

### Step 5: Call Controls

```dart
// Toggle microphone (mute/unmute)
callManager.webrtcService?.toggleAudio(false); // mute
callManager.webrtcService?.toggleAudio(true);  // unmute

// Toggle camera (enable/disable)
callManager.webrtcService?.toggleVideo(false); // disable video
callManager.webrtcService?.toggleVideo(true);  // enable video

// Switch between front and back camera
await callManager.webrtcService?.switchCamera();

// Get call duration
final duration = callManager.callDuration;
print('Call duration: ${duration.inSeconds} seconds');
```

### Step 6: Cleanup

```dart
// Always dispose resources when done
callManager.dispose();
client.close();
```

### 7. Real-Time Messaging

```dart
// Create messaging manager
final messagingManager = client.createMessagingManager();

// Listen for messages
messagingManager.messageStream.listen((message) {
  print('Message: ${message['message']}');
});

// Send a message
messagingManager.sendMessage(
  to: 'recipient@example.com',
  message: 'Hello!',
);

// Send typing indicator
messagingManager.sendTypingIndicator('recipient@example.com', isTyping: true);

// Send read receipt
messagingManager.sendReadReceipt('recipient@example.com', 'msg_123');

// Listen for presence changes
messagingManager.presenceStream.listen((presence) {
  final isOnline = presence['type'] == null || presence['type'] == 'available';
  print('User is ${isOnline ? 'online' : 'offline'}');
});

// Cleanup
messagingManager.dispose();
```

### 8. Foldable Device Support

The SDK provides a `FoldStateService` for detecting foldable device state changes on Android.

```dart
import 'package:nexacon_sdk/nexacon_sdk.dart';

// Create fold state service
final foldStateService = FoldStateService();

// Listen for fold state changes
foldStateService.foldStateStream.listen((state) {
  switch (state) {
    case FoldState.flat:
      print('Device is flat');
      break;
    case FoldState.folded:
      print('Device is folded');
      break;
    case FoldState.halfOpen:
      print('Device is half open');
      break;
    case FoldState.unknown:
      print('Fold state unknown');
      break;
  }
});

// Check current state
if (foldStateService.isFolded) {
  // Adjust UI for folded state
}

// Cleanup
foldStateService.dispose();
```

**Android Native Implementation**

To enable actual fold detection on Android, you need to implement the native platform code. The SDK provides a reference implementation in `android/src/main/kotlin/com/nexacon/nexacon_sdk/FoldStatePlugin.kt`.

For production use, use Android's DeviceStateManager API:

```kotlin
val deviceStateManager = context.getSystemService(DeviceStateManager::class.java)
deviceStateManager.registerCallback(mainExecutor, object : DeviceStateCallback() {
    override fun onDeviceStateChanged(state: DeviceState) {
        // Handle fold state changes
    }
})
```

## Platform Configuration

### Android

Add permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.BLUETOOTH"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
```

Set minimum SDK version in `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        minSdkVersion 21
    }
}
```

### iOS

Add permissions to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required for video calls</string>
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access is required for audio calls</string>
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
  <string>voip</string>
</array>
```

Set minimum iOS version in `ios/Podfile`:

```ruby
platform :ios, '12.0'
```

### Linux

No additional configuration required. The SDK works out of the box on Linux.

### macOS

Add permissions to `macos/Runner/DebugProfile.entitlements` and `Release.entitlements`:

```xml
<key>com.apple.security.device.camera</key>
<true/>
<key>com.apple.security.device.microphone</key>
<true/>
<key>com.apple.security.network.client</key>
<true/>
```

### Web

No additional configuration required. The SDK works in modern browsers with WebRTC support.

### Windows

No additional configuration required. The SDK works out of the box on Windows.

## Features

- **NX Token Management**: Generate and refresh NX tokens for signaling
- **P2P Calling**: Full WebRTC peer-to-peer calling with automatic signaling
- **Real-Time Messaging**: Instant messaging with presence
- **Typing Indicators**: Real-time typing status
- **Read Receipts**: Message delivery and read confirmations
- **Presence Management**: Online/offline status tracking
- **Message History**: Fetch message history with filters and pagination
- **Automatic Reconnection**: Built-in connection with exponential backoff
- **ICE Management**: Automatic ICE candidate buffering and exchange
- **Call Controls**: Mute, speaker toggle, camera switch
- **Duration Tracking**: Built-in call duration timer
- **Foldable Device Support**: Detect fold state changes on Android
- **Cross-platform**: Works on Android, iOS, Linux, macOS, Web, Windows

## Call States

| State       | Description               |
| ----------- | ------------------------- |
| `idle`      | No active call            |
| `calling`   | Outgoing call in progress |
| `incoming`  | Incoming call received    |
| `connected` | Call established          |
| `ended`     | Call ended                |

## API Reference

### NexaconClient

Main client for API interactions.

```dart
final client = NexaconClient(
  apiKey: String,
  secretKey: String,
  baseUrl: String,
);
```

### CallManager

Manages P2P calls with automatic signaling.

```dart
final callManager = await client.createCallManager(
  nxtoken: String,
  nxid: String,
  wsUrl: String,
  name: String?,
  onCallStateChanged: Function(CallState)?,
  onIncomingCall: Function(String)?,
  onCallEnded: Function(String)?,
  onError: Function(String)?,
);
```

#### Methods

- `initiateCall({required String to, bool audio, bool video})` - Initiate outgoing call
- `acceptCall({bool audio, bool video})` - Accept incoming call
- `rejectCall()` - Reject incoming call
- `endCall()` - End current call
- `dispose()` - Cleanup resources

### Auth

NX token management.

```dart
final response = await client.auth.getNxToken(
  username: String,
);
```

### MessagingManager

Real-time messaging with presence and read receipts.

```dart
final messagingManager = client.createMessagingManager();
```

#### Streams

- `messageStream` - Incoming chat messages
- `typingStream` - Typing indicators
- `readReceiptStream` - Read confirmations
- `deliveryReceiptStream` - Delivery confirmations (XEP-0184)
- `presenceStream` - Online/offline status

#### Methods

- `sendMessage({required String to, required String message, String messageType})` - Send message
- `sendTypingIndicator(String to, {bool isTyping})` - Send typing status
- `sendReadReceipt(String to, String messageId)` - Send read receipt
- `dispose()` - Cleanup resources

### FoldStateService

Foldable device state detection service.

```dart
final foldStateService = FoldStateService();
```

#### Streams

- `foldStateStream` - Stream of fold state changes

#### Properties

- `currentState` - Current fold state
- `isFolded` - Whether device is folded
- `isFlat` - Whether device is flat
- `isHalfOpen` - Whether device is half open

#### Methods

- `updateFoldState(FoldState state)` - Manually update fold state
- `dispose()` - Cleanup resources

## Troubleshooting

### Common Issues

#### 403 Error When Initiating Calls

**Problem**: You get a 403 error when calling `initiateCall()`.

**Solution**: Make sure to set the NX token on the client after generating it:

```dart
final nxResponse = await client.auth.getNxToken(username: '+255788811191');
final nxtoken = nxResponse['token'];

// IMPORTANT: This line is required for API authentication
client.setToken(nxtoken);
```

#### Connection Timeout

**Problem**: WebSocket connection times out or fails to connect.

**Solution**:

- Check your internet connection
- Verify the `wsUrl` is correct and accessible
- Ensure your firewall allows WebSocket connections
- The SDK has built-in automatic reconnection with exponential backoff

#### Camera/Microphone Not Working

**Problem**: Camera or microphone doesn't work during calls.

**Solution**:

- **Android**: Ensure permissions are granted in `AndroidManifest.xml`
- **iOS**: Ensure permissions are added to `Info.plist` and granted by user
- **Web**: Ensure the app is served over HTTPS (required for WebRTC)
- Check if the device has another app using the camera/microphone

#### Call State Stuck in "Calling"

**Problem**: Call state remains in "calling" and never transitions.

**Solution**:

- Ensure both users have stable internet connections
- Check if the callee is online and has the SDK initialized
- Verify the recipient's JID is correct
- The call will timeout after 60 seconds if not accepted

#### XMPP Connection Issues

**Problem**: XMPP connection fails or disconnects frequently.

**Solution**:

- Verify the `nxid` and `nxtoken` are valid
- Check if the XMPP server is accessible
- The SDK automatically reconnects with exponential backoff
- Check console logs for detailed error messages

### Debug Mode

Enable detailed logging by checking the console output. The SDK provides emoji-based logging:

- 🔐 - Authentication operations
- 📞 - Call operations
- 📡 - Signaling/WebRTC operations
- ❌ - Errors
- ✅ - Success operations

### Getting Help

If you encounter issues not covered here:

1. Check the [full documentation](https://nexacon-flutter-sdk.readthedocs.io/)
2. Review the [example app](https://github.com/jenadiusnicholaus/nexacon-flutter-sdk/tree/main/example)
3. Open an issue on [GitHub](https://github.com/jenadiusnicholaus/nexacon-flutter-sdk/issues)

## Documentation

Full documentation available at [nexacon-flutter-sdk.readthedocs.io](https://nexacon-flutter-sdk.readthedocs.io/)

## License

MIT License - see LICENSE file for details.
