Devices Service
===============

The Devices service provides functionality for managing devices and push notifications.

.. code-block:: dart

    final devices = client.devices;

Platform Types
~~~~~~~~~~~~~~

The service supports the following platforms:

* ``android`` - Android devices
* ``ios`` - iOS devices
* ``web`` - Web browsers

Methods
~~~~~~~

register
^^^^^^^^

Register a device for push notifications.

.. code-block:: dart

    Future<Map<String, dynamic>> register({
      required String fcmToken,
      Platform platform = Platform.android,
      String? deviceName,
    })

Parameters
^^^^^^^^^^

* **fcmToken** (String): Firebase Cloud Messaging token
* **platform** (Platform): Device platform (android, ios, web)
* **deviceName** (String?): Optional device name

Returns
^^^^^^^

``Future<Map<String, dynamic>>``: Response from the server

unregister
^^^^^^^^^^

Unregister a device from push notifications.

.. code-block:: dart

    Future<Map<String, dynamic>> unregister(String fcmToken)

Parameters
^^^^^^^^^^

* **fcmToken** (String): Firebase Cloud Messaging token

Returns
^^^^^^^

``Future<Map<String, dynamic>>``: Response from the server

listDevices
^^^^^^^^^^

List all registered devices for the current user.

.. code-block:: dart

    Future<List<Map<String, dynamic>>> listDevices()

Returns
^^^^^^^

``Future<List<Map<String, dynamic>>>``: List of registered devices

revokeDevice
^^^^^^^^^^^^

Revoke a specific device.

.. code-block:: dart

    Future<Map<String, dynamic>> revokeDevice(String deviceId)

Parameters
^^^^^^^^^^

* **deviceId** (String): Device identifier

Returns
^^^^^^^

``Future<Map<String, dynamic>>``: Response from the server
