API Reference
=============

This section provides detailed documentation for all classes and methods in the Nexacon Flutter SDK.

NexaconClient
------------

The main client for interacting with the Nexacon API.

.. code-block:: dart

    final client = NexaconClient(
      apiKey: String,
      secretKey: String,
      baseUrl: String,
    );

Parameters
~~~~~~~~~~

* **apiKey** (String): Your Nexacon API key
* **secretKey** (String): Your Nexacon secret key
* **baseUrl** (String): Base URL for the Nexacon API

Methods
~~~~~~~

createCallManager
^^^^^^^^^^^^^^^^^

Creates a CallManager instance for P2P calling.

.. code-block:: dart

    Future<CallManager> createCallManager({
      String? nxtoken,
      String? nxid,
      String? wsUrl,
      String? name,
      Function(CallState)? onCallStateChanged,
      Function(String)? onIncomingCall,
      Function(String)? onCallEnded,
      Function(String)? onError,
    })

Parameters
^^^^^^^^^^

* **nxtoken** (String?): NX token for signaling
* **nxid** (String?): NX identifier
* **wsUrl** (String?): WebSocket URL for NX connection
* **name** (String?): Display name for the user
* **onCallStateChanged** (Function?): Callback for call state changes
* **onIncomingCall** (Function?): Callback for incoming calls
* **onCallEnded** (Function?): Callback for call ended events
* **onError** (Function?): Callback for error events

Returns
^^^^^^^

``Future<CallManager>``: A CallManager instance

CallManager
-----------

Manages P2P calls with automatic NX signaling and WebRTC peer connection.

Properties
~~~~~~~~~~

callState
^^^^^^^^^

Current call state.

.. code-block:: dart

    CallState get callState

Possible values: ``idle``, ``calling``, ``incoming``, ``connected``, ``ended``

webrtcService
^^^^^^^^^^^^^

WebRTC service instance for call controls.

.. code-block:: dart

    WebRTCService? get webrtcService

Methods
~~~~~~~

initiateCall
^^^^^^^^^^^^

Initiates an outgoing P2P call.

.. code-block:: dart

    Future<void> initiateCall({
      required String to,
      bool audio = true,
      bool video = true,
    })

Parameters
^^^^^^^^^^

* **to** (String): Recipient's phone number or identifier
* **audio** (bool): Enable audio (default: true)
* **video** (bool): Enable video (default: true)

acceptCall
^^^^^^^^^^

Accepts an incoming call.

.. code-block:: dart

    Future<void> acceptCall({
      bool audio = true,
      bool video = true,
    })

Parameters
^^^^^^^^^^

* **audio** (bool): Enable audio (default: true)
* **video** (bool): Enable video (default: true)

rejectCall
^^^^^^^^^^

Rejects an incoming call.

.. code-block:: dart

    void rejectCall()

endCall
^^^^^^^

Ends the current call.

.. code-block:: dart

    Future<void> endCall()

dispose
^^^^^^^

Cleans up resources.

.. code-block:: dart

    void dispose()

Auth
----

NX token management for signaling.

Methods
~~~~~~~

getNxToken
^^^^^^^^^^^

Gets an NX token for signaling.

.. code-block:: dart

    Future<Map<String, dynamic>> getNxToken({
      required String username,
      String host = 'nxservice.quantumvision-tech.com',
    })

Parameters
^^^^^^^^^^

* **username** (String): User's phone number or identifier
* **host** (String): XMPP host (default: 'nxservice.quantumvision-tech.com')

Returns
^^^^^^^

``Future<Map<String, dynamic>>``: Response containing token, jid, and wsUrl

refreshXMPPToken
^^^^^^^^^^^^^^^^

Refreshes an NX token.

.. code-block:: dart

    Future<Map<String, dynamic>> refreshXMPPToken({
      required String refreshToken,
    })

Parameters
^^^^^^^^^^

* **refreshToken** (String): Refresh token

Returns
^^^^^^^

``Future<Map<String, dynamic>>``: Response containing new token

WebRTCService
-------------

WebRTC service for call controls (accessed via CallManager.webrtcService).

Methods
~~~~~~~

toggleAudio
^^^^^^^^^^^

Toggle audio track.

.. code-block:: dart

    void toggleAudio(bool enabled)

toggleVideo
^^^^^^^^^^^

Toggle video track.

.. code-block:: dart

    void toggleVideo(bool enabled)

toggleSpeaker
^^^^^^^^^^^^^

Toggle speakerphone.

.. code-block:: dart

    Future<void> toggleSpeaker(bool enabled)

switchCamera
^^^^^^^^^^^

Switch between front and back camera.

.. code-block:: dart

    Future<void> switchCamera()

Call States
-----------

The following states represent the lifecycle of a call:

.. list-table::
   :widths: 25 75
   :header-rows: 1

   * - State
     - Description
   * - ``idle``
     - No active call
   * - ``calling``
     - Outgoing call in progress
   * - ``incoming``
     - Incoming call received
   * - ``connected``
     - Call established
   * - ``ended``
     - Call ended
