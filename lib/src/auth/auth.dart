import '../core/client.dart';
import '../core/exceptions.dart';

/// Authentication Service - NX Token Management
class Auth {
  final NexaconClient _client;

  Auth(this._client);

  /// Get NX token for ejabberd authentication (used for messaging and call signaling)
  ///
  /// Returns a Map containing:
  /// - token: The NX authentication token
  /// - jid: The user's NX network ID
  /// - nxws: The WebSocket URL for NX connection
  ///
  /// Throws [ValidationException] if username is empty
  /// Throws [APIException] if the request fails
  Future<Map<String, dynamic>> getNxToken({
    required String username,
    String host = 'nxservice.quantumvision-tech.com',
  }) async {
    // Validate input
    if (username.isEmpty) {
      print('❌ Auth Error: Username cannot be empty');
      throw ValidationException('Username is required');
    }

    if (username.trim().isEmpty) {
      print('❌ Auth Error: Username cannot be whitespace only');
      throw ValidationException('Username cannot be whitespace only');
    }

    try {
      print('🔐 Requesting NX token for user: $username');

      final response =
          await _client.request('POST', '/nexacon-auth/nxm-token/', data: {
        'username': username.trim(),
        'host': host,
      });

      // Validate response
      if (!response.containsKey('token')) {
        print('❌ Auth Error: Response missing required field: token');
        throw APIException('Response missing required field: token');
      }

      if (!response.containsKey('jid')) {
        print('❌ Auth Error: Response missing required field: jid');
        throw APIException('Response missing required field: jid');
      }

      if (!response.containsKey('nxws')) {
        print('❌ Auth Error: Response missing required field: nxws');
        throw APIException('Response missing required field: nxws');
      }

      print('✅ NX token retrieved successfully for user: $username');
      return response;
    } on ValidationException {
      rethrow;
    } on APIException {
      rethrow;
    } catch (e) {
      print('❌ Auth Error: Failed to get NX token - $e');
      throw APIException('Failed to get NX token: $e');
    }
  }

  /// Refresh NX token
  Future<Map<String, dynamic>> refreshNxToken({
    required String refreshToken,
  }) async {
    if (refreshToken.isEmpty) {
      throw ValidationException('Refresh token is required');
    }

    return _client.request('POST', '/nexacon-auth/nxm-token/refresh/', data: {
      'refresh_token': refreshToken,
    });
  }
}
