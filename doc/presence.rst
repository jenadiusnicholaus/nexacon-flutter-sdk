Presence Service
================

The Presence service provides functionality for checking user presence and online status.

.. code-block:: dart

    final presence = client.presence;

Methods
~~~~~~~

get
^^^

Get the last seen / presence for a user.

.. code-block:: dart

    Future<Map<String, dynamic>> get([String? user])

Parameters
^^^^^^^^^^

* **user** (String?): Optional user identifier. If not provided, returns current user's presence.

Returns
^^^^^^^

``Future<Map<String, dynamic>>``: User presence information including last seen timestamp and online status
