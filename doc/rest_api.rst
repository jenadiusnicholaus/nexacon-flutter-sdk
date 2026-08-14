REST API Reference
==================

Prefer to use the Nexacon REST API directly without the Flutter SDK? This page documents every endpoint the SDK wraps, with raw HTTP examples.

You can use any HTTP client in any language — Dart, JavaScript, Python, Swift, Kotlin, cURL, etc.

.. note::

   The Flutter SDK is a convenience wrapper around these endpoints. It adds NX signaling, WebRTC management, reconnection logic, and call lifecycle handling. If you only need REST calls (initiate calls, send messages, fetch history), the API below is all you need.

----

Authentication
--------------

All requests require two headers for API authentication:

.. list-table::
   :widths: 25 75
   :header-rows: 1

   * - Header
     - Description
   * - ``X-API-Key``
     - Your Nexacon API key
   * - ``X-Secret-Key``
     - Your Nexacon secret key

For endpoints that require NX token authentication (call signaling, messaging), also include:

.. list-table::
   :widths: 25 75
   :header-rows: 1

   * - Header
     - Description
   * - ``X-NX-Token``
     - NX token obtained from the token endpoint

**Base URL**

::

    https://nxservice.quantumvision-tech.com/api/v1.0

----

NX Token
--------

Get NX Token
~~~~~~~~~~~~

Obtain an NX token for signaling. This token is used for WebSocket authentication and as the ``X-NX-Token`` header in subsequent requests.

**Request**

::

    POST /nexacon-auth/nxm-token/

.. code-block:: json

    {
      "username": "+255788811191",
      "host": "nxservice.quantumvision-tech.com"
    }

**Response**

.. code-block:: json

    {
      "token": "nx_abc123...",
      "jid": "+255788811191@nxservice.quantumvision-tech.com",
      "nxws": "wss://nxservice.quantumvision-tech.com/nx-websocket/",
      "refresh_token": "rt_xyz789..."
    }

.. note::

   The ``jid`` field is the user's NX ID. The SDK maps this to ``nxid`` internally. When using the API directly, use ``jid`` as the NX identifier.

**cURL example**

.. code-block:: bash

    curl -X POST https://nxservice.quantumvision-tech.com/api/v1.0/nexacon-auth/nxm-token/ \
      -H "Content-Type: application/json" \
      -H "X-API-Key: YOUR_API_KEY" \
      -H "X-Secret-Key: YOUR_SECRET_KEY" \
      -d '{"username": "+255788811191", "host": "nxservice.quantumvision-tech.com"}'

Refresh NX Token
~~~~~~~~~~~~~~~~~

**Request**

::

    POST /nexacon-auth/nxm-token/refresh/

.. code-block:: json

    {
      "refresh_token": "rt_xyz789..."
    }

**Response**

.. code-block:: json

    {
      "token": "nx_new_token...",
      "refresh_token": "rt_new_refresh..."
    }

----

Calls
-----

Initiate a 1:1 Call
~~~~~~~~~~~~~~~~~~~~

**Request**

::

    POST /nx/call/

.. code-block:: json

    {
      "to": "+255788811192",
      "type": "video"
    }

**Parameters**

.. list-table::
   :widths: 20 15 65
   :header-rows: 1

   * - Field
     - Type
     - Description
   * - ``to``
     - String
     - Recipient's phone number or NX ID
   * - ``type``
     - String
     - ``audio`` or ``video``
   * - ``room``
     - String?
     - Optional custom room identifier

**cURL example**

.. code-block:: bash

    curl -X POST https://nxservice.quantumvision-tech.com/api/v1.0/nx/call/ \
      -H "Content-Type: application/json" \
      -H "X-API-Key: YOUR_API_KEY" \
      -H "X-Secret-Key: YOUR_SECRET_KEY" \
      -H "X-NX-Token: YOUR_NX_TOKEN" \
      -d '{"to": "+255788811192", "type": "video"}'

Get a Pre-signed Call URL
~~~~~~~~~~~~~~~~~~~~~~~~~~

Generate a shareable URL for joining a call from a browser or mobile app.

**Request**

::

    POST /nx/call-url/

.. code-block:: json

    {
      "to": "+255788811192",
      "type": "video"
    }

**Response**

.. code-block:: json

    {
      "call_url": "https://nxservice.quantumvision-tech.com/call?room=abc123&caller=..."
    }

Decline an Incoming Call
~~~~~~~~~~~~~~~~~~~~~~~~~

**Request**

::

    POST /nx/call/decline/

.. code-block:: json

    {
      "room": "room_abc123"
    }

Get WebRTC Credentials
~~~~~~~~~~~~~~~~~~~~~~~

Fetch TURN/STUN credentials for WebRTC peer connections. Credentials have a 24-hour TTL.

**Request**

::

    GET /nx/webrtc/credentials/

**Response**

.. code-block:: json

    {
      "iceServers": [
        {"urls": "stun:stun.l.google.com:19302"},
        {"urls": "turn:turn.nexacon.com:3478", "username": "...", "credential": "..."}
      ]
    }

**cURL example**

.. code-block:: bash

    curl https://nxservice.quantumvision-tech.com/api/v1.0/nx/webrtc/credentials/ \
      -H "X-API-Key: YOUR_API_KEY" \
      -H "X-Secret-Key: YOUR_SECRET_KEY" \
      -H "X-NX-Token: YOUR_NX_TOKEN"

Initiate a P2P WebRTC Call
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Sends both an FCM push notification and an NX signaling message to the recipient.

**Request**

::

    POST /nx/webrtc/call/

.. code-block:: json

    {
      "to": "+255788811192",
      "type": "p2p"
    }

Record Call Analytics
~~~~~~~~~~~~~~~~~~~~~~

Record a call event for analytics and history. Call this after every call ends, fails, is declined, or is missed.

**Request**

::

    POST /nx/call-analytics/

.. code-block:: json

    {
      "room": "room_abc123",
      "call_type": "video",
      "duration_seconds": 120,
      "status": "ended",
      "metadata": {"ended_by": "caller", "is_group": false}
    }

**Status values**

.. list-table::
   :widths: 25 75
   :header-rows: 1

   * - Status
     - Description
   * - ``initiated``
     - Call was initiated by the caller
   * - ``calling``
     - Ringing, waiting for recipient to answer
   * - ``answered``
     - Recipient answered the call
   * - ``declined``
     - Recipient declined the call
   * - ``cancelled``
     - Caller cancelled before answer
   * - ``missed``
     - Recipient did not answer
   * - ``ended``
     - Call completed successfully
   * - ``failed``
     - Call failed (e.g. ICE connection error)

Get Call History
~~~~~~~~~~~~~~~~~

**Request**

::

    GET /nx/call-history/?page=1&page_size=20

**Query parameters**

.. list-table::
   :widths: 20 15 65
   :header-rows: 1

   * - Parameter
     - Type
     - Description
   * - ``start_date``
     - String
     - Filter from date (YYYY-MM-DD)
   * - ``end_date``
     - String
     - Filter to date (YYYY-MM-DD)
   * - ``call_type``
     - String
     - Filter by type: ``audio``, ``video``, ``p2p``, ``group``
   * - ``status``
     - String
     - Filter by outcome: ``ended``, ``failed``, ``declined``, etc.
   * - ``participant``
     - String
     - Filter by participant NX ID or phone number
   * - ``page``
     - int
     - Page number (default: 1)
   * - ``page_size``
     - int
     - Results per page (default: 20)

**cURL example**

.. code-block:: bash

    curl "https://nxservice.quantumvision-tech.com/api/v1.0/nx/call-history/?page=1&page_size=20&call_type=video" \
      -H "X-API-Key: YOUR_API_KEY" \
      -H "X-Secret-Key: YOUR_SECRET_KEY" \
      -H "X-NX-Token: YOUR_NX_TOKEN"

----

Messaging
---------

Send a Message
~~~~~~~~~~~~~~

**Request**

::

    POST /nx/message/

.. code-block:: json

    {
      "to": "+255788811192",
      "message": "Hello!",
      "type": "chat"
    }

**Parameters**

.. list-table::
   :widths: 20 15 65
   :header-rows: 1

   * - Field
     - Type
     - Description
   * - ``to``
     - String
     - Recipient's phone number or NX ID
   * - ``message``
     - String
     - The message content
   * - ``type``
     - String
     - ``chat`` (default) or ``groupchat``

**cURL example**

.. code-block:: bash

    curl -X POST https://nxservice.quantumvision-tech.com/api/v1.0/nx/message/ \
      -H "Content-Type: application/json" \
      -H "X-API-Key: YOUR_API_KEY" \
      -H "X-Secret-Key: YOUR_SECRET_KEY" \
      -H "X-NX-Token: YOUR_NX_TOKEN" \
      -d '{"to": "+255788811192", "message": "Hello!", "type": "chat"}'

Broadcast a Message
~~~~~~~~~~~~~~~~~~~~

Send the same message to multiple recipients at once.

**Request**

::

    POST /nx/broadcast/

.. code-block:: json

    {
      "message": "System maintenance at 10pm tonight.",
      "recipients": ["+255788811192", "+255788811193"]
    }

**cURL example**

.. code-block:: bash

    curl -X POST https://nxservice.quantumvision-tech.com/api/v1.0/nx/broadcast/ \
      -H "Content-Type: application/json" \
      -H "X-API-Key: YOUR_API_KEY" \
      -H "X-Secret-Key: YOUR_SECRET_KEY" \
      -H "X-NX-Token: YOUR_NX_TOKEN" \
      -d '{"message": "Maintenance tonight", "recipients": ["+255788811192", "+255788811193"]}'

Get Message History
~~~~~~~~~~~~~~~~~~~~

**Request**

::

    GET /nx/history/?page=1&page_size=20

**Query parameters**

.. list-table::
   :widths: 20 15 65
   :header-rows: 1

   * - Parameter
     - Type
     - Description
   * - ``start_date``
     - String
     - Filter from date (YYYY-MM-DD)
   * - ``end_date``
     - String
     - Filter to date (YYYY-MM-DD)
   * - ``sender``
     - String
     - Filter by sender NX ID or phone number
   * - ``message_type``
     - String
     - Filter by type: ``chat``, ``groupchat``
   * - ``page``
     - int
     - Page number (default: 1)
   * - ``page_size``
     - int
     - Results per page (default: 20)

**cURL example**

.. code-block:: bash

    curl "https://nxservice.quantumvision-tech.com/api/v1.0/nx/history/?page=1&page_size=20&sender=%2B255788811192" \
      -H "X-API-Key: YOUR_API_KEY" \
      -H "X-Secret-Key: YOUR_SECRET_KEY" \
      -H "X-NX-Token: YOUR_NX_TOKEN"

----

Contacts
--------

Get Contacts
~~~~~~~~~~~~

**Request**

::

    GET /nx/contacts/

**Response**

.. code-block:: json

    {
      "contacts": [
        {"nxid": "user1@nxservice.quantumvision-tech.com", "name": "Alice"},
        {"nxid": "user2@nxservice.quantumvision-tech.com", "name": "Bob"}
      ]
    }

Add a Contact
~~~~~~~~~~~~~

**Request**

::

    POST /nx/contacts/

.. code-block:: json

    {
      "nxid": "+255788811192@nxservice.quantumvision-tech.com",
      "name": "Alice"
    }

Remove a Contact
~~~~~~~~~~~~~~~~~

**Request**

::

    DELETE /nx/contacts/{nxid}/

**cURL example**

.. code-block:: bash

    curl -X DELETE https://nxservice.quantumvision-tech.com/api/v1.0/nx/contacts/%2B255788811192@nxservice.quantumvision-tech.com/ \
      -H "X-API-Key: YOUR_API_KEY" \
      -H "X-Secret-Key: YOUR_SECRET_KEY" \
      -H "X-NX-Token: YOUR_NX_TOKEN"

----

Presence
--------

Get Presence
~~~~~~~~~~~~

**Request**

::

    GET /nx/presence/?user={nxid}

**Query parameters**

.. list-table::
   :widths: 20 15 65
   :header-rows: 1

   * - Parameter
     - Type
     - Description
   * - ``user``
     - String?
     - Optional NX ID to check a specific user. Omit to get your own presence.

**Response**

.. code-block:: json

    {
      "user": "+255788811192@nxservice.quantumvision-tech.com",
      "status": "online",
      "last_seen": "2026-08-14T10:30:00Z"
    }

----

Rooms
-----

List Rooms
~~~~~~~~~~

**Request**

::

    GET /nx/rooms/

Create a Room
~~~~~~~~~~~~~

**Request**

::

    POST /nx/rooms/

.. code-block:: json

    {
      "name": "team-chat",
      "title": "Team Chat",
      "description": "General team discussion",
      "avatar_url": ""
    }

Get Room Details
~~~~~~~~~~~~~~~~~

**Request**

::

    GET /nx/rooms/{name}/

Destroy a Room
~~~~~~~~~~~~~~

**Request**

::

    DELETE /nx/rooms/{name}/

Add a Member
~~~~~~~~~~~~

**Request**

::

    POST /nx/rooms/{name}/members/

.. code-block:: json

    {
      "nxid": "+255788811192@nxservice.quantumvision-tech.com",
      "affiliation": "member"
    }

Remove a Member
~~~~~~~~~~~~~~~

**Request**

::

    DELETE /nx/rooms/{name}/members/{nxid}/

----

Devices
-------

Register a Device
~~~~~~~~~~~~~~~~~~

**Request**

::

    POST /nx/register-device/

.. code-block:: json

    {
      "fcm_token": "firebase_token_here",
      "platform": "android",
      "device_name": "Pixel 7"
    }

**Parameters**

.. list-table::
   :widths: 20 15 65
   :header-rows: 1

   * - Field
     - Type
     - Description
   * - ``fcm_token``
     - String
     - Firebase Cloud Messaging token
   * - ``platform``
     - String
     - ``android`` or ``ios``
   * - ``device_name``
     - String?
     - Optional device name

Unregister a Device
~~~~~~~~~~~~~~~~~~~~

**Request**

::

    DELETE /nx/register-device/

.. code-block:: json

    {
      "fcm_token": "firebase_token_here"
    }

List Devices
~~~~~~~~~~~~

**Request**

::

    GET /nx/devices/

Revoke a Device
~~~~~~~~~~~~~~~

**Request**

::

    DELETE /nx/devices/{deviceId}/

----

WebSocket Signaling (NX Connection)
-----------------------------------

For real-time call signaling and messaging, connect to the NX WebSocket:

**URL**

::

    wss://nxservice.quantumvision-tech.com/nx-websocket/

**Protocol**

The WebSocket uses the XMPP over WebSocket protocol. After connecting, authenticate with the NX token received from the token endpoint.

.. note::

   The Flutter SDK handles WebSocket connection, authentication, reconnection, and message routing automatically. If you need real-time signaling in a non-Flutter environment, you will need to implement the WebSocket client yourself. The SDK's internal ``xmpp_client.dart`` can serve as a reference implementation.

**Authentication**

After connecting, send an authentication stanza with your NX token:

.. code-block:: xml

    <auth xmlns="urn:ietf:params:xml:ns:xmpp-sasl" mechanism="PLAIN">
      BASE64(nxid\x00nxid\x00nxtoken)
    </auth>

Once authenticated, you will receive presence and message events in real time.

----

Call Signaling Events
~~~~~~~~~~~~~~~~~~~~~~

Call signaling messages are JSON payloads sent over the WebSocket. Each message has a ``type`` field that determines its structure.

**1. call_invitation** — Incoming call invitation

Sent by the caller to the callee to initiate a call. Use this to show an incoming call UI in the foreground.

.. code-block:: json

    {
      "type": "call_invitation",
      "roomId": "call_abc123",
      "callType": "video",
      "fromNxId": "+255788811191@nxservice.quantumvision-tech.com",
      "fromName": "Alice",
      "timestamp": 1723624800000
    }

.. list-table::
   :widths: 20 15 65
   :header-rows: 1

   * - Field
     - Type
     - Description
   * - ``type``
     - String
     - Always ``call_invitation``
   * - ``roomId``
     - String
     - Unique room identifier for this call
   * - ``callType``
     - String
     - ``audio`` or ``video``
   * - ``fromNxId``
     - String
     - Caller's NX ID (e.g. ``+255788811191@nxservice.quantumvision-tech.com``)
   * - ``fromName``
     - String
     - Caller's display name
   * - ``timestamp``
     - int
     - Unix timestamp in milliseconds

**2. call_response** — Response to call invitation

Sent by the callee to accept or reject the call.

.. code-block:: json

    {
      "type": "call_response",
      "roomId": "call_abc123",
      "accepted": true,
      "timestamp": 1723624801000
    }

.. list-table::
   :widths: 20 15 65
   :header-rows: 1

   * - Field
     - Type
     - Description
   * - ``type``
     - String
     - Always ``call_response``
   * - ``roomId``
     - String
     - Room identifier of the call
   * - ``accepted``
     - bool
     - ``true`` to accept, ``false`` to reject
   * - ``timestamp``
     - int
     - Unix timestamp in milliseconds

**3. call_accepted** — Call was accepted

Sent by the callee after accepting. Similar to ``call_response`` with ``accepted: true``.

.. code-block:: json

    {
      "type": "call_accepted",
      "roomId": "call_abc123",
      "timestamp": 1723624802000
    }

**4. call_end** — End the call

Sent by either party to end the call.

.. code-block:: json

    {
      "type": "call_end",
      "roomId": "call_abc123",
      "timestamp": 1723624900000
    }

**5. webrtc_offer** — WebRTC SDP offer

Sent by the caller to initiate the WebRTC peer connection.

.. code-block:: json

    {
      "type": "webrtc_offer",
      "roomId": "call_abc123",
      "sdp": "v=0\r\no=- 4611731400430051...",
      "sdp_type": "offer"
    }

**6. webrtc_answer** — WebRTC SDP answer

Sent by the callee in response to the offer.

.. code-block:: json

    {
      "type": "webrtc_answer",
      "roomId": "call_abc123",
      "sdp": "v=0\r\no=- 4611731400430052...",
      "sdp_type": "answer"
    }

**7. webrtc_ice_candidate** — ICE candidate exchange

Sent by either party to exchange ICE candidates for NAT traversal.

.. code-block:: json

    {
      "type": "webrtc_ice_candidate",
      "roomId": "call_abc123",
      "candidate": "candidate:842163049 1 udp 1677729535...",
      "sdpMid": "0",
      "sdpMLineIndex": 0
    }

.. list-table::
   :widths: 20 15 65
   :header-rows: 1

   * - Field
     - Type
     - Description
   * - ``type``
     - String
     - Always ``webrtc_ice_candidate``
   * - ``roomId``
     - String
     - Room identifier of the call
   * - ``candidate``
     - String
     - ICE candidate string
   * - ``sdpMid``
     - String?
     - SDP media ID
   * - ``sdpMLineIndex``
     - int?
     - SDP media line index

**Plain-text call invitation (fallback)**

Some call flows send a plain-text message containing a call URL instead of a JSON signaling message. Parse the URL to extract call parameters:

.. code-block:: text

    Incoming p2p call. Click to join: https://nxservice.quantumvision-tech.com/nexacon-call.html?room=call_abc123&caller=+255788811191&type=audio

Extract ``room``, ``caller``, and ``type`` from the query parameters.

----

Messaging Events
~~~~~~~~~~~~~~~~~

Real-time messaging events are JSON payloads sent over the WebSocket.

**1. Chat message** — Incoming text message

.. code-block:: json

    {
      "type": "chat",
      "message": "Hello!",
      "from": "+255788811191@nxservice.quantumvision-tech.com",
      "to": "+255788811192@nxservice.quantumvision-tech.com",
      "timestamp": 1723624800000
    }

.. list-table::
   :widths: 20 15 65
   :header-rows: 1

   * - Field
     - Type
     - Description
   * - ``type``
     - String
     - ``chat`` or ``groupchat``
   * - ``message``
     - String
     - Message content
   * - ``from``
     - String
     - Sender's NX ID
   * - ``to``
     - String
     - Recipient's NX ID
   * - ``timestamp``
     - int
     - Unix timestamp in milliseconds

**2. Typing indicator** — User is typing

.. code-block:: json

    {
      "type": "typing",
      "is_typing": true,
      "from": "+255788811191@nxservice.quantumvision-tech.com",
      "timestamp": 1723624800000
    }

.. list-table::
   :widths: 20 15 65
   :header-rows: 1

   * - Field
     - Type
     - Description
   * - ``type``
     - String
     - Always ``typing``
   * - ``is_typing``
     - bool
     - ``true`` when user is typing, ``false`` when stopped
   * - ``from``
     - String
     - Sender's NX ID
   * - ``timestamp``
     - int
     - Unix timestamp in milliseconds

**3. Read receipt** — Message was read

.. code-block:: json

    {
      "type": "read_receipt",
      "message_id": "msg_abc123",
      "from": "+255788811191@nxservice.quantumvision-tech.com",
      "timestamp": 1723624800000
    }

.. list-table::
   :widths: 20 15 65
   :header-rows: 1

   * - Field
     - Type
     - Description
   * - ``type``
     - String
     - Always ``read_receipt``
   * - ``message_id``
     - String
     - ID of the message that was read
   * - ``from``
     - String
     - Sender's NX ID
   * - ``timestamp``
     - int
     - Unix timestamp in milliseconds

**Sending messages**

To send a message, send a JSON payload to the recipient's NX ID via the WebSocket:

.. code-block:: json

    {
      "type": "chat",
      "message": "Hello!",
      "timestamp": 1723624800000
    }

To send a typing indicator:

.. code-block:: json

    {
      "type": "typing",
      "is_typing": true,
      "timestamp": 1723624800000
    }

To send a read receipt:

.. code-block:: json

    {
      "type": "read_receipt",
      "message_id": "msg_abc123",
      "timestamp": 1723624800000
    }

----

Presence Events
~~~~~~~~~~~~~~~

Presence events indicate user online/offline status and typing state. These are delivered as presence stanzas over the WebSocket.

**1. User online** — User became available

.. code-block:: json

    {
      "from": "+255788811191@nxservice.quantumvision-tech.com",
      "type": null,
      "show": "available"
    }

**2. User offline** — User went offline

.. code-block:: json

    {
      "from": "+255788811191@nxservice.quantumvision-tech.com",
      "type": "unavailable",
      "show": null
    }

**3. User typing (via presence)** — Composing state

.. code-block:: json

    {
      "from": "+255788811191@nxservice.quantumvision-tech.com",
      "type": "composing",
      "show": null
    }

**4. User stopped typing (via presence)** — Paused state

.. code-block:: json

    {
      "from": "+255788811191@nxservice.quantumvision-tech.com",
      "type": "paused",
      "show": null
    }

.. list-table::
   :widths: 25 75
   :header-rows: 1

   * - Presence Type
     - Description
   * - ``null`` / ``available``
     - User is online and available
   * - ``unavailable``
     - User is offline
   * - ``composing``
     - User is typing a message
   * - ``paused``
     - User stopped typing
   * - ``active``
     - User is active (e.g. just opened the app)

**Sending presence**

To broadcast your own presence (online status):

.. code-block:: xml

    <presence>
      <show>available</show>
    </presence>

To go offline:

.. code-block:: xml

    <presence type="unavailable"/>

To send a typing indicator via presence:

.. code-block:: xml

    <presence to="+255788811192@nxservice.quantumvision-tech.com">
      <show>composing</show>
    </presence>

----

Connection Lifecycle
~~~~~~~~~~~~~~~~~~~~~

**Heartbeat / Ping**

Send a ping every 30 seconds to keep the connection alive:

.. code-block:: xml

    <iq type="get" id="ping_1723624800000">
      <ping xmlns="urn:xmpp:ping"/>
    </iq>

The server responds with:

.. code-block:: xml

    <iq type="result" id="ping_1723624800000"/>

**Reconnection**

If the WebSocket disconnects, reconnect with exponential backoff:

.. list-table::
   :widths: 25 75
   :header-rows: 1

   * - Attempt
     - Delay
   * - 1
     - 5 seconds
   * - 2
     - 10 seconds
   * - 3
     - 20 seconds
   * - 4
     - 40 seconds
   * - 5+
     - Max 30 seconds (capped)

Maximum reconnection attempts: **10**

**Event Summary**

.. list-table::
   :widths: 25 25 50
   :header-rows: 1

   * - Event
     - Direction
     - Description
   * - ``call_invitation``
     - Incoming
     - Incoming call — use to show call UI in foreground
   * - ``call_response``
     - Outgoing
     - Accept or reject an incoming call
   * - ``call_accepted``
     - Incoming
     - Remote party accepted the call
   * - ``call_end``
     - Bidirectional
     - End the active call
   * - ``webrtc_offer``
     - Outgoing/Incoming
     - WebRTC SDP offer for peer connection
   * - ``webrtc_answer``
     - Outgoing/Incoming
     - WebRTC SDP answer for peer connection
   * - ``webrtc_ice_candidate``
     - Bidirectional
     - ICE candidate for NAT traversal
   * - ``chat`` / ``groupchat``
     - Bidirectional
     - Real-time text message
   * - ``typing``
     - Bidirectional
     - Typing indicator (JSON message)
   * - ``read_receipt``
     - Bidirectional
     - Message read confirmation
   * - ``composing`` / ``paused``
     - Bidirectional
     - Typing indicator (presence stanza)
   * - ``available`` / ``unavailable``
     - Bidirectional
     - Online/offline presence
   * - Ping/Pong
     - Bidirectional
     - Keep-alive heartbeat (every 30s)

----

SDK vs API Comparison
---------------------

.. list-table::
   :widths: 30 35 35
   :header-rows: 1

   * - Feature
     - Flutter SDK
     - REST API
   * - Initiate calls
     - ✅ One method call
     - ✅ ``POST /nx/call/``
   * - Send messages
     - ✅ One method call
     - ✅ ``POST /nx/message/``
   * - Real-time messaging
     - ✅ Built-in streams
     - ⚠️ Requires WebSocket client
   * - WebRTC peer connection
     - ✅ Fully managed
     - ❌ Implement yourself
   * - ICE negotiation
     - ✅ Automatic
     - ❌ Implement yourself
   * - Reconnection
     - ✅ Automatic backoff
     - ❌ Implement yourself
   * - Call analytics
     - ✅ Auto-recorded
     - ✅ ``POST /nx/call-analytics/``
   * - Push notifications
     - ✅ Via SDK
     - ✅ ``POST /nx/register-device/``
   * - Platform
     - Flutter only
     - Any platform / language
