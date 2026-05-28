import '../core/client.dart';

/// Presence Service - User presence and online status
class Presence {
  final NexaconClient _client;

  Presence(this._client);

  /// Get the last seen / presence for a user
  Future<Map<String, dynamic>> get([String? user]) async {
    final params = <String, dynamic>{};
    if (user != null) params['user'] = user;

    return _client.request('GET', '/nx/presence/', params: params);
  }
}
