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
   * - ``CallType.group``
     - Group call with multiple participants

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
   :widths: 25 75
   :header-rows: 1

   * - Status
     - Description
   * - ``CallAnalyticsStatus.initiated``
     - Call was initiated by the caller
   * - ``CallAnalyticsStatus.calling``
     - Ringing, waiting for recipient to answer
   * - ``CallAnalyticsStatus.answered``
     - Recipient answered the call
   * - ``CallAnalyticsStatus.declined``
     - Recipient declined the call
   * - ``CallAnalyticsStatus.cancelled``
     - Caller cancelled before answer
   * - ``CallAnalyticsStatus.missed``
     - Recipient did not answer
   * - ``CallAnalyticsStatus.ended``
     - Call completed successfully
   * - ``CallAnalyticsStatus.failed``
     - Call failed (e.g. ICE connection error)

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

.. note::
   CallManager automatically records call analytics on every call end. You don't need to manually call ``recordCall`` when using CallManager.

----

getCallHistory
~~~~~~~~~~~~~

Fetch call history for the current user with optional filters.

**Signature**

.. code-block:: dart

    Future<Map<String, dynamic>> getCallHistory({
      DateTime? startDate,
      DateTime? endDate,
      CallType? callType,
      CallAnalyticsStatus? status,
      String? participant,
      int page = 1,
      int pageSize = 20,
    })

**Parameters**

.. list-table::
   :widths: 20 15 65
   :header-rows: 1

   * - Parameter
     - Type
     - Description
   * - ``startDate``
     - DateTime?
     - Filter calls from this date onwards (format: YYYY-MM-DD)
   * - ``endDate``
     - DateTime?
     - Filter calls up to this date (format: YYYY-MM-DD)
   * - ``callType``
     - CallType?
     - Filter by call type (audio, video, p2p, group)
   * - ``status``
     - CallAnalyticsStatus?
     - Filter by call outcome (ended, failed, declined, etc.)
   * - ``participant``
     - String?
     - Filter by participant (NX ID or phone number)
   * - ``page``
     - int
     - Page number (default: 1)
   * - ``pageSize``
     - int
     - Results per page (default: 20)

**Example**

.. code-block:: dart

    // Get all calls (paginated)
    final history = await client.calls.getCallHistory();

    // Filter by date range
    final recent = await client.calls.getCallHistory(
      startDate: DateTime(2026, 5, 1),
      endDate: DateTime(2026, 5, 27),
    );

    // Filter by call type
    final videoCalls = await client.calls.getCallHistory(
      callType: CallType.video,
    );

    // Filter by status
    final failedCalls = await client.calls.getCallHistory(
      status: CallAnalyticsStatus.failed,
    );

    // Filter by participant
    final callsWithUser = await client.calls.getCallHistory(
      participant: 'user123',
    );

    // Combined filters with pagination
    final filtered = await client.calls.getCallHistory(
      callType: CallType.video,
      status: CallAnalyticsStatus.ended,
      startDate: DateTime(2026, 5, 20),
      page: 1,
      pageSize: 20,
    );

----

CallManager Advanced Features
-----------------------------

CallManager provides advanced features for quality control and call statistics.

**Video Quality Settings**

Adjust video resolution and frame rate based on network conditions:

.. code-block:: dart

    // Set low quality for poor network
    callManager.setVideoQuality(
      width: 640,
      height: 480,
      fps: 15,
    );

    // Set high quality for good network
    callManager.setVideoQuality(
      width: 1920,
      height: 1080,
      fps: 30,
    );

**Bitrate Control**

Limit audio and video bandwidth:

.. code-block:: dart

    // Set audio bitrate (kbps)
    callManager.setAudioBitrate(64);  // 64 kbps

    // Set video bitrate (kbps)
    callManager.setVideoBitrate(1000);  // 1000 kbps

**Call Statistics**

Monitor real-time call quality metrics:

.. code-block:: dart

    // Start collecting statistics (every 2 seconds)
    callManager.startCallStatsCollection();

    // Listen to statistics stream
    callManager.callStatsStream?.listen((stats) {
      print('Video bitrate: ${stats['video']['bitrate']} bps');
      print('Packets lost: ${stats['video']['packetsLost']}');
      print('Frame size: ${stats['video']['frameWidth']}x${stats['video']['frameHeight']}');
    });

    // Get latest stats snapshot
    final latest = callManager.latestCallStats;

**Statistics Data Structure**

The stats stream provides the following data:

.. list-table::
   :widths: 25 75
   :header-rows: 1

   * - Field
     - Description
   * - ``video.bitrate``
     - Current video bitrate in bps
   * - ``video.packetsReceived``
     - Total video packets received
   * - ``video.packetsLost``
     - Total video packets lost
   * - ``video.bytesReceived``
     - Total video bytes received
   * - ``video.framesReceived``
     - Total video frames received
   * - ``video.frameWidth``
     - Current video frame width
   * - ``video.frameHeight``
     - Current video frame height
   * - ``audio.bitrate``
     - Current audio bitrate in bps
   * - ``audio.packetsReceived``
     - Total audio packets received
   * - ``audio.packetsLost``
     - Total audio packets lost
   * - ``audio.bytesReceived``
     - Total audio bytes received
   * - ``videoOut.packetsSent``
     - Total video packets sent
   * - ``videoOut.bytesSent``
     - Total video bytes sent
   * - ``audioOut.packetsSent``
     - Total audio packets sent
   * - ``audioOut.bytesSent``
     - Total audio bytes sent

**Quality Presets**

Recommended quality settings for different network conditions:

.. list-table::
   :widths: 20 40 40
   :header-rows: 1

   * - Network
     - Resolution
     - Bitrate
   * - Poor (3G)
     - 640x480 @ 15fps
     - 500 kbps video, 32 kbps audio
   * - Medium (4G/WiFi)
     - 1280x720 @ 30fps (default)
     - 1000 kbps video, 64 kbps audio
   * - Good (5G/Fiber)
     - 1920x1080 @ 30fps
     - 2000 kbps video, 128 kbps audio
