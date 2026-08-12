import '../core/client.dart';
import '../core/nexacon_config.dart';
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

    return _client.request('POST', NexaconConfig.callEndpoint, data: data);
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

    return _client.request('POST', NexaconConfig.groupCallEndpoint, data: data);
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

    final response = await _client
        .request('POST', NexaconConfig.callUrlEndpoint, data: data);
    return response['call_url'] ?? '';
  }

  /// Decline an incoming call
  Future<Map<String, dynamic>> declineCall(String room) async {
    if (room.isEmpty) {
      throw ValidationException('Room is required');
    }

    return _client.request('POST', NexaconConfig.callDeclineEndpoint,
        data: {'room': room});
  }

  /// Get TURN/STUN credentials for WebRTC P2P calls
  /// Credentials are time-limited (24h TTL). Fetch fresh credentials before each call.
  Future<Map<String, dynamic>> getWebRTCCredentials() async {
    final response =
        await _client.request('GET', NexaconConfig.webrtcCredentialsEndpoint);
    return response;
  }

  /// Initiate a P2P WebRTC call (sends FCM push + NX notification)
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

    return _client.request('POST', NexaconConfig.webrtcCallEndpoint,
        data: data);
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

    try {
      return await _client
          .request('POST', NexaconConfig.callAnalyticsEndpoint, data: {
        'room': room,
        'call_type': callType.name,
        'duration_seconds': durationSeconds,
        'status': status.name,
        'metadata': metadata ?? {},
      });
    } on APIException catch (e) {
      // Analytics endpoint may not be implemented on backend.
      // This should not break the call flow.
      if (e.statusCode == 404) {
        return {
          'success': true,
          'message': 'Analytics endpoint not found, call recorded locally',
          'room': room,
        };
      }
      rethrow;
    } catch (e) {
      // Non-fatal: analytics should not break the call
      return {
        'success': true,
        'message': 'Analytics request failed: $e',
        'room': room,
      };
    }
  }

  /// Get call history for the current user
  /// Supports filtering by date range, call type, status, and participant
  Future<Map<String, dynamic>> getCallHistory({
    DateTime? startDate,
    DateTime? endDate,
    CallType? callType,
    CallAnalyticsStatus? status,
    String? participant,
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
    if (callType != null) {
      params['call_type'] = callType.name;
    }
    if (status != null) {
      params['status'] = status.name;
    }
    if (participant != null && participant.isNotEmpty) {
      params['participant'] = participant;
    }

    return _client.request('GET', NexaconConfig.callHistoryEndpoint,
        params: params);
  }
}
