# Nexacon Flutter SDK

[![pub.dev](https://img.shields.io/pub/v/nexacon_calls.svg)](https://pub.dev/packages/nexacon_calls)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-android%20%7C%20ios%20%7C%20linux%20%7C%20macos%20%7C%20windows-blue)](https://pub.dev/packages/nexacon_calls)

A Flutter SDK for Nexacon API — plug-and-play P2P audio/video calling with WebRTC and NX signaling.

---

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Platform Requirements](#platform-requirements)
- [Platform Configuration](#platform-configuration)
- [Quick Start — Outgoing Call](#quick-start--outgoing-call)
- [Quick Start — Incoming Call](#quick-start--incoming-call)
- [Push Notification Routing](#push-notification-routing)
- [Pre-warming](#pre-warming)
- [Advanced Usage](#advanced-usage)
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
- **Consecutive Call Safety**: SDK automatically resets all internal state after each call — safe for back-to-back calls
- **Stale Signal Guard**: Signaling messages from previous calls are filtered by room ID and cancelled subscription — no ghost `call_end` events
- **Pre-warming**: Establish NX connection before dialing for faster call setup
- **Push Notification Accept**: Accept calls from FCM data without waiting for signaling
- **Call Controls**: Mute, speaker toggle, video toggle, camera switch, duration tracking
- **Automatic Reconnection**: Built-in connection management with exponential backoff
- **ICE Management**: Automatic ICE candidate buffering and exchange
- **Foldable Device Support**: Detect fold state changes on Android devices
- **Cross-Platform**: Android, iOS, Linux, macOS, Windows
- **Professional Logging**: Emoji-based console logging for easy debugging

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  nexacon_calls: ^1.3.16
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

### Linux, Windows

No additional configuration required.

---

## Quick Start — Outgoing Call

Use `NexaconSDK` for the simplest possible integration:

```dart
import 'package:nexacon_calls/nexacon_calls.dart';
import 'package:permission_handler/permission_handler.dart';

final sdk = NexaconSDK(
  apiKey: 'your_api_key',
  secretKey: 'your_secret_key',
);

// 1. Request permissions (required before calling)
await Permission.microphone.request();
await Permission.camera.request();

// 2. Set up callbacks
sdk.onCallStateChanged = (state) {
  if (state == CallState.calling) {
    // Show ringing UI
  } else if (state == CallState.connected) {
    // Start call duration timer
  }
};
sdk.onOtherUserJoined = () {
  // Remote peer joined — stop ringing, show active call UI
};
sdk.onOtherUserLeft = () {
  // Remote peer left — end the call
  sdk.endCall();
};
sdk.onCallEnded = (reason) => print('📞 Ended: $reason');
sdk.onError     = (error)  => print('❌ Error: $error');
sdk.onLocalStream  = () => print('📹 Local stream ready');
sdk.onRemoteStream = () => print('📹 Remote stream ready');

// 3. Start an outgoing call — handles token, connection & signaling automatically
await sdk.startCall(
  to: '+255788811192',       // recipient
  username: '+255788811191', // your username
  name: 'John Doe',          // optional display name
  audio: true,
  video: false,
);

// 4. In-call controls
sdk.toggleMute(true);     // mute microphone
sdk.toggleSpeaker(true);  // enable speaker
sdk.toggleVideo(true);    // enable video
await sdk.switchCamera(); // switch front/back camera

// 5. End call and release resources
await sdk.endCall();
await sdk.dispose();
```

### Phone Number Formatting

The SDK uses phone numbers as NX IDs. Always include the country code:

```dart
String formatPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
  if (digits.startsWith('255')) return '+$digits';
  if (digits.startsWith('0')) return '+255${digits.substring(1)}';
  return '+255$digits';
}
```

---

## Quick Start — Incoming Call

Incoming calls can be handled via two paths:

### Path 1: NX (app in foreground)

Use `acceptWhenReady()` when the app is already open — it waits for the NX `callInvitation` signal:

```dart
import 'package:nexacon_calls/nexacon_calls.dart';
import 'package:permission_handler/permission_handler.dart';

final sdk = NexaconSDK(
  apiKey: 'your_api_key',
  secretKey: 'your_secret_key',
);

// Request permissions
await Permission.microphone.request();

// Set up callbacks (same as outgoing)
sdk.onCallStateChanged = (state) => print('📱 State: $state');
sdk.onIncomingCall     = (name)  => print('📞 Incoming from: $name');
sdk.onOtherUserJoined  = ()      => print('✅ Peer joined');
sdk.onOtherUserLeft    = ()      => sdk.endCall();
sdk.onCallEnded        = (reason)=> print('📞 Ended: $reason');
sdk.onError            = (error) => print('❌ Error: $error');
sdk.onLocalStream      = ()      => print('📹 Local stream ready');
sdk.onRemoteStream     = ()      => print('📹 Remote stream ready');

// Initialize and automatically accept when NX signal arrives
await sdk.acceptWhenReady(
  username: '+255788811191',
  name: 'John Doe',
  audio: true,
  video: false,
);

// End call and release resources
await sdk.endCall();
await sdk.dispose();
```

### Path 2: Push Notification (app opened from FCM)

Use `acceptFromNotification()` when the user opens the app from a push notification — the FCM payload already contains `roomId` and `callerNxId`:

```dart
// Request permissions first
await Permission.microphone.request();

// Pre-warm the connection as soon as the incoming call screen opens
await sdk.initialize(username: '+255788811191', name: 'John Doe');

// Accept using FCM payload data — bypasses waiting for signaling
await sdk.acceptFromNotification(
  username: '+255788811191',
  roomId: fcmData['room'],        // from FCM payload
  callerNxId: fcmData['caller'],  // from FCM payload (caller's phone/NX ID)
  callerName: fcmData['caller_name'],
  name: 'John Doe',
  audio: true,
  video: false,
);

// If signaling is delayed, notify SDK that remote accepted
sdk.notifyRemoteAccepted();
```

---

## Push Notification Routing

We **recommend using push notifications** to route call events to recipients. You can use **Nexacon's built-in push service** or **your own FCM setup** — both work seamlessly with the SDK.

### How It Works

1. **Caller** initiates a call via `sdk.startCall()`
2. **Your backend** sends an FCM push notification to the recipient with call details (`roomId`, `callerNxId`, `callerName`)
3. **Recipient's app** receives the FCM payload and uses `sdk.acceptFromNotification()` to accept instantly — no need to wait for NX signaling

### Outgoing Call (Caller Side)

The caller starts the call and your backend triggers the push notification:

```dart
// Caller initiates the call
await sdk.startCall(
  to: '+255788811192',
  username: '+255788811191',
  name: 'John Doe',
  audio: true,
  video: false,
  roomId: 'unique-room-id',  // optional — auto-generated if omitted
);

// Your backend should send an FCM to the recipient with:
// {
//   "room": "unique-room-id",
//   "caller": "+255788811191",
//   "caller_name": "John Doe",
//   "call_type": "voice"
// }
```

### Incoming Call (Recipient Side)

The recipient receives the FCM push and accepts the call:

```dart
// Recipient's app — triggered by FCM background handler
Future<void> onFCMReceived(Map<String, dynamic> fcmData) async {
  final sdk = NexaconSDK(
    apiKey: 'your_api_key',
    secretKey: 'your_secret_key',
  );

  // Set up callbacks
  sdk.onCallStateChanged = (state) {
    if (state == CallState.connected) {
      // Call connected — start duration timer
    }
  };
  sdk.onOtherUserJoined = () {
    // Caller joined — update UI
  };
  sdk.onOtherUserLeft = () => sdk.endCall();
  sdk.onCallEnded = (reason) {
    // Clean up, navigate away
  };

  // Pre-warm the connection
  await sdk.initialize(
    username: '+255788811192',
    name: 'Jane Doe',
  );

  // Accept directly from FCM payload — no waiting for signaling
  await sdk.acceptFromNotification(
    username: '+255788811192',
    roomId: fcmData['room'],
    callerNxId: fcmData['caller'],
    callerName: fcmData['caller_name'],
    name: 'Jane Doe',
    audio: true,
    video: false,
  );

  // If NX signaling is delayed, notify SDK that the caller already accepted
  sdk.notifyRemoteAccepted();
}
```

### Using Nexacon's Push Service

Nexacon provides a built-in push service that handles FCM delivery for you. Register the device first:

```dart
// Register device for push notifications (once, at app startup)
final client = sdk.client; // or NexaconClient directly
await client.devices.register(
  fcmToken: fcmToken,       // from FirebaseMessaging.getToken()
  platform: 'android',      // 'android' or 'ios'
  deviceId: deviceId,       // optional
);
```

When a call is initiated, Nexacon's backend automatically sends an FCM push to the registered device with the `room`, `caller`, and `caller_name` fields.

### Using Your Own FCM

If you prefer to manage your own FCM infrastructure:

1. Send the FCM from your backend when the caller initiates the call
2. Include `room`, `caller`, and `caller_name` in the FCM data payload
3. On the recipient side, pass those fields to `sdk.acceptFromNotification()`

```dart
// Your own FCM handler
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  final data = message.data;
  // data should contain: room, caller, caller_name
  onFCMReceived(data);
});
```

> **Tip**: Whether you use Nexacon's push or your own, the SDK's `acceptFromNotification()` works the same way — it uses the FCM payload to join the call room directly.

---

## Pre-warming

Pre-warm the NX connection before dialing for faster call setup. This is a production pattern from real apps:

```dart
// Pre-warm before the user taps call (e.g., when viewing a contact)
await sdk.initialize(username: '+255788811191', name: 'John Doe');

// Later, when the user taps call — reuses the pre-warmed connection
await sdk.startCall(
  to: '+255788811192',
  username: '+255788811191',
  audio: true,
  video: false,
);
```

For incoming calls, pre-warm as soon as the incoming call screen appears:

```dart
// Pre-warm on incoming call screen
await sdk.initialize(username: '+255788811191', name: 'John Doe');

// Then accept via signaling...
await sdk.acceptWhenReady(username: '+255788811191', audio: true, video: false);

// ...or accept from FCM payload
await sdk.acceptFromNotification(
  username: '+255788811191',
  roomId: channelName,
  callerNxId: callerPhone,
  audio: true,
  video: false,
);
```

---

## Advanced Usage

For full low-level control, use `NexaconClient` directly.

### Step 1: Initialize Client

```dart
import 'package:nexacon_calls/nexacon_calls.dart';

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
final nxid    = nxResponse['nxid'];

// IMPORTANT: Required to avoid 403 errors on subsequent API calls
client.setToken(nxtoken);
```

### Step 3: Create CallManager

```dart
final callManager = await client.createCallManager(
  nxtoken: nxtoken,
  nxid: nxid,
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

| Method                                                                                            | Description                                                    |
| ------------------------------------------------------------------------------------------------- | -------------------------------------------------------------- |
| `initialize({required username, name})`                                                           | Connect to signaling without dialing — use for incoming calls  |
| `startCall({required to, required username, name, audio, video})`                                 | Start outgoing call — handles everything internally            |
| `acceptWhenReady({required username, name, audio, video, timeout})`                               | Initialize and auto-accept when NX signal arrives (foreground) |
| `acceptFromNotification({required username, roomId, callerNxId, callerName, name, audio, video})` | Accept using FCM/push payload data (background)                |
| `acceptCall({audio, video})`                                                                      | Accept an incoming call (must be in `incoming` state)          |
| `rejectCall()`                                                                                    | Reject an incoming call                                        |
| `endCall()`                                                                                       | End the current call                                           |
| `notifyRemoteAccepted()`                                                                          | Notify SDK that remote accepted (FCM fallback)                 |
| `toggleMute(bool muted)`                                                                          | Toggle microphone                                              |
| `toggleSpeaker(bool enabled)`                                                                     | Toggle speaker                                                 |
| `toggleVideo(bool enabled)`                                                                       | Toggle video                                                   |
| `switchCamera()`                                                                                  | Switch front/back camera                                       |
| `dispose()`                                                                                       | Cleanup all resources                                          |

| Property       | Type             | Description                                        |
| -------------- | ---------------- | -------------------------------------------------- |
| `callDuration` | `Duration`       | Current call duration                              |
| `client`       | `NexaconClient?` | Underlying client for advanced use (devices, etc.) |

| Callback             | Signature             | Description                 |
| -------------------- | --------------------- | --------------------------- |
| `onCallStateChanged` | `Function(CallState)` | Call state updates          |
| `onIncomingCall`     | `Function(String)`    | Incoming call received      |
| `onCallEnded`        | `Function(String)`    | Call ended with reason      |
| `onError`            | `Function(String)`    | Error occurred              |
| `onLocalStream`      | `Function()`          | Local video stream ready    |
| `onRemoteStream`     | `Function()`          | Remote video stream ready   |
| `onOtherUserJoined`  | `Function()`          | Remote peer joined the call |
| `onOtherUserLeft`    | `Function()`          | Remote peer left the call   |

---

### NexaconClient _(Advanced)_

```dart
NexaconClient({required String apiKey, required String secretKey, String? baseUrl})
```

| Method                                 | Description                   |
| -------------------------------------- | ----------------------------- |
| `auth.getNxToken({required username})` | Generate NX token             |
| `setToken(String token)`               | Set NX token for API auth     |
| `createCallManager({...})`             | Create a CallManager instance |
| `close()`                              | Close the client              |

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

> **ℹ️ Real-Time Messaging**: For chat messaging (text messages, typing indicators, read receipts, presence, message history), use the separate [Nexacon Messaging SDK](https://nexacon-messaging.readthedocs.io/).

---

## Troubleshooting

### 403 Error on Call Initiation

**Cause**: NX token not set on the client.

**Fix** (Advanced API only — `NexaconSDK` handles this automatically):

```dart
client.setToken(nxtoken); // Must be called after getNxToken()
```

### NX Connection Timeout

**Cause**: WebSocket URL uses `https://` instead of `wss://`.

**Fix**: `NexaconSDK` converts this automatically. If using `NexaconClient` directly, ensure `wsUrl` starts with `wss://`.

### Camera / Microphone Not Working

- **Android**: Ensure permissions are in `AndroidManifest.xml` and granted at runtime
- **iOS**: Ensure keys are in `Info.plist`
- **Web**: App must be served over HTTPS (WebRTC requirement)

### Call Stuck in "Calling"

- Ensure the callee is online with the SDK initialized
- Calls time out after **60 seconds** if not accepted

### Second Call Auto-Ends After Acceptance

**Cause (pre-1.3.4)**: When the NX connection is re-established for a second call, the server replays queued messages from the previous session — including the old `call_end` signal. Two bugs compounded this:

1. The `CallManager` NX subscription was never cancelled on call end — an orphaned subscription could process stale signals after internal state was reset to `idle`.
2. There was no room ID validation — any `call_end` was processed unconditionally.

**Fixed in v1.3.4**:

- The `StreamSubscription` is now stored and immediately cancelled in `_endCall()`, making the old `CallManager` permanently deaf after a call ends.
- Every non-invitation signal is validated against `_currentRoomId` — mismatched room IDs are silently dropped.
- `NexaconSDK.endCall()` nulls the internal `_callManager` so the next call always gets a completely fresh instance.

**Required app-side guard** (still needed even with 1.3.4):

```dart
onOtherUserLeft: () {
  // Only end call if the WebRTC peer actually joined.
  // Guards against any residual state on the app layer.
  if (!_isOtherUserConnected) return;
  _endCall();
},
```

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
