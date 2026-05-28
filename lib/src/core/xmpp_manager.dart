import 'dart:async';
import 'dart:convert';
import '../xmpp/xmpp_client.dart';

/// Global XMPP connection manager
/// Maintains a single XMPP connection for both chat and call signaling
class XmppManager {
  XmppClient? _xmppClient;
  String? _jid;
  bool _isConnected = false;

  // Streams
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _signalingController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();

  /// Stream for chat messages
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  /// Stream for call signaling messages
  Stream<Map<String, dynamic>> get signalingStream =>
      _signalingController.stream;

  /// Stream for connection state changes
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  /// Current connection state
  bool get isConnected => _isConnected;

  /// Initialize and connect to XMPP server
  Future<bool> connect({
    required String jid,
    required String password,
    required String wsUrl,
  }) async {
    if (_isConnected && _jid == jid) {
      return true; // Already connected with same credentials
    }

    // Disconnect existing connection if credentials changed
    if (_isConnected) {
      await disconnect();
    }

    _jid = jid;

    _xmppClient = XmppClient();
    final connected = await _xmppClient!.connect(
      jid: jid,
      password: password,
      wsUrl: wsUrl,
    );

    if (connected) {
      _isConnected = true;
      _connectionStateController.add(true);

      // Listen for incoming messages
      _xmppClient!.messageStream.listen((message) {
        if (message.body != null) {
          try {
            final data = jsonDecode(message.body!);

            // Route to appropriate stream based on message type
            if (data['type'] != null && _isSignalingMessage(data['type'])) {
              _signalingController.add(data);
            } else {
              _messageController.add(data);
            }
          } catch (e) {
            print('Error parsing XMPP message: $e');
          }
        }
      });
    }

    return connected;
  }

  /// Check if a message type is a signaling message
  bool _isSignalingMessage(String type) {
    const signalingTypes = {
      'call_invitation',
      'call_response',
      'call_end',
      'webrtc_offer',
      'webrtc_answer',
      'webrtc_ice_candidate',
    };
    return signalingTypes.contains(type);
  }

  /// Send a message to a specific JID
  void sendMessage(String to, String message) {
    if (!_isConnected || _xmppClient == null) {
      throw Exception('XMPP not connected');
    }
    _xmppClient!.sendMessage(to, message);
  }

  /// Disconnect from XMPP server
  Future<void> disconnect() async {
    if (_xmppClient != null) {
      _xmppClient!.disconnect();
      _xmppClient!.dispose();
      _xmppClient = null;
    }
    _isConnected = false;
    _connectionStateController.add(false);
  }

  /// Cleanup resources
  void dispose() {
    disconnect();
    _messageController.close();
    _signalingController.close();
    _connectionStateController.close();
  }
}
