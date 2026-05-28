Messaging Service
=================

The ``Messaging`` service allows you to send direct messages to users, broadcast to multiple recipients, and manage your contact list.

.. code-block:: dart

    // Access via client
    final messaging = client.messaging;

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
