Quick Start Guide
================

This guide will help you get started with the Nexacon Flutter SDK in just a few minutes.

Step 1: Initialize the Client
-----------------------------

Create a ``NexaconClient`` instance with your API credentials:

.. code-block:: dart

    import 'package:nexacon_sdk/nexacon_sdk.dart';

    final client = NexaconClient(
      apiKey: 'your_api_key',
      secretKey: 'your_secret_key',
      baseUrl: 'https://nxservice.quantumvision-tech.com/api/v1.0',
    );

Step 2: Generate NX Token
-------------------------

Generate an NX token for signaling:

.. code-block:: dart

    final nxResponse = await client.auth.generateXMPPToken(
      username: '+255788811191',
    );
    final nxtoken = nxResponse['token'];
    final nxid = nxResponse['jid'];
    final wsUrl = nxResponse['nxws'];

Step 3: Create CallManager
---------------------------

Initialize the ``CallManager`` with your NX credentials:

.. code-block:: dart

    final callManager = await client.createCallManager(
      nxtoken: nxtoken,
      nxid: nxid,
      wsUrl: wsUrl,
      name: 'Your Name',
      onCallStateChanged: (state) {
        // Handle call state changes
        print('Call state: $state');
      },
      onIncomingCall: (callerName) {
        // Show incoming call UI
        print('Incoming call from: $callerName');
      },
      onCallEnded: (reason) {
        // Handle call ended
        print('Call ended: $reason');
      },
      onError: (error) {
        // Handle errors
        print('Error: $error');
      },
    );

Step 4: Make a Call
------------------

Initiate an outgoing call:

.. code-block:: dart

    await callManager.initiateCall(
      to: '+255788811192',
      audio: true,
      video: false,
    );

Accept an incoming call:

.. code-block:: dart

    await callManager.acceptCall(
      audio: true,
      video: false,
    );

Step 5: Call Controls
--------------------

Control call features:

.. code-block:: dart

    // Mute/Unmute
    callManager.webrtcService?.toggleAudio(false);

    // Speaker toggle
    callManager.webrtcService?.toggleSpeaker(true);

    // Switch camera
    await callManager.webrtcService?.switchCamera();

Step 6: End Call
---------------

End the current call:

.. code-block:: dart

    await callManager.endCall();

Step 7: Cleanup
--------------

Dispose resources when done:

.. code-block:: dart

    callManager.dispose();

Next Steps
----------

* Learn about `Platform Configuration <platform-config.html>`_
* Explore the `API Reference <api.html>`_
