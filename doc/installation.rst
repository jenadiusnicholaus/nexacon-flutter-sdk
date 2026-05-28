Installation
============

This guide covers installing the Nexacon Flutter SDK in your Flutter project.

Requirements
------------

* Flutter SDK 3.0.0 or higher
* Dart 3.0.0 or higher
* Android SDK 21+ (for Android)
* iOS 12.0+ (for iOS)

Add Dependency
-------------

Add the Nexacon Flutter SDK to your ``pubspec.yaml`` file:

.. code-block:: yaml

    dependencies:
      flutter:
        sdk: flutter
      nexacon_sdk: ^1.0.0

Install the package:

.. code-block:: bash

    flutter pub get

Platform Configuration
----------------------

Android
~~~~~~~

Add permissions to ``android/app/src/main/AndroidManifest.xml``:

.. code-block:: xml

    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    <uses-permission android:name="android.permission.BLUETOOTH"/>
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>

Set minimum SDK version in ``android/app/build.gradle``:

.. code-block:: gradle

    android {
        defaultConfig {
            minSdkVersion 21
        }
    }

iOS
~~~

Add permissions to ``ios/Runner/Info.plist``:

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

Set minimum iOS version in ``ios/Podfile``:

.. code-block:: ruby

    platform :ios, '12.0'

Verify Installation
------------------

To verify the installation, import the package in your Dart file:

.. code-block:: dart

    import 'package:nexacon_sdk/nexacon_sdk.dart';

If there are no import errors, the SDK is installed correctly.

Next Steps
----------

After installation, proceed to the `Quick Start Guide <quickstart.html>`_ to learn how to initialize and use the SDK.
