Calls Service
=============

The ``Calls`` service handles all call operations — 1:1 audio/video calls, group calls, and peer-to-peer WebRTC calls.

.. code-block:: dart

    // Access via client
    final calls = client.calls;

----

Call Types
----------

.. list-table::
   :widths: 20 80
   :header-rows: 1

   * - Type
     - Description
   * - ``CallType.audio``
     - Audio-only call
   * - ``CallType.video``
     - Audio and video call
   * - ``CallType.p2p``
     - Peer-to-peer WebRTC call (direct, low latency)

----

Methods
-------

initiateCall
~~~~~~~~~~~~

Start a 1:1 call with a single user.

**Signature**

.. code-block:: dart

    Future<Map<String, dynamic>> initiateCall({
      required String to,
      CallType callType = CallType.video,
      String? room,
    })

**Parameters**

.. list-table::
   :widths: 20 15 65
   :header-rows: 1

   * - Parameter
     - Type
     - Description
   * - ``to``
     - String
     - Recipient's phone number or NX identifier
   * - ``callType``
     - CallType
     - Type of call: ``audio``, ``video`` (default), or ``p2p``
   * - ``room``
     - String?
     - Optional custom room identifier

**Example**

.. code-block:: dart

    await client.calls.initiateCall(
      to: '+255788811192',
      callType: CallType.video,
    );

----

initiateGroupCall
~~~~~~~~~~~~~~~~~

Start a call with multiple participants.

**Signature**

.. code-block:: dart

    Future<Map<String, dynamic>> initiateGroupCall({
      required List<String> participants,
      CallType callType = CallType.video,
      String? room,
    })

**Parameters**

.. list-table::
   :widths: 20 15 65
   :header-rows: 1

   * - Parameter
     - Type
     - Description
   * - ``participants``
     - List<String>
     - List of recipient phone numbers or NX identifiers
   * - ``callType``
     - CallType
     - Type of call: ``audio``, ``video`` (default), or ``p2p``
   * - ``room``
     - String?
     - Optional custom room identifier

**Example**

.. code-block:: dart

    await client.calls.initiateGroupCall(
      participants: ['+255788811192', '+255788811193'],
      callType: CallType.audio,
    );

----

initiateP2PCall
~~~~~~~~~~~~~~~

Start a direct peer-to-peer WebRTC call. This sends both an FCM push notification and an NX signaling message to the recipient.

**Signature**

.. code-block:: dart

    Future<Map<String, dynamic>> initiateP2PCall({
      required String to,
      String? room,
    })

**Parameters**

.. list-table::
   :widths: 20 15 65
   :header-rows: 1

   * - Parameter
     - Type
     - Description
   * - ``to``
     - String
     - Recipient's phone number or NX identifier
   * - ``room``
     - String?
     - Optional custom room identifier

**Example**

.. code-block:: dart

    await client.calls.initiateP2PCall(
      to: '+255788811192',
    );

----

declineCall
~~~~~~~~~~~

Decline an incoming call.

**Signature**

.. code-block:: dart

    Future<Map<String, dynamic>> declineCall(String room)

**Parameters**

.. list-table::
   :widths: 20 15 65
   :header-rows: 1

   * - Parameter
     - Type
     - Description
   * - ``room``
     - String
     - The room identifier of the incoming call

**Example**

.. code-block:: dart

    await client.calls.declineCall(roomId);

----

getCallUrl
~~~~~~~~~~

Generate a pre-signed call URL for use in mobile apps or web clients.

**Signature**

.. code-block:: dart

    Future<String> getCallUrl({
      required String to,
      CallType callType = CallType.video,
      String? room,
    })

**Parameters**

.. list-table::
   :widths: 20 15 65
   :header-rows: 1

   * - Parameter
     - Type
     - Description
   * - ``to``
     - String
     - Recipient's phone number or NX identifier
   * - ``callType``
     - CallType
     - Type of call: ``audio``, ``video`` (default), or ``p2p``
   * - ``room``
     - String?
     - Optional custom room identifier

**Example**

.. code-block:: dart

    final url = await client.calls.getCallUrl(
      to: '+255788811192',
      callType: CallType.video,
    );
    // Open url in browser or deep link

----

getWebRTCCredentials
~~~~~~~~~~~~~~~~~~~~

Fetch TURN/STUN server credentials required for WebRTC P2P calls.

.. note::
   Credentials have a **24-hour TTL**. Always fetch fresh credentials immediately before starting a call.

**Signature**

.. code-block:: dart

    Future<Map<String, dynamic>> getWebRTCCredentials()

**Returns**

A map containing ``iceServers``, ``username``, and ``password`` for use with the WebRTC peer connection.

**Example**

.. code-block:: dart

    final credentials = await client.calls.getWebRTCCredentials();
    final iceServers = credentials['iceServers'];
