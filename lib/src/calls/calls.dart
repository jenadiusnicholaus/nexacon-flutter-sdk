import '../core/client.dart';
import '../core/exceptions.dart';

/// Call types enum
enum CallType { audio, video, p2p, group }

/// Call analytics status enum
enum CallAnalyticsStatus {
  initiated,
  calling,
  answered,
  declined,
  cancelled,
  missed,
  ended,
  failed,
}

/// Calls Service
class Calls {
  final NexaconClient _client;

  Calls(this._client);

  /// Initiate a 1:1 call
  Future<Map<String, dynamic>> initiateCall({
    required String to,
    CallType callType = CallType.video,
    String? room,
  }) async {
    if (to.isEmpty) {
      throw ValidationException('Recipient is required');
    }

    final data = <String, dynamic>{
      'to': to,
      'type': callType.name,
    };

    if (room != null) {
      data['room'] = room;
    }

    return _client.request('POST', '/nx/call/', data: data);
  }

  /// Initiate a group call
  Future<Map<String, dynamic>> initiateGroupCall({
    required List<String> participants,
    CallType callType = CallType.video,
    String? room,
  }) async {
    if (participants.isEmpty) {
      throw ValidationException('At least one participant is required');
    }

    final data = <String, dynamic>{
      'participants': participants,
      'type': callType.name,
    };

    if (room != null) {
      data['room'] = room;
    }

    return _client.request('POST', '/nx/group-call/', data: data);
  }

  /// Get a pre-signed call URL for mobile apps
  Future<String> getCallUrl({
    required String to,
    CallType callType = CallType.video,
    String? room,
  }) async {
    if (to.isEmpty) {
      throw ValidationException('Recipient is required');
    }

    final data = <String, dynamic>{
      'to': to,
      'type': callType.name,
    };

    if (room != null) {
      data['room'] = room;
    }

    final response = await _client.request('POST', '/nx/call-url/', data: data);
    return response['call_url'] ?? '';
  }

  /// Decline an incoming call
  Future<Map<String, dynamic>> declineCall(String room) async {
    if (room.isEmpty) {
      throw ValidationException('Room is required');
    }

    return _client.request('POST', '/nx/call/decline/', data: {'room': room});
  }

  /// Get TURN/STUN credentials for WebRTC P2P calls
  /// Credentials are time-limited (24h TTL). Fetch fresh credentials before each call.
  Future<Map<String, dynamic>> getWebRTCCredentials() async {
    final response = await _client.request('GET', '/nx/webrtc/credentials/');
    return response;
  }

  /// Initiate a P2P WebRTC call (sends FCM push + XMPP notification)
  Future<Map<String, dynamic>> initiateP2PCall({
    required String to,
    String? room,
  }) async {
    if (to.isEmpty) {
      throw ValidationException('Recipient is required');
    }

    final data = <String, dynamic>{
      'to': to,
      'type': 'p2p',
    };

    if (room != null) {
      data['room'] = room;
    }

    return _client.request('POST', '/nx/webrtc/call/', data: data);
  }

  /// Record a call event for analytics (ended, failed, declined, missed)
  Future<Map<String, dynamic>> recordCall({
    required String room,
    required CallType callType,
    required CallAnalyticsStatus status,
    int durationSeconds = 0,
    Map<String, dynamic>? metadata,
  }) async {
    if (room.isEmpty) {
      throw ValidationException('Room is required');
    }

    return _client.request('POST', '/nx/call-analytics/', data: {
      'room': room,
      'call_type': callType.name,
      'duration_seconds': durationSeconds,
      'status': status.name,
      'metadata': metadata ?? {},
    });
  }
}
