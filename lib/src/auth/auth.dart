import '../core/client.dart';
import '../core/exceptions.dart';

/// Authentication Service - NX Token Management
class Auth {
  final NexaconClient _client;

  Auth(this._client);

  /// Generate NX token for ejabberd authentication (used for messaging and call signaling)
  Future<Map<String, dynamic>> generateXMPPToken({
    required String username,
    String host = 'nxservice.quantumvision-tech.com',
  }) async {
    if (username.isEmpty) {
      throw ValidationException('Username is required');
    }

    return _client.request('POST', '/nexacon-auth/nxm-token/', data: {
      'username': username,
      'host': host,
    });
  }

  /// Refresh XMPP token
  Future<Map<String, dynamic>> refreshXMPPToken({
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
