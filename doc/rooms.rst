Rooms Service
=============

The ``Rooms`` service manages group chat rooms. You can create rooms, add or remove members, and control member roles using affiliations.

.. code-block:: dart

    // Access via client
    final rooms = client.rooms;

----

Member Affiliations
-------------------

.. list-table::
   :widths: 20 80
   :header-rows: 1

   * - Affiliation
     - Description
   * - ``owner``
     - Full control over the room
   * - ``admin``
     - Can manage members and settings
   * - ``member``
     - Standard member (default)
   * - ``none``
     - No affiliation (used to remove)

----

Methods
-------

list
~~~~

List all rooms the current user belongs to.

**Signature**

.. code-block:: dart

    Future<Map<String, dynamic>> list()

**Example**

.. code-block:: dart

    final result = await client.rooms.list();
    final rooms = result['rooms'];

----

create
~~~~~~

Create a new group chat room.

**Signature**

.. code-block:: dart

    Future<Map<String, dynamic>> create({
      String? name,
      String? title,
      String description = '',
      String avatarUrl = '',
    })

**Parameters**

.. list-table::
   :widths: 20 15 65
   :header-rows: 1

   * - Parameter
     - Type
     - Description
   * - ``name``
     - String?
     - Unique room identifier (e.g. ``team-alpha``). Required if ``title`` not set.
   * - ``title``
     - String?
     - Display title for the room. Required if ``name`` not set.
   * - ``description``
     - String
     - Optional room description
   * - ``avatarUrl``
     - String
     - Optional URL for the room avatar image

**Example**

.. code-block:: dart

    await client.rooms.create(
      name: 'team-alpha',
      title: 'Team Alpha',
      description: 'Main communication room for Team Alpha',
    );

----

get
~~~

Get details and member list for a specific room.

**Signature**

.. code-block:: dart

    Future<Map<String, dynamic>> get(String name)

**Parameters**

.. list-table::
   :widths: 20 15 65
   :header-rows: 1

   * - Parameter
     - Type
     - Description
   * - ``name``
     - String
     - The unique room identifier

**Example**

.. code-block:: dart

    final room = await client.rooms.get('team-alpha');
    print(room['title']);
    print(room['members']);

----

destroy
~~~~~~~

Permanently delete a room and remove all its members.

.. warning::
   This action is irreversible. All room data will be lost.

**Signature**

.. code-block:: dart

    Future<Map<String, dynamic>> destroy(String name)

**Parameters**

.. list-table::
   :widths: 20 15 65
   :header-rows: 1

   * - Parameter
     - Type
     - Description
   * - ``name``
     - String
     - The unique room identifier

**Example**

.. code-block:: dart

    await client.rooms.destroy('team-alpha');

----

addMember
~~~~~~~~~

Add a user to a room with a specified affiliation (role).

**Signature**

.. code-block:: dart

    Future<Map<String, dynamic>> addMember({
      required String name,
      required String nxid,
      String affiliation = 'member',
    })

**Parameters**

.. list-table::
   :widths: 20 15 65
   :header-rows: 1

   * - Parameter
     - Type
     - Description
   * - ``name``
     - String
     - The unique room identifier
   * - ``nxid``
     - String
     - The NX identifier of the user to add
   * - ``affiliation``
     - String
     - Role: ``owner``, ``admin``, or ``member`` (default)

**Example**

.. code-block:: dart

    await client.rooms.addMember(
      name: 'team-alpha',
      nxid: 'user@nxservice.quantumvision-tech.com',
      affiliation: 'member',
    );

----

removeMember
~~~~~~~~~~~~

Remove a user from a room.

**Signature**

.. code-block:: dart

    Future<Map<String, dynamic>> removeMember({
      required String name,
      required String nxid,
    })

**Parameters**

.. list-table::
   :widths: 20 15 65
   :header-rows: 1

   * - Parameter
     - Type
     - Description
   * - ``name``
     - String
     - The unique room identifier
   * - ``nxid``
     - String
     - The NX identifier of the user to remove

**Example**

.. code-block:: dart

    await client.rooms.removeMember(
      name: 'team-alpha',
      nxid: 'user@nxservice.quantumvision-tech.com',
    );
