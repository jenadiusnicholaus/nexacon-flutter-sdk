# Nexacon Flutter SDK Documentation

Welcome to the Nexacon Flutter SDK documentation.

## Quick Start

```dart
import 'package:nexacon_sdk/nexacon_sdk.dart';

// Initialize client
final client = NexaconClient(
  apiKey: 'your_api_key',
  secretKey: 'your_secret_key',
  baseUrl: 'https://nxservice.quantumvision-tech.com/api/v1.0',
);

// Generate NX token for signaling
final nxResponse = await client.auth.generateXMPPToken(
  username: '+255788811191',
);
final nxtoken = nxResponse['token'];
final nxid = nxResponse['jid'];
final wsUrl = nxResponse['nxws'];

// Create CallManager
final callManager = await client.createCallManager(
  nxtoken: nxtoken,
  nxid: nxid,
  wsUrl: wsUrl,
  name: 'Your Name',
);

// Initiate call
await callManager.initiateCall(
  to: '+255788811192',
  audio: true,
  video: false,
);
```

## Installation

Add to `pubspec.yaml`:

.. code-block:: yaml

    dependencies:
      nexacon_sdk: ^1.0.0

Then run:

.. code-block:: bash

    flutter pub get

## Platform Configuration

### Android

Add permissions to `android/app/src/main/AndroidManifest.xml`:

.. code-block:: xml

    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    <uses-permission android:name="android.permission.BLUETOOTH"/>
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>

Set minimum SDK version in `android/app/build.gradle`:

.. code-block:: gradle

    android {
        defaultConfig {
            minSdkVersion 21
        }
    }

### iOS

Add permissions to `ios/Runner/Info.plist`:

.. code-block:: xml

    <key>NSCameraUsageDescription</key>
    <string>Camera access is required for video calls</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>Microphone access is required for audio calls</string>
    <key>UIBackgroundModes</key>
    <array>
      <string>audio</string>
      <string>voip</string>
    </array>

Set minimum iOS version in `ios/Podfile`:

.. code-block:: ruby

    platform :ios, '12.0'

## API Reference

.. toctree::
   :maxdepth: 2
   :caption: Contents:

   api
