/// Messaging models for API responses

/// Message history response from /nx/history/ endpoint
class MessageHistoryResponse {
  final String status;
  final int total;
  final int limit;
  final int offset;
  final int? nextOffset;
  final int? prevOffset;
  final bool hasNext;
  final bool hasPrev;
  final List<NexaconMessage> messages;

  MessageHistoryResponse({
    required this.status,
    required this.total,
    required this.limit,
    required this.offset,
    this.nextOffset,
    this.prevOffset,
    required this.hasNext,
    required this.hasPrev,
    required this.messages,
  });

  factory MessageHistoryResponse.fromJson(Map<String, dynamic> json) {
    final messagesList = json['messages'];
    List<NexaconMessage> parsedMessages = [];

    if (messagesList is List) {
      for (var item in messagesList) {
        if (item is Map<String, dynamic>) {
          try {
            parsedMessages.add(NexaconMessage.fromJson(item));
          } catch (e) {
            print('⚠️ Failed to parse message: $e, item: $item');
          }
        }
      }
    } else {
      print(
          '⚠️ messages is not a List: ${messagesList.runtimeType}, value: $messagesList');
    }

    return MessageHistoryResponse(
      status: json['status']?.toString() ?? 'unknown',
      total: json['total'] is int
          ? json['total'] as int
          : int.tryParse(json['total']?.toString() ?? '0') ?? 0,
      limit: json['limit'] is int
          ? json['limit'] as int
          : int.tryParse(json['limit']?.toString() ?? '20') ?? 20,
      offset: json['offset'] is int
          ? json['offset'] as int
          : int.tryParse(json['offset']?.toString() ?? '0') ?? 0,
      nextOffset:
          json['next_offset'] is int ? json['next_offset'] as int : null,
      prevOffset:
          json['prev_offset'] is int ? json['prev_offset'] as int : null,
      hasNext: json['has_next'] is bool ? json['has_next'] as bool : false,
      hasPrev: json['has_prev'] is bool ? json['has_prev'] as bool : false,
      messages: parsedMessages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'total': total,
      'limit': limit,
      'offset': offset,
      'next_offset': nextOffset,
      'prev_offset': prevOffset,
      'has_next': hasNext,
      'has_prev': hasPrev,
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }
}

/// Individual message from history
class NexaconMessage {
  final String id;
  final String from;
  final String to;
  final String body;
  final int timestamp;
  final String type;
  final String? originId;

  NexaconMessage({
    required this.id,
    required this.from,
    required this.to,
    required this.body,
    required this.timestamp,
    required this.type,
    this.originId,
  });

  factory NexaconMessage.fromJson(Map<String, dynamic> json) {
    return NexaconMessage(
      id: json['id']?.toString() ?? '',
      from: json['from']?.toString() ?? '',
      to: json['to']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      timestamp: json['timestamp'] is int
          ? json['timestamp'] as int
          : int.tryParse(json['timestamp']?.toString() ?? '0') ?? 0,
      type: json['type']?.toString() ?? 'chat',
      originId: json['origin_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from': from,
      'to': to,
      'body': body,
      'timestamp': timestamp,
      'type': type,
      'origin_id': originId,
    };
  }

  /// Check if message body contains call-related content
  bool get isCallMessage {
    try {
      // Check for "Incoming p2p call" link format
      if (body.contains('Incoming p2p call') ||
          body.contains('Click to join:') ||
          body.contains('custom-call-interfaces')) {
        return true;
      }

      // Check for JSON call messages
      if (body.startsWith('{') && body.endsWith('}')) {
        return body.contains('call_') ||
            body.contains('callType') ||
            body.contains('roomId');
      }
    } catch (e) {
      // If parsing fails, treat as regular message
    }
    return false;
  }

  /// Extract call type if this is a call message
  String? get callType {
    if (!isCallMessage) return null;

    // Check for link-based call invitation
    if (body.contains('Incoming p2p call')) {
      if (body.contains('type=audio')) return 'audio_invitation';
      if (body.contains('type=video')) return 'video_invitation';
      return 'invitation';
    }

    // Check for JSON-based call events
    if (body.contains('call_invitation')) return 'invitation';
    if (body.contains('call_end') || body.contains('Call ended')) return 'end';
    if (body.contains('call_response')) return 'response';
    if (body.contains('webrtc_offer')) return 'offer';
    if (body.contains('webrtc_ice_candidate')) return 'ice_candidate';
    return null;
  }

  /// Get display text for the message (hides call technical details)
  String get displayText {
    if (isCallMessage) {
      final type = callType;
      switch (type) {
        case 'audio_invitation':
          return '📞 Audio call invitation';
        case 'video_invitation':
          return '📹 Video call invitation';
        case 'invitation':
          return '📞 Call invitation';
        case 'end':
          return '📞 Call ended';
        case 'response':
          return '📞 Call accepted';
        default:
          return '📞 Call event';
      }
    }
    return body;
  }
}
