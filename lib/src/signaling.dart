import 'dart:convert';

/// Signaling message types for XMPP communication
enum SignalingMessageType {
  callInvitation,
  callResponse,
  callEnd,
  webrtcOffer,
  webrtcAnswer,
  webrtcIceCandidate,
}

/// Signaling message data structure
class SignalingMessage {
  final SignalingMessageType type;
  final Map<String, dynamic> data;

  SignalingMessage({required this.type, required this.data});

  factory SignalingMessage.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    SignalingMessageType type;

    switch (typeStr) {
      case 'call_invitation':
        type = SignalingMessageType.callInvitation;
        break;
      case 'call_response':
        type = SignalingMessageType.callResponse;
        break;
      case 'call_end':
        type = SignalingMessageType.callEnd;
        break;
      case 'webrtc_offer':
        type = SignalingMessageType.webrtcOffer;
        break;
      case 'webrtc_answer':
        type = SignalingMessageType.webrtcAnswer;
        break;
      case 'webrtc_ice_candidate':
        type = SignalingMessageType.webrtcIceCandidate;
        break;
      default:
        throw ArgumentError('Unknown signaling message type: $typeStr');
    }

    return SignalingMessage(type: type, data: json);
  }

  Map<String, dynamic> toJson() {
    final json = Map<String, dynamic>.from(data);
    json['type'] = _typeToString(type);
    return json;
  }

  String _typeToString(SignalingMessageType type) {
    switch (type) {
      case SignalingMessageType.callInvitation:
        return 'call_invitation';
      case SignalingMessageType.callResponse:
        return 'call_response';
      case SignalingMessageType.callEnd:
        return 'call_end';
      case SignalingMessageType.webrtcOffer:
        return 'webrtc_offer';
      case SignalingMessageType.webrtcAnswer:
        return 'webrtc_answer';
      case SignalingMessageType.webrtcIceCandidate:
        return 'webrtc_ice_candidate';
    }
  }

  String toJsonString() => jsonEncode(toJson());
}

/// Signaling Service - Handles XMPP signaling messages
/// Note: This is a stub implementation. Users need to integrate
/// their own XMPP client (e.g., xmpp_stone, smack, etc.)
class SignalingService {
  final Function(SignalingMessage)? onMessageReceived;
  final Function(String)? onSendMessage;

  SignalingService({
    this.onMessageReceived,
    this.onSendMessage,
  });

  /// Send a signaling message via XMPP
  void sendMessage(SignalingMessage message) {
    final jsonStr = message.toJsonString();
    onSendMessage?.call(jsonStr);
  }

  /// Handle incoming XMPP message
  void handleIncomingMessage(String jsonStr) {
    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final message = SignalingMessage.fromJson(json);
      onMessageReceived?.call(message);
    } catch (e) {
      // Invalid message format
      print('Error parsing signaling message: $e');
    }
  }

  /// Create call invitation message
  SignalingMessage createCallInvitation({
    required String roomId,
    required String callType,
    required String fromJid,
    required String fromName,
  }) {
    return SignalingMessage(
      type: SignalingMessageType.callInvitation,
      data: {
        'roomId': roomId,
        'callType': callType,
        'fromJid': fromJid,
        'fromName': fromName,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// Create call response message
  SignalingMessage createCallResponse({
    required String roomId,
    required bool accepted,
  }) {
    return SignalingMessage(
      type: SignalingMessageType.callResponse,
      data: {
        'roomId': roomId,
        'accepted': accepted,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// Create call end message
  SignalingMessage createCallEnd({
    required String roomId,
  }) {
    return SignalingMessage(
      type: SignalingMessageType.callEnd,
      data: {
        'roomId': roomId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// Create WebRTC offer message
  SignalingMessage createWebRTCOffer({
    required String roomId,
    required String sdp,
    required String sdpType,
  }) {
    return SignalingMessage(
      type: SignalingMessageType.webrtcOffer,
      data: {
        'roomId': roomId,
        'sdp': sdp,
        'sdp_type': sdpType,
      },
    );
  }

  /// Create WebRTC answer message
  SignalingMessage createWebRTCAnswer({
    required String roomId,
    required String sdp,
    required String sdpType,
  }) {
    return SignalingMessage(
      type: SignalingMessageType.webrtcAnswer,
      data: {
        'roomId': roomId,
        'sdp': sdp,
        'sdp_type': sdpType,
      },
    );
  }

  /// Create WebRTC ICE candidate message
  SignalingMessage createIceCandidate({
    required String roomId,
    required String candidate,
    required String? sdpMid,
    required int? sdpMLineIndex,
  }) {
    return SignalingMessage(
      type: SignalingMessageType.webrtcIceCandidate,
      data: {
        'roomId': roomId,
        'candidate': candidate,
        'sdpMid': sdpMid,
        'sdpMLineIndex': sdpMLineIndex,
      },
    );
  }
}
