# API Reference

## NexaconClient

The main client for interacting with the Nexacon API.

### Initialization

.. code-block:: dart

    final client = NexaconClient(
      apiKey: 'your_api_key',
      secretKey: 'your_secret_key',
      baseUrl: 'https://nxservice.quantumvision-tech.com/api/v1.0',
    );

### Methods

#### createCallManager

Creates a CallManager instance for P2P calling.

.. code-block:: dart

    final callManager = await client.createCallManager(
      nxtoken: 'nx_token',
      nxid: 'nx_id',
      wsUrl: 'wss://nxservice.quantumvision-tech.com/nx-websocket/',
      name: 'Your Name',
      onCallStateChanged: (state) {},
      onIncomingCall: (callerName) {},
      onCallEnded: (reason) {},
      onError: (error) {},
    );

## CallManager

Manages P2P calls with automatic NX signaling and WebRTC peer connection.

### Methods

#### initiateCall

Initiates an outgoing P2P call.

.. code-block:: dart

    await callManager.initiateCall(
      to: '+255788811192',
      audio: true,
      video: false,
    );

#### acceptCall

Accepts an incoming call.

.. code-block:: dart

    await callManager.acceptCall(
      audio: true,
      video: false,
    );

#### rejectCall

Rejects an incoming call.

.. code-block:: dart

    callManager.rejectCall();

#### endCall

Ends the current call.

.. code-block:: dart

    await callManager.endCall();

#### dispose

Cleans up resources.

.. code-block:: dart

    callManager.dispose();

### Properties

#### callState

Current call state (idle, calling, incoming, connected, ended).

.. code-block:: dart

    final state = callManager.callState;

#### webrtcService

WebRTC service instance for call controls.

.. code-block:: dart

    callManager.webrtcService?.toggleAudio(false);
    callManager.webrtcService?.toggleSpeaker(true);
    callManager.webrtcService?.switchCamera();

## Auth

NX token management for signaling.

### Methods

#### generateXMPPToken

Generates an NX token for signaling.

.. code-block:: dart

    final response = await client.auth.generateXMPPToken(
      username: '+255788811191',
    );
    final nxtoken = response['token'];
    final nxid = response['jid'];
    final wsUrl = response['nxws'];

#### refreshXMPPToken

Refreshes an NX token.

.. code-block:: dart

    final response = await client.auth.refreshXMPPToken(
      refreshToken: 'refresh_token',
    );

## Call States

- ``idle`` - No active call
- ``calling`` - Outgoing call in progress
- ``incoming`` - Incoming call received
- ``connected`` - Call established
- ``ended`` - Call ended
