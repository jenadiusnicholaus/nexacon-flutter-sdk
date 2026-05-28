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
  final _presenceController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _deliveryReceiptController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Reconnection
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  // Heartbeat
  Timer? _heartbeatTimer;

  /// Stream for chat messages
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  /// Stream for call signaling messages
  Stream<Map<String, dynamic>> get signalingStream =>
      _signalingController.stream;

  /// Stream for connection state changes
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  /// Stream for presence changes (online/offline, typing)
  Stream<Map<String, dynamic>> get presenceStream => _presenceController.stream;

  /// Stream for delivery receipts
  Stream<Map<String, dynamic>> get deliveryReceiptStream =>
      _deliveryReceiptController.stream;

  /// Current connection state
  bool get isConnected => _isConnected;

  /// Current JID
  String? get jid => _jid;

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
      _reconnectAttempts = 0;
      _reconnectTimer?.cancel();
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
            // If not JSON, treat as plain text message
            _messageController.add({
              'message': message.body,
              'from': message.from,
              'to': message.to,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            });
          }
        }
      });

      // Listen for presence changes
      _xmppClient!.presenceStream.listen((presence) {
        _presenceController.add({
          'from': presence.from,
          'type': presence.type,
          'show': presence.show,
        });
      });

      // Start heartbeat
      _startHeartbeat();
    } else {
      // Schedule reconnect on failure
      _scheduleReconnect();
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
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    disconnect();
    _messageController.close();
    _signalingController.close();
    _connectionStateController.close();
    _presenceController.close();
    _deliveryReceiptController.close();
  }

  /// Start heartbeat to keep connection alive
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected && _xmppClient != null) {
        _xmppClient!.sendPresence();
      }
    });
  }

  /// Schedule reconnection with exponential backoff
  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive == true) return;
    _reconnectAttempts++;
    if (_reconnectAttempts > 10) {
      print('Max reconnect attempts reached');
      _reconnectAttempts = 0;
      return;
    }
    final delaySec = 5 * (1 << (_reconnectAttempts - 1)); // Exponential backoff
    print('Reconnecting in ${delaySec}s (attempt $_reconnectAttempts)');
    _reconnectTimer = Timer(Duration(seconds: delaySec), () async {
      if (!_isConnected && _jid != null) {
        // Note: Would need stored password/wsUrl for full reconnect
        // For now, just reset attempts
        _reconnectAttempts = 0;
      }
    });
  }
}
