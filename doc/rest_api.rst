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

Initiate a Group Call
~~~~~~~~~~~~~~~~~~~~~~

**Request**

::

    POST /nx/group-call/

.. code-block:: json

    {
      "participants": ["+255788811192", "+255788811193"],
      "type": "video"
    }

**cURL example**

.. code-block:: bash

    curl -X POST https://nxservice.quantumvision-tech.com/api/v1.0/nx/group-call/ \
      -H "Content-Type: application/json" \
      -H "X-API-Key: YOUR_API_KEY" \
      -H "X-Secret-Key: YOUR_SECRET_KEY" \
      -H "X-NX-Token: YOUR_NX_TOKEN" \
      -d '{"participants": ["+255788811192", "+255788811193"], "type": "video"}'

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
