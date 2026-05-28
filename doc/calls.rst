Calls Service
=============

The Calls service provides functionality for initiating and managing calls through the Nexacon API.

.. code-block:: dart

    final calls = client.calls;

Call Types
~~~~~~~~~~

The service supports the following call types:

* ``audio`` - Audio-only calls
* ``video`` - Video calls
* ``p2p`` - Peer-to-peer WebRTC calls

Methods
~~~~~~~

initiateCall
^^^^^^^^^^^^

Initiate a 1:1 call.

.. code-block:: dart

    Future<Map<String, dynamic>> initiateCall({
      required String to,
      CallType callType = CallType.video,
      String? room,
    })

Parameters
^^^^^^^^^^

* **to** (String): Recipient's phone number or identifier
* **callType** (CallType): Type of call (audio, video, p2p)
* **room** (String?): Optional room identifier

Returns
^^^^^^^

``Future<Map<String, dynamic>>``: Response from the server

initiateGroupCall
^^^^^^^^^^^^^^^^^

Initiate a group call with multiple participants.

.. code-block:: dart

    Future<Map<String, dynamic>> initiateGroupCall({
      required List<String> participants,
      CallType callType = CallType.video,
      String? room,
    })

Parameters
^^^^^^^^^^

* **participants** (List<String>): List of participant identifiers
* **callType** (CallType): Type of call (audio, video, p2p)
* **room** (String?): Optional room identifier

Returns
^^^^^^^

``Future<Map<String, dynamic>>``: Response from the server

getCallUrl
^^^^^^^^^^

Get a pre-signed call URL for mobile apps.

.. code-block:: dart

    Future<String> getCallUrl({
      required String to,
      CallType callType = CallType.video,
      String? room,
    })

Parameters
^^^^^^^^^^

* **to** (String): Recipient's phone number or identifier
* **callType** (CallType): Type of call (audio, video, p2p)
* **room** (String?): Optional room identifier

Returns
^^^^^^^

``Future<String>``: Pre-signed call URL

declineCall
^^^^^^^^^^

Decline an incoming call.

.. code-block:: dart

    Future<Map<String, dynamic>> declineCall(String room)

Parameters
^^^^^^^^^^

* **room** (String): Room identifier for the call

Returns
^^^^^^^

``Future<Map<String, dynamic>>``: Response from the server

getWebRTCCredentials
^^^^^^^^^^^^^^^^^^^^

Get TURN/STUN credentials for WebRTC P2P calls. Credentials are time-limited (24h TTL). Fetch fresh credentials before each call.

.. code-block:: dart

    Future<Map<String, dynamic>> getWebRTCCredentials()

Returns
^^^^^^^

``Future<Map<String, dynamic>>``: TURN/STUN credentials

initiateP2PCall
^^^^^^^^^^^^^^

Initiate a P2P WebRTC call (sends FCM push + XMPP notification).

.. code-block:: dart

    Future<Map<String, dynamic>> initiateP2PCall({
      required String to,
      String? room,
    })

Parameters
^^^^^^^^^^

* **to** (String): Recipient's phone number or identifier
* **room** (String?): Optional room identifier

Returns
^^^^^^^

``Future<Map<String, dynamic>>``: Response from the server
