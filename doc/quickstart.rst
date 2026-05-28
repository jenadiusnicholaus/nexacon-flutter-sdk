Quick Start Guide
================

Get up and running with the Nexacon Flutter SDK in minutes.

----

1. Initialize the Client
------------------------

.. code-block:: dart

    import 'package:nexacon_sdk/nexacon_sdk.dart';

    final client = NexaconClient(
      apiKey: 'your_api_key',
      secretKey: 'your_secret_key',
      baseUrl: 'https://nxservice.quantumvision-tech.com/api/v1.0',
    );

----

2. Available Services
---------------------

Once the client is initialized, all services are available via:

.. code-block:: dart

    client.auth        // Generate NX tokens for signaling
    client.calls       // P2P calls, group calls, WebRTC
    client.messaging   // Send messages, manage contacts
    client.devices     // Register devices for push notifications
    client.rooms       // Create and manage group chat rooms
    client.presence    // Check user online status

----

3. Next Steps
-------------

Click on a service in the **Services** menu on the left for full documentation, method signatures, parameters, and code examples.

+---------------------------+-----------------------------------------------+
| Service                   | What it does                                  |
+===========================+===============================================+
| :doc:`calls`              | P2P calling, group calls, WebRTC — start here |
+---------------------------+-----------------------------------------------+
| :doc:`messaging`          | Send messages and manage contacts             |
+---------------------------+-----------------------------------------------+
| :doc:`devices`            | Register devices for FCM push notifications   |
+---------------------------+-----------------------------------------------+
| :doc:`rooms`              | Create and manage group chat rooms            |
+---------------------------+-----------------------------------------------+
| :doc:`presence`           | Check user online status and last seen        |
+---------------------------+-----------------------------------------------+
