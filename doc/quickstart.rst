Quick Start Guide
================

This guide provides a quick overview of the Nexacon Flutter SDK and how to get started with its services.

Initialize the Client
--------------------

Create a ``NexaconClient`` instance with your API credentials:

.. code-block:: dart

    import 'package:nexacon_sdk/nexacon_sdk.dart';

    final client = NexaconClient(
      apiKey: 'your_api_key',
      secretKey: 'your_secret_key',
      baseUrl: 'https://nxservice.quantumvision-tech.com/api/v1.0',
    );

Available Services
------------------

The SDK provides the following services:

* `Messaging Service <messaging.html>`_ - Send and receive messages, manage contacts
* `Calls Service <calls.html>`_ - Initiate and manage 1:1 and group calls, P2P calling
* `Devices Service <devices.html>`_ - Register and manage devices for push notifications
* `Rooms Service <rooms.html>`_ - Create and manage group chat rooms
* `Presence Service <presence.html>`_ - Check user online status and last seen

Quick Examples
--------------

**Send a Message:**

.. code-block:: dart

    await client.messaging.send(
      message: 'Hello!',
      recipients: ['+255788811192'],
    );

**Initiate a 1:1 Call:**

.. code-block:: dart

    await client.calls.initiateCall(
      to: '+255788811192',
      callType: CallType.video,
    );

**Initiate a P2P Call:**

.. code-block:: dart

    await client.calls.initiateP2PCall(
      to: '+255788811192',
    );

**Initiate a Group Call:**

.. code-block:: dart

    await client.calls.initiateGroupCall(
      participants: ['+255788811192', '+255788811193'],
      callType: CallType.audio,
    );

**Decline a Call:**

.. code-block:: dart

    await client.calls.declineCall(room);

**Get WebRTC Credentials:**

.. code-block:: dart

    final credentials = await client.calls.getWebRTCCredentials();

For more details, see the full `Calls Service documentation <calls.html>`_.

**Register a Device:**

.. code-block:: dart

    await client.devices.register(
      fcmToken: 'your_fcm_token',
      platform: Platform.android,
    );

Next Steps
----------

* Explore individual `Services <#available-services>`_ for detailed documentation
* Check the `API Reference <api.html>`_ for complete API documentation
