Rooms Service
=============

The Rooms service provides functionality for managing group chat rooms.

.. code-block:: dart

    final rooms = client.rooms;

Methods
~~~~~~~

list
^^^^

List all rooms for the current user.

.. code-block:: dart

    Future<Map<String, dynamic>> list()

Returns
^^^^^^^

``Future<Map<String, dynamic>>``: List of rooms

create
^^^^^^

Create a new group chat room.

.. code-block:: dart

    Future<Map<String, dynamic>> create({
      String? name,
      String? title,
      String description = '',
      String avatarUrl = '',
    })

Parameters
^^^^^^^^^^

* **name** (String?): Room name
* **title** (String?): Room title
* **description** (String): Room description
* **avatarUrl** (String): Room avatar URL

Returns
^^^^^^^

``Future<Map<String, dynamic>>``: Response from the server

get
^^^

Get room details and members.

.. code-block:: dart

    Future<Map<String, dynamic>> get(String name)

Parameters
^^^^^^^^^^

* **name** (String): Room name

Returns
^^^^^^^

``Future<Map<String, dynamic>>``: Room details

destroy
^^^^^^^

Destroy a room.

.. code-block:: dart

    Future<Map<String, dynamic>> destroy(String name)

Parameters
^^^^^^^^^^

* **name** (String): Room name

Returns
^^^^^^^

``Future<Map<String, dynamic>>``: Response from the server

addMember
^^^^^^^^^

Add a member to a room with specified affiliation.

.. code-block:: dart

    Future<Map<String, dynamic>> addMember({
      required String name,
      required String nxid,
      String affiliation = 'member',
    })

Parameters
^^^^^^^^^^

* **name** (String): Room name
* **nxid** (String): User's NX identifier
* **affiliation** (String): Member affiliation (default: 'member')

Returns
^^^^^^^

``Future<Map<String, dynamic>>``: Response from the server

removeMember
^^^^^^^^^^^^

Remove a member from a room.

.. code-block:: dart

    Future<Map<String, dynamic>> removeMember({
      required String name,
      required String nxid,
    })

Parameters
^^^^^^^^^^

* **name** (String): Room name
* **nxid** (String): User's NX identifier

Returns
^^^^^^^

``Future<Map<String, dynamic>>``: Response from the server
