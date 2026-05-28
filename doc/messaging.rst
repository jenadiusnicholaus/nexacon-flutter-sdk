Messaging Service
=================

The Messaging service provides functionality for sending and receiving messages, and managing contacts.

.. code-block:: dart

    final messaging = client.messaging;

Methods
~~~~~~~

send
^^^^

Send a message to one or more recipients.

.. code-block:: dart

    Future<Map<String, dynamic>> send({
      required String message,
      required List<String> recipients,
    })

Parameters
^^^^^^^^^^

* **message** (String): The message content
* **recipients** (List<String>): List of recipient phone numbers or identifiers

Returns
^^^^^^^

``Future<Map<String, dynamic>>``: Response from the server

getContacts
^^^^^^^^^^^

Get the user's contact list.

.. code-block:: dart

    Future<List<Map<String, dynamic>>> getContacts()

Returns
^^^^^^^

``Future<List<Map<String, dynamic>>>``: List of contacts

addContact
^^^^^^^^^^

Add a user to contacts.

.. code-block:: dart

    Future<Map<String, dynamic>> addContact(String nxid)

Parameters
^^^^^^^^^^

* **nxid** (String): The user's NX identifier

Returns
^^^^^^^

``Future<Map<String, dynamic>>``: Response from the server

removeContact
^^^^^^^^^^^^^

Remove a user from contacts.

.. code-block:: dart

    Future<Map<String, dynamic>> removeContact(String nxid)

Parameters
^^^^^^^^^^

* **nxid** (String): The user's NX identifier

Returns
^^^^^^^

``Future<Map<String, dynamic>>``: Response from the server
