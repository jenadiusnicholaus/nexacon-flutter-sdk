import '../core/client.dart';
import '../core/exceptions.dart';

/// Messaging Service
class Messaging {
  final NexaconClient _client;

  Messaging(this._client);

  /// Send a message to a user
  Future<Map<String, dynamic>> send({
    required String to,
    required String message,
    String messageType = 'chat',
  }) async {
    if (to.isEmpty || message.isEmpty) {
      throw ValidationException('Recipient and message are required');
    }

    return _client.request('POST', '/nx/message/', data: {
      'to': to,
      'message': message,
      'type': messageType,
    });
  }

  /// Broadcast a message to multiple recipients
  Future<Map<String, dynamic>> broadcast({
    required String message,
    required List<String> recipients,
  }) async {
    if (message.isEmpty || recipients.isEmpty) {
      throw ValidationException('Message and recipients are required');
    }

    return _client.request('POST', '/nx/broadcast/', data: {
      'message': message,
      'recipients': recipients,
    });
  }

  /// Get user's contact list
  Future<List<Map<String, dynamic>>> getContacts() async {
    final response = await _client.request('GET', '/nx/contacts/');
    return (response['contacts'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  /// Add a user to contacts
  Future<Map<String, dynamic>> addContact(String nxid) async {
    if (nxid.isEmpty) {
      throw ValidationException('nxid is required');
    }

    return _client.request('POST', '/nx/contacts/', data: {'nxid': nxid});
  }

  /// Remove a user from contacts
  Future<Map<String, dynamic>> removeContact(String nxid) async {
    if (nxid.isEmpty) {
      throw ValidationException('nxid is required');
    }

    return _client.request('DELETE', '/nx/contacts/$nxid/');
  }

  /// Get message history for the current user
  /// Supports filtering by date range, sender, and message type
  Future<Map<String, dynamic>> getMessageHistory({
    DateTime? startDate,
    DateTime? endDate,
    String? sender,
    String? messageType,
    int page = 1,
    int pageSize = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };

    if (startDate != null) {
      params['start_date'] =
          '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    }
    if (endDate != null) {
      params['end_date'] =
          '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
    }
    if (sender != null && sender.isNotEmpty) {
      params['sender'] = sender;
    }
    if (messageType != null && messageType.isNotEmpty) {
      params['message_type'] = messageType;
    }

    return _client.request('GET', '/nx/history/', params: params);
  }
}
