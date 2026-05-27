# Nexacon Flutter SDK

A comprehensive Flutter SDK for Nexacon API, providing plug-and-play P2P calling with WebRTC and NX signaling.

## Overview

Nexacon Flutter SDK enables developers to integrate peer-to-peer audio and video calling into their Flutter applications with minimal setup. The SDK handles all complex signaling, WebRTC peer connections, and ICE negotiation internally.

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  nexacon_sdk: ^1.0.0
```

Install the dependency:

```bash
flutter pub get
```

## Getting Started

### 1. Initialize the Client

```dart
import 'package:nexacon_sdk/nexacon_sdk.dart';

final client = NexaconClient(
  apiKey: 'your_api_key',
  secretKey: 'your_secret_key',
  baseUrl: 'https://nxservice.quantumvision-tech.com/api/v1.0',
);
```

### 2. Generate NX Token

```dart
final nxResponse = await client.auth.generateXMPPToken(
  username: '+255788811191',
);
final nxtoken = nxResponse['token'];
final nxid = nxResponse['jid'];
final wsUrl = nxResponse['nxws'];
```

### 3. Create CallManager

```dart
final callManager = await client.createCallManager(
  nxtoken: nxtoken,
  nxid: nxid,
  wsUrl: wsUrl,
  name: 'Your Name',
  onCallStateChanged: (state) {
    // Handle call state changes
  },
  onIncomingCall: (callerName) {
    // Show incoming call UI
  },
  onCallEnded: (reason) {
    // Handle call ended
  },
  onError: (error) {
    // Handle errors
  },
);
```

### 4. Make a Call

```dart
// Outgoing call
await callManager.initiateCall(
  to: '+255788811192',
  audio: true,
  video: false,
);

// Accept incoming call
await callManager.acceptCall(
  audio: true,
  video: false,
);

// End call
await callManager.endCall();
```

### 5. Call Controls

```dart
// Mute/Unmute
callManager.webrtcService?.toggleAudio(false);

// Speaker toggle
callManager.webrtcService?.toggleSpeaker(true);

// Switch camera
await callManager.webrtcService?.switchCamera();
```

### 6. Cleanup

```dart
callManager.dispose();
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

## Features

- **NX Token Management**: Generate and refresh NX tokens for signaling
- **P2P Calling**: Full WebRTC peer-to-peer calling with automatic signaling
- **Automatic Reconnection**: Built-in WebSocket client with reconnection logic
- **ICE Management**: Automatic ICE candidate buffering and exchange
- **Call Controls**: Mute, speaker toggle, camera switch
- **Duration Tracking**: Built-in call duration timer
- **Cross-platform**: Works on iOS, Android, Web, Desktop

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
final response = await client.auth.generateXMPPToken(
  username: String,
);
```

## Documentation

Full documentation available at [nexacon-flutter-sdk.readthedocs.io](https://nexacon-flutter-sdk.readthedocs.io/)

## License

MIT License - see LICENSE file for details.
