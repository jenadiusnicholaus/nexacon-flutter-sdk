# Nexacon Flutter SDK

[![pub.dev](https://img.shields.io/pub/v/nexacon_sdk.svg)](https://pub.dev/packages/nexacon_sdk)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-android%20%7C%20ios%20%7C%20web%20%7C%20linux%20%7C%20macos%20%7C%20windows-blue)](https://pub.dev/packages/nexacon_sdk)

A comprehensive Flutter SDK for Nexacon API — providing plug-and-play P2P audio/video calling with WebRTC and NX signaling, plus real-time messaging with presence and read receipts.

---

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Platform Requirements](#platform-requirements)
- [Platform Configuration](#platform-configuration)
- [Quick Start — Outgoing Call](#quick-start--outgoing-call)
- [Quick Start — Incoming Call](#quick-start--incoming-call)
- [Advanced Usage](#advanced-usage)
- [Real-Time Messaging](#real-time-messaging)
- [Foldable Device Support](#foldable-device-support)
- [Call States](#call-states)
- [API Reference](#api-reference)
- [Troubleshooting](#troubleshooting)

---

## Features

- **Simplified API**: Make or receive calls in 3 steps with `NexaconSDK`
- **P2P Calling**: Full WebRTC peer-to-peer audio/video calling with automatic signaling
- **NX Token Management**: Automatic token generation, validation, and client authentication
- **Incoming Call Support**: `initialize()` + `acceptCall()` for clean incoming call handling
- **Real-Time Messaging**: Instant messaging with typing indicators and read receipts
- **Presence Management**: Online/offline status tracking
- **Call Controls**: Mute, speaker toggle, video toggle, camera switch, duration tracking
- **Automatic Reconnection**: Built-in connection management with exponential backoff
- **ICE Management**: Automatic ICE candidate buffering and exchange
- **Foldable Device Support**: Detect fold state changes on Android devices
- **Cross-Platform**: Android, iOS, Web, Linux, macOS, Windows
- **Professional Logging**: Emoji-based console logging for easy debugging

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  nexacon_sdk: ^1.2.0
```

Install:

```bash
flutter pub get
```

---

## Platform Requirements

| Platform | Minimum Version      | Notes                              |
| -------- | -------------------- | ---------------------------------- |
| Android  | API 21 (Android 5.0) | Requires camera/audio permissions  |
| iOS      | 12.0                 | Requires camera/audio permissions  |
| Linux    | Any                  | Works out of the box               |
| macOS    | 10.14                | Requires camera/audio entitlements |
| Web      | Modern browsers      | Requires WebRTC support            |
| Windows  | Any                  | Works out of the box               |

---

## Platform Configuration

### Android

Add to `android/app/src/main/AndroidManifest.xml`:

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

Set minimum SDK in `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        minSdkVersion 21
    }
}
```

### iOS

Add to `ios/Runner/Info.plist`:

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

### macOS

Add to `macos/Runner/DebugProfile.entitlements` and `Release.entitlements`:

```xml
<key>com.apple.security.device.camera</key>
<true/>
<key>com.apple.security.device.microphone</key>
<true/>
<key>com.apple.security.network.client</key>
<true/>
```

### Web, Linux, Windows

No additional configuration required.

---

## Quick Start — Outgoing Call

Use `NexaconSDK` for the simplest possible integration:

```dart
import 'package:nexacon_sdk/nexacon_sdk.dart';

final sdk = NexaconSDK(
  apiKey: 'your_api_key',
  secretKey: 'your_secret_key',
);

// Set up callbacks
sdk.onCallStateChanged = (state) => print('📱 State: $state');
sdk.onCallEnded       = (reason) => print('📞 Ended: $reason');
sdk.onError           = (error)  => print('❌ Error: $error');

// Start an outgoing call — handles token, connection & signaling automatically
await sdk.startCall(
  to: '+255788811192',       // recipient
  username: '+255788811191', // your username
  audio: true,
  video: false,
);

// In-call controls
sdk.toggleMute(true);     // mute microphone
sdk.toggleSpeaker(true);  // enable speaker
sdk.toggleVideo(true);    // enable video
await sdk.switchCamera(); // switch front/back camera

// End call and release resources
await sdk.endCall();
await sdk.dispose();
```

---

## Quick Start — Incoming Call

Incoming calls can be handled via two paths:

### Path 1: XMPP (app in foreground)

Use `acceptWhenReady()` when the app is already open — it waits for the XMPP `callInvitation` signal:

```dart
import 'package:nexacon_sdk/nexacon_sdk.dart';

final sdk = NexaconSDK(
  apiKey: 'your_api_key',
  secretKey: 'your_secret_key',
);

// Set up callbacks
sdk.onCallStateChanged = (state) => print('📱 State: $state');
sdk.onIncomingCall     = (name)  => print('📞 Incoming from: $name');
sdk.onCallEnded        = (reason)=> print('📞 Ended: $reason');
sdk.onError            = (error) => print('❌ Error: $error');

// Initialize and automatically accept when XMPP signal arrives
await sdk.acceptWhenReady(
  username: '+255788811191',
  audio: true,
  video: false,
);

// End call and release resources
await sdk.endCall();
await sdk.dispose();
```

### Path 2: Push Notification (app opened from FCM)

Use `acceptFromNotification()` when the user opens the app from a push notification — the FCM payload already contains `roomId` and `callerJid`:

```dart
// Called when user taps the FCM notification
await sdk.acceptFromNotification(
  username: '+255788811191',
  roomId: fcmData['room'],      // from FCM payload
  callerJid: fcmData['caller'], // from FCM payload
  callerName: fcmData['caller_name'],
  audio: true,
  video: false,
);
```

---

## Advanced Usage

For full low-level control, use `NexaconClient` directly.

### Step 1: Initialize Client

```dart
import 'package:nexacon_sdk/nexacon_sdk.dart';

final client = NexaconClient(
  apiKey: 'your_api_key',
  secretKey: 'your_secret_key',
  // baseUrl is optional — defaults to https://nxservice.quantumvision-tech.com/api/v1.0
);
```

### Step 2: Generate NX Token

```dart
final nxResponse = await client.auth.getNxToken(username: '+255788811191');

final nxtoken = nxResponse['token'];
final nxid    = nxResponse['jid'];
final wsUrl   = nxResponse['nxws'];

// IMPORTANT: Required to avoid 403 errors on subsequent API calls
client.setToken(nxtoken);
```

### Step 3: Create CallManager

```dart
final callManager = await client.createCallManager(
  nxtoken: nxtoken,
  nxid: nxid,
  wsUrl: wsUrl,
  name: 'Your Display Name',
  onCallStateChanged: (state) {
    if (state == CallState.connected) print('✅ Connected');
  },
  onIncomingCall: (callerName) => print('📞 Incoming: $callerName'),
  onCallEnded:    (reason)     => print('📞 Ended: $reason'),
  onError:        (error)      => print('❌ $error'),
);
```

### Step 4: Make or Accept a Call

```dart
// Outgoing call
await callManager.initiateCall(to: '+255788811192', audio: true, video: false);

// Accept incoming call
await callManager.acceptCall(audio: true, video: false);

// Reject incoming call
callManager.rejectCall();

// End current call
await callManager.endCall();
```

### Step 5: In-Call Controls

```dart
callManager.webrtcService?.toggleAudio(false);  // mute
callManager.webrtcService?.toggleAudio(true);   // unmute
callManager.webrtcService?.toggleVideo(false);  // disable video
callManager.webrtcService?.toggleVideo(true);   // enable video
callManager.webrtcService?.toggleSpeaker(true); // speaker on
await callManager.webrtcService?.switchCamera();

final duration = callManager.callDuration;
print('Duration: ${duration.inSeconds}s');
```

### Step 6: Cleanup

```dart
callManager.dispose();
client.close();
```

---

## Real-Time Messaging

```dart
final messagingManager = client.createMessagingManager();

// Receive messages
messagingManager.messageStream.listen((message) {
  print('💬 ${message['from']}: ${message['message']}');
});

// Send a message
messagingManager.sendMessage(to: 'recipient@example.com', message: 'Hello!');

// Typing indicator
messagingManager.sendTypingIndicator('recipient@example.com', isTyping: true);

// Read receipt
messagingManager.sendReadReceipt('recipient@example.com', 'msg_123');

// Presence (online/offline)
messagingManager.presenceStream.listen((presence) {
  final isOnline = presence['type'] == null || presence['type'] == 'available';
  print('User is ${isOnline ? 'online' : 'offline'}');
});

messagingManager.dispose();
```

---

## Foldable Device Support

```dart
final foldStateService = FoldStateService();

foldStateService.foldStateStream.listen((state) {
  switch (state) {
    case FoldState.flat:     print('Device is flat');
    case FoldState.folded:   print('Device is folded');
    case FoldState.halfOpen: print('Device is half open');
    case FoldState.unknown:  print('Fold state unknown');
  }
});

if (foldStateService.isFolded) {
  // Adjust UI for folded state
}

foldStateService.dispose();
```

---

## Call States

| State       | Description               |
| ----------- | ------------------------- |
| `idle`      | No active call            |
| `calling`   | Outgoing call in progress |
| `incoming`  | Incoming call received    |
| `connected` | Call connected            |
| `ended`     | Call ended                |

---

## API Reference

### NexaconSDK _(Simplified)_

```dart
NexaconSDK({required String apiKey, required String secretKey, String? baseUrl})
```

| Method                                                                                           | Description                                                      |
| ------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------- |
| `initialize({required username, name})`                                                          | Connect to signaling without dialing — use for incoming calls    |
| `startCall({required to, required username, name, audio, video})`                                | Start outgoing call — handles everything internally              |
| `acceptWhenReady({required username, name, audio, video, timeout})`                              | Initialize and auto-accept when XMPP signal arrives (foreground) |
| `acceptFromNotification({required username, roomId, callerJid, callerName, name, audio, video})` | Accept using FCM/push payload data (background)                  |
| `acceptCall({audio, video})`                                                                     | Accept an incoming call (must be in `incoming` state)            |
| `rejectCall()`                                                                                   | Reject an incoming call                                          |
| `endCall()`                                                                                      | End the current call                                             |
| `toggleMute(bool muted)`                                                                         | Toggle microphone                                                |
| `toggleSpeaker(bool enabled)`                                                                    | Toggle speaker                                                   |
| `toggleVideo(bool enabled)`                                                                      | Toggle video                                                     |
| `switchCamera()`                                                                                 | Switch front/back camera                                         |
| `dispose()`                                                                                      | Cleanup all resources                                            |

| Property       | Type       | Description           |
| -------------- | ---------- | --------------------- |
| `callDuration` | `Duration` | Current call duration |

| Callback             | Signature             | Description               |
| -------------------- | --------------------- | ------------------------- |
| `onCallStateChanged` | `Function(CallState)` | Call state updates        |
| `onIncomingCall`     | `Function(String)`    | Incoming call received    |
| `onCallEnded`        | `Function(String)`    | Call ended with reason    |
| `onError`            | `Function(String)`    | Error occurred            |
| `onLocalStream`      | `Function()`          | Local video stream ready  |
| `onRemoteStream`     | `Function()`          | Remote video stream ready |

---

### NexaconClient _(Advanced)_

```dart
NexaconClient({required String apiKey, required String secretKey, String? baseUrl})
```

| Method                                 | Description                        |
| -------------------------------------- | ---------------------------------- |
| `auth.getNxToken({required username})` | Generate NX token                  |
| `setToken(String token)`               | Set NX token for API auth          |
| `createCallManager({...})`             | Create a CallManager instance      |
| `createMessagingManager()`             | Create a MessagingManager instance |
| `close()`                              | Close the client                   |

---

### CallManager

| Method                                      | Description          |
| ------------------------------------------- | -------------------- |
| `initiateCall({required to, audio, video})` | Start outgoing call  |
| `acceptCall({audio, video})`                | Accept incoming call |
| `rejectCall()`                              | Reject incoming call |
| `endCall()`                                 | End current call     |
| `dispose()`                                 | Cleanup resources    |

---

### MessagingManager

| Stream              | Description       |
| ------------------- | ----------------- |
| `messageStream`     | Incoming messages |
| `typingStream`      | Typing indicators |
| `readReceiptStream` | Read receipts     |
| `presenceStream`    | Presence changes  |

| Method                                         | Description        |
| ---------------------------------------------- | ------------------ |
| `sendMessage({required to, required message})` | Send a message     |
| `sendTypingIndicator(to, {isTyping})`          | Send typing status |
| `sendReadReceipt(to, messageId)`               | Send read receipt  |
| `dispose()`                                    | Cleanup            |

---

## Troubleshooting

### 403 Error on Call Initiation

**Cause**: NX token not set on the client.

**Fix** (Advanced API only — `NexaconSDK` handles this automatically):

```dart
client.setToken(nxtoken); // Must be called after getNxToken()
```

### XMPP Connection Timeout

**Cause**: WebSocket URL uses `https://` instead of `wss://`.

**Fix**: `NexaconSDK` converts this automatically. If using `NexaconClient` directly, ensure `wsUrl` starts with `wss://`.

### Camera / Microphone Not Working

- **Android**: Ensure permissions are in `AndroidManifest.xml` and granted at runtime
- **iOS**: Ensure keys are in `Info.plist`
- **Web**: App must be served over HTTPS (WebRTC requirement)

### Call Stuck in "Calling"

- Ensure the callee is online with the SDK initialized
- Calls time out after **60 seconds** if not accepted

### Console Log Reference

| Emoji | Meaning            |
| ----- | ------------------ |
| 🔐    | Authentication     |
| 📞    | Call operations    |
| 📡    | Signaling / WebRTC |
| ✅    | Success            |
| ❌    | Error              |
| ⚠️    | Warning            |

### Getting Help

1. 📖 [Full Documentation](https://nexacon-flutter-sdk.readthedocs.io/)
2. 💡 [Example App](https://github.com/jenadiusnicholaus/nexacon-flutter-sdk/tree/main/example)
3. 🐛 [Report an Issue](https://github.com/jenadiusnicholaus/nexacon-flutter-sdk/issues)

---

## License

MIT License — see [LICENSE](LICENSE) for details.
