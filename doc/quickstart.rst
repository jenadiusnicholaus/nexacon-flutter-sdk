Quick Start Guide
================

This guide walks you through setting up the Nexacon Flutter SDK and accessing its services.

Step 1: Initialize the Client
------------------------------

Create a ``NexaconClient`` instance with your API credentials:

.. code-block:: dart

    import 'package:nexacon_sdk/nexacon_sdk.dart';

    final client = NexaconClient(
      apiKey: 'your_api_key',
      secretKey: 'your_secret_key',
      baseUrl: 'https://nxservice.quantumvision-tech.com/api/v1.0',
    );

Step 2: Access a Service
------------------------

All services are accessible directly from the client:

.. code-block:: dart

    client.messaging   // Send messages, manage contacts
    client.calls       // Initiate and manage calls
    client.devices     // Register devices for push notifications
    client.rooms       // Manage group chat rooms
    client.presence    // Check user online status
    client.auth        // Generate NX tokens

Step 3: Choose Your Service
---------------------------

Use the menu on the left to navigate to the service you need:

+----------------------------+----------------------------------------------+
| Service                    | What it does                                 |
+============================+==============================================+
| :doc:`messaging`           | Send messages and manage contacts            |
+----------------------------+----------------------------------------------+
| :doc:`calls`               | 1:1 calls, group calls, P2P WebRTC calls     |
+----------------------------+----------------------------------------------+
| :doc:`devices`             | Register devices for FCM push notifications  |
+----------------------------+----------------------------------------------+
| :doc:`rooms`               | Create and manage group chat rooms           |
+----------------------------+----------------------------------------------+
| :doc:`presence`            | Check user online status and last seen       |
+----------------------------+----------------------------------------------+

Each service page contains full method signatures, parameters, return values, and code examples.
