Platform Configuration
=====================

This guide covers the platform-specific configuration required for the Nexacon Flutter SDK.

Android Configuration
--------------------

Permissions
~~~~~~~~~~~

Add the following permissions to ``android/app/src/main/AndroidManifest.xml``:

.. code-block:: xml

    <manifest>
        <uses-permission android:name="android.permission.INTERNET"/>
        <uses-permission android:name="android.permission.RECORD_AUDIO"/>
        <uses-permission android:name="android.permission.CAMERA"/>
        <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
        <uses-permission android:name="android.permission.WAKE_LOCK"/>
        <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
        <uses-permission android:name="android.permission.BLUETOOTH"/>
        <uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
    </manifest>

Minimum SDK Version
~~~~~~~~~~~~~~~~~~~

Set the minimum SDK version in ``android/app/build.gradle``:

.. code-block:: gradle

    android {
        defaultConfig {
            minSdkVersion 21
        }
    }

iOS Configuration
----------------

Permissions
~~~~~~~~~~~

Add the following permissions to ``ios/Runner/Info.plist``:

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

Minimum iOS Version
~~~~~~~~~~~~~~~~~~~

Set the minimum iOS version in ``ios/Podfile``:

.. code-block:: ruby

    platform :ios, '12.0'

Web Configuration
----------------

The SDK works on web browsers that support WebRTC. No additional configuration is required for web platforms.

Desktop Configuration
---------------------

The SDK supports desktop platforms (Windows, macOS, Linux). Ensure your application has the necessary permissions to access camera and microphone devices.

Next Steps
----------

After configuring your platform, proceed to the `API Reference <api.html>`_ to learn about available methods and classes.
