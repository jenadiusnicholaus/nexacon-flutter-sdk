Messaging Service
=================

The ``Messaging`` service allows you to send direct messages to users, broadcast to multiple recipients, and manage your contact list.

For real-time messaging with typing indicators and read receipts, use the ``MessagingManager`` with the global XMPP connection.

.. code-block:: dart

    // Access via client
    final messaging = client.messaging;

    // For real-time messaging
    final messagingManager = client.createMessagingManager();

----

Methods
-------

send
~~~~

Send a direct message to a single user.

**Signature**

.. code-block:: dart

    Future<Map<String, dynamic>> send({
      required String to,
      required String message,
      String messageType = 'chat',
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
   * - ``message``
     - String
     - The message content to send
   * - ``messageType``
     - String
     - Message type: ``chat`` (default) or ``groupchat``

**Example**

.. code-block:: dart

    await client.messaging.send(
      to: '+255788811192',
      message: 'Hello!',
    );

----

broadcast
~~~~~~~~~

Send the same message to multiple recipients at once.

**Signature**

.. code-block:: dart

    Future<Map<String, dynamic>> broadcast({
      required String message,
      required List<String> recipients,
    })

**Parameters**

.. list-table::
   :widths: 20 15 65
   :header-rows: 1

   * - Parameter
     - Type
     - Description
   * - ``message``
     - String
     - The message content to broadcast
   * - ``recipients``
     - List<String>
     - List of recipient phone numbers or NX identifiers

**Example**

.. code-block:: dart

    await client.messaging.broadcast(
      message: 'System maintenance at 10pm tonight.',
      recipients: ['+255788811192', '+255788811193'],
    );

----

getContacts
~~~~~~~~~~~

Retrieve the current user's full contact list.

**Signature**

.. code-block:: dart

    Future<List<Map<String, dynamic>>> getContacts()

**Returns**

A list of contact objects, each containing user details such as ``nxid``, ``name``, and ``status``.

**Example**

.. code-block:: dart

    final contacts = await client.messaging.getContacts();
    for (final contact in contacts) {
      print(contact['name']);
    }

----

addContact
~~~~~~~~~~

Add a user to the current user's contact list.

**Signature**

.. code-block:: dart

    Future<Map<String, dynamic>> addContact(String nxid)

**Parameters**

.. list-table::
   :widths: 20 15 65
   :header-rows: 1

   * - Parameter
     - Type
     - Description
   * - ``nxid``
     - String
     - The NX identifier of the user to add

**Example**

.. code-block:: dart

    await client.messaging.addContact('user@nxservice.quantumvision-tech.com');

----

removeContact
~~~~~~~~~~~~~

Remove a user from the current user's contact list.

**Signature**

.. code-block:: dart

    Future<Map<String, dynamic>> removeContact(String nxid)

**Parameters**

.. list-table::
   :widths: 20 15 65
   :header-rows: 1

   * - Parameter
     - Type
     - Description
   * - ``nxid``
     - String
     - The NX identifier of the user to remove

**Example**

.. code-block:: dart

    await client.messaging.removeContact('user@nxservice.quantumvision-tech.com');

----

getMessageHistory
~~~~~~~~~~~~~~~~~

Retrieve message history for the current user with optional filters.

**Signature**

.. code-block:: dart

    Future<Map<String, dynamic>> getMessageHistory({
      DateTime? startDate,
      DateTime? endDate,
      String? sender,
      String? messageType,
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
     - Filter messages from this date onwards (format: YYYY-MM-DD)
   * - ``endDate``
     - DateTime?
     - Filter messages up to this date (format: YYYY-MM-DD)
   * - ``sender``
     - String?
     - Filter by sender (NX ID or phone number)
   * - ``messageType``
     - String?
     - Filter by message type (chat, groupchat, etc.)
   * - ``page``
     - int
     - Page number (default: 1)
   * - ``pageSize``
     - int
     - Results per page (default: 20)

**Example**

.. code-block:: dart

    // Get all messages (paginated)
    final history = await client.messaging.getMessageHistory();

    // Filter by date range
    final recent = await client.messaging.getMessageHistory(
      startDate: DateTime(2026, 5, 1),
      endDate: DateTime(2026, 5, 27),
    );

    // Filter by sender
    final messagesFromUser = await client.messaging.getMessageHistory(
      sender: 'user123',
    );

    // Combined filters
    final filtered = await client.messaging.getMessageHistory(
      sender: 'user123',
      messageType: 'chat',
      page: 1,
      pageSize: 50,
    );

----

Real-Time Messaging with MessagingManager
-----------------------------------------

The ``MessagingManager`` provides real-time messaging capabilities using the global XMPP connection. It supports message streams, typing indicators, and read receipts.

**Setup**

.. code-block:: dart

    // Connect XMPP once
    await client.xmppManager.connect(
      jid: 'user@example.com',
      password: 'token',
      wsUrl: 'wss://your-server.com/ws',
    );

    // Create messaging manager
    final messagingManager = client.createMessagingManager();

**Listen for Messages**

.. code-block:: dart

    // Listen for incoming chat messages
    messagingManager.messageStream.listen((message) {
      print('Message: ${message['message']}');
      print('From: ${message['from']}');
      print('Timestamp: ${message['timestamp']}');
    });

    // Listen for typing indicators
    messagingManager.typingStream.listen((typing) {
      if (typing['is_typing'] == true) {
        print('User is typing...');
      } else {
        print('User stopped typing');
      }
    });

    // Listen for read receipts
    messagingManager.readReceiptStream.listen((receipt) {
      print('Message ${receipt['message_id']} was read');
    });

**Send Messages**

.. code-block:: dart

    // Send a chat message
    messagingManager.sendMessage(
      to: 'recipient@example.com',
      message: 'Hello!',
    );

    // Send typing indicator
    messagingManager.sendTypingIndicator('recipient@example.com', isTyping: true);

    // Stop typing indicator
    messagingManager.sendTypingIndicator('recipient@example.com', isTyping: false);

    // Send read receipt
    messagingManager.sendReadReceipt('recipient@example.com', 'msg_123');

**Cleanup**

.. code-block:: dart

    messagingManager.dispose();
