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

Verify Installation
------------------

To verify the installation, import the package in your Dart file:

.. code-block:: dart

    import 'package:nexacon_sdk/nexacon_sdk.dart';

If there are no import errors, the SDK is installed correctly.

Next Steps
----------

After installation, proceed to the `Quick Start Guide <quickstart.html>`_ to learn how to initialize and use the SDK.
