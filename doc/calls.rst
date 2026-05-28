Calls Service
=============

The ``Calls`` service handles all call operations — 1:1 audio/video calls, group calls, and full peer-to-peer WebRTC calls with the ``CallManager``.

.. code-block:: dart

    // Access via client
    final calls = client.calls;

----

P2P Calling with CallManager
-----------------------------

For full peer-to-peer calling (audio/video), use the built-in ``CallManager``. It handles NX signaling, WebRTC peer connections, ICE negotiation, and call lifecycle automatically.

**Step 1: Generate NX Token**

.. code-block:: dart

    final nxResponse = await client.auth.generateXMPPToken(
      username: '+255788811191',
    );
    final nxtoken = nxResponse['token'];
    final nxid = nxResponse['jid'];
    final wsUrl = nxResponse['nxws'];

**Step 2: Create CallManager**

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

**Step 3: Make a Call**

.. code-block:: dart

    // Outgoing call
    await callManager.initiateCall(
      to: '+255788811192',
      audio: true,
      video: false,
    );

    // Accept incoming call
    await callManager.acceptCall(
      audio: true,
      video: false,
    );

    // Reject incoming call
    await callManager.rejectCall();

    // End call
    await callManager.endCall();

**Step 4: Call Controls**

.. code-block:: dart

    // Mute / Unmute
    callManager.webrtcService?.toggleAudio(false);

    // Speaker toggle
    callManager.webrtcService?.toggleSpeaker(true);

    // Switch front/back camera
    await callManager.webrtcService?.switchCamera();

**Step 5: Cleanup**

.. code-block:: dart

    callManager.dispose();

----

Call States
-----------

.. list-table::
   :widths: 25 75
   :header-rows: 1

   * - State
     - Description
   * - ``CallState.idle``
     - No active call
   * - ``CallState.calling``
     - Outgoing call in progress
   * - ``CallState.incoming``
     - Incoming call received
   * - ``CallState.connected``
     - Call established and connected
   * - ``CallState.ended``
     - Call has ended

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

----

recordCall
~~~~~~~~~~

Record a call event for analytics. Call this after every call ends, fails, is declined, or is missed to track call history.

**Signature**

.. code-block:: dart

    Future<Map<String, dynamic>> recordCall({
      required String room,
      required CallType callType,
      required CallAnalyticsStatus status,
      int durationSeconds = 0,
      Map<String, dynamic>? metadata,
    })

**Parameters**

.. list-table::
   :widths: 22 18 60
   :header-rows: 1

   * - Parameter
     - Type
     - Description
   * - ``room``
     - String
     - The room identifier of the call
   * - ``callType``
     - CallType
     - Type of call: ``audio``, ``video``, or ``p2p``
   * - ``status``
     - CallAnalyticsStatus
     - Outcome: ``ended``, ``failed``, ``declined``, or ``missed``
   * - ``durationSeconds``
     - int
     - Duration of the call in seconds (0 for failed/declined/missed)
   * - ``metadata``
     - Map<String, dynamic>?
     - Optional extra data (e.g. who ended the call, error message)

**Analytics Status Values**

.. list-table::
   :widths: 20 80
   :header-rows: 1

   * - Status
     - Description
   * - ``CallAnalyticsStatus.ended``
     - Call completed successfully
   * - ``CallAnalyticsStatus.failed``
     - Call failed (e.g. ICE connection error)
   * - ``CallAnalyticsStatus.declined``
     - Recipient declined the call
   * - ``CallAnalyticsStatus.missed``
     - Recipient did not answer

**Examples**

Record a completed call:

.. code-block:: dart

    await client.calls.recordCall(
      room: 'room_abc123',
      callType: CallType.video,
      status: CallAnalyticsStatus.ended,
      durationSeconds: 120,
      metadata: {'ended_by': 'caller', 'is_group': false},
    );

Record a failed call:

.. code-block:: dart

    await client.calls.recordCall(
      room: 'room_xyz789',
      callType: CallType.audio,
      status: CallAnalyticsStatus.failed,
      durationSeconds: 0,
      metadata: {'error': 'ICE connection failed'},
    );

Record a declined call:

.. code-block:: dart

    await client.calls.recordCall(
      room: 'room_declined123',
      callType: CallType.video,
      status: CallAnalyticsStatus.declined,
    );

**Usage with CallManager**

Hook into the ``onCallEnded`` and ``onError`` callbacks to record automatically:

.. code-block:: dart

    final callManager = await client.createCallManager(
      // ...
      onCallEnded: (reason) async {
        await client.calls.recordCall(
          room: currentRoomId,
          callType: CallType.video,
          status: CallAnalyticsStatus.ended,
          durationSeconds: callManager.callDuration?.inSeconds ?? 0,
          metadata: {'ended_by': reason},
        );
      },
      onError: (error) async {
        await client.calls.recordCall(
          room: currentRoomId,
          callType: CallType.video,
          status: CallAnalyticsStatus.failed,
          metadata: {'error': error},
        );
      },
    );
