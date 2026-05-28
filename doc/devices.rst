Devices Service
===============

The ``Devices`` service manages device registration for push notifications (FCM). Register a device to receive incoming call alerts and messages even when the app is in the background.

.. code-block:: dart

    // Access via client
    final devices = client.devices;

----

Platform Types
--------------

.. list-table::
   :widths: 20 80
   :header-rows: 1

   * - Platform
     - Description
   * - ``Platform.android``
     - Android devices (default)
   * - ``Platform.ios``
     - iOS devices
   * - ``Platform.web``
     - Web browsers

----

Methods
-------

register
~~~~~~~~

Register a device to receive push notifications. Call this after the user logs in and you have a valid FCM token.

**Signature**

.. code-block:: dart

    Future<Map<String, dynamic>> register({
      required String fcmToken,
      Platform platform = Platform.android,
      String? deviceName,
    })

**Parameters**

.. list-table::
   :widths: 20 15 65
   :header-rows: 1

   * - Parameter
     - Type
     - Description
   * - ``fcmToken``
     - String
     - Firebase Cloud Messaging token from FirebaseMessaging.getToken()
   * - ``platform``
     - Platform
     - Device platform: ``android`` (default), ``ios``, or ``web``
   * - ``deviceName``
     - String?
     - Optional label for the device (e.g. "John's iPhone")

**Example**

.. code-block:: dart

    final fcmToken = await FirebaseMessaging.instance.getToken();
    await client.devices.register(
      fcmToken: fcmToken!,
      platform: Platform.android,
      deviceName: 'My Phone',
    );

----

unregister
~~~~~~~~~~

Unregister a device so it no longer receives push notifications. Call this on logout.

**Signature**

.. code-block:: dart

    Future<Map<String, dynamic>> unregister(String fcmToken)

**Parameters**

.. list-table::
   :widths: 20 15 65
   :header-rows: 1

   * - Parameter
     - Type
     - Description
   * - ``fcmToken``
     - String
     - The FCM token of the device to unregister

**Example**

.. code-block:: dart

    await client.devices.unregister(fcmToken);

----

listDevices
~~~~~~~~~~~

List all devices registered by the current user.

**Signature**

.. code-block:: dart

    Future<List<Map<String, dynamic>>> listDevices()

**Returns**

A list of device objects, each containing ``device_id``, ``platform``, ``device_name``, and ``registered_at``.

**Example**

.. code-block:: dart

    final devices = await client.devices.listDevices();
    for (final device in devices) {
      print('${device["device_name"]} - ${device["platform"]}');
    }

----

revokeDevice
~~~~~~~~~~~~

Revoke access for a specific registered device by its ID.

**Signature**

.. code-block:: dart

    Future<Map<String, dynamic>> revokeDevice(String deviceId)

**Parameters**

.. list-table::
   :widths: 20 15 65
   :header-rows: 1

   * - Parameter
     - Type
     - Description
   * - ``deviceId``
     - String
     - The unique device ID returned from ``listDevices()``

**Example**

.. code-block:: dart

    await client.devices.revokeDevice('device_id_here');
