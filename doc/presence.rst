Presence Service
================

The ``Presence`` service lets you check whether a user is currently online and when they were last seen.

.. code-block:: dart

    // Access via client
    final presence = client.presence;

----

Methods
-------

get
~~~

Retrieve the online status and last seen timestamp for a user.

**Signature**

.. code-block:: dart

    Future<Map<String, dynamic>> get([String? user])

**Parameters**

.. list-table::
   :widths: 20 15 65
   :header-rows: 1

   * - Parameter
     - Type
     - Description
   * - ``user``
     - String?
     - NX identifier of the user to check. If omitted, returns the current user's presence.

**Returns**

A map containing:

.. list-table::
   :widths: 25 75
   :header-rows: 1

   * - Field
     - Description
   * - ``online``
     - ``true`` if the user is currently connected
   * - ``last_seen``
     - ISO 8601 timestamp of the user's last activity
   * - ``status``
     - Optional status message set by the user

**Example**

.. code-block:: dart

    // Check another user's presence
    final result = await client.presence.get(
      'user@nxservice.quantumvision-tech.com',
    );
    print(result['online']);     // true or false
    print(result['last_seen']);  // 2024-01-15T10:30:00Z

    // Check your own presence
    final myPresence = await client.presence.get();
    print(myPresence['status']);
