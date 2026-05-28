import '../core/client.dart';
import '../core/exceptions.dart';

/// Rooms Service - Group chat room management
class Rooms {
  final NexaconClient _client;

  Rooms(this._client);

  /// List all rooms for the current user
  Future<Map<String, dynamic>> list() async {
    return _client.request('GET', '/nx/rooms/');
  }

  /// Create a new group chat room
  Future<Map<String, dynamic>> create({
    String? name,
    String? title,
    String description = '',
    String avatarUrl = '',
  }) async {
    if (name == null && title == null) {
      throw ValidationException('Either name or title is required');
    }

    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (title != null) data['title'] = title;
    if (description.isNotEmpty) data['description'] = description;
    if (avatarUrl.isNotEmpty) data['avatar_url'] = avatarUrl;

    return _client.request('POST', '/nx/rooms/', data: data);
  }

  /// Get room details and members
  Future<Map<String, dynamic>> get(String name) async {
    if (name.isEmpty) {
      throw ValidationException('Room name is required');
    }

    return _client.request('GET', '/nx/rooms/$name/');
  }

  /// Destroy a room
  Future<Map<String, dynamic>> destroy(String name) async {
    if (name.isEmpty) {
      throw ValidationException('Room name is required');
    }

    return _client.request('DELETE', '/nx/rooms/$name/');
  }

  /// Add a member to a room with specified affiliation
  Future<Map<String, dynamic>> addMember({
    required String name,
    required String nxid,
    String affiliation = 'member',
  }) async {
    if (name.isEmpty) {
      throw ValidationException('Room name is required');
    }
    if (nxid.isEmpty) {
      throw ValidationException('nxid is required');
    }

    final data = <String, dynamic>{
      'nxid': nxid,
      'affiliation': affiliation,
    };

    return _client.request('POST', '/nx/rooms/$name/members/', data: data);
  }

  /// Remove a member from a room
  Future<Map<String, dynamic>> removeMember({
    required String name,
    required String nxid,
  }) async {
    if (name.isEmpty) {
      throw ValidationException('Room name is required');
    }
    if (nxid.isEmpty) {
      throw ValidationException('nxid is required');
    }

    return _client.request('DELETE', '/nx/rooms/$name/members/$nxid/');
  }
}
