import '../core/client.dart';
import '../core/exceptions.dart';

/// Platform enum
enum Platform { android, ios, web }

/// Device Management Service
class Devices {
  final NexaconClient _client;

  Devices(this._client);

  /// Register a device for push notifications
  Future<Map<String, dynamic>> register({
    required String fcmToken,
    Platform platform = Platform.android,
    String? deviceName,
  }) async {
    if (fcmToken.isEmpty) {
      throw ValidationException('FCM token is required');
    }

    final data = <String, dynamic>{
      'fcm_token': fcmToken,
      'platform': platform.name,
    };

    if (deviceName != null) {
      data['device_name'] = deviceName;
    }

    return _client.request('POST', '/nx/register-device/', data: data);
  }

  /// Unregister a device from push notifications
  Future<Map<String, dynamic>> unregister(String fcmToken) async {
    if (fcmToken.isEmpty) {
      throw ValidationException('FCM token is required');
    }

    return _client.request('DELETE', '/nx/register-device/',
        data: {'fcm_token': fcmToken});
  }

  /// List all registered devices for the current user
  Future<List<Map<String, dynamic>>> listDevices() async {
    final response = await _client.request('GET', '/nx/devices/');
    return (response['devices'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  /// Revoke a specific device
  Future<Map<String, dynamic>> revokeDevice(String deviceId) async {
    if (deviceId.isEmpty) {
      throw ValidationException('Device ID is required');
    }

    return _client.request('DELETE', '/nx/devices/$deviceId/');
  }
}
