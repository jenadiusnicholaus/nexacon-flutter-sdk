import 'dart:async';
import 'dart:convert';
import '../xmpp/xmpp_client.dart';
import 'nx_id_utils.dart';

/// Global NX connection manager (internal)
/// Maintains a single NX connection for both chat and call signaling
class NxConnectionManager {
  XmppClient? _client;
  String? _nxid;
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

  /// Current NX ID
  String? get nxid => _nxid;

  /// Initialize and connect to NX server
  Future<bool> connect({
    required String nxid,
    required String password,
    required String wsUrl,
  }) async {
    if (_isConnected && _nxid == nxid) {
      return true; // Already connected with same credentials
    }

    // Disconnect existing connection if credentials changed
    if (_isConnected) {
      await disconnect();
    }

    _nxid = nxid;

    _client = XmppClient();
    final connected = await _client!.connect(
      jid: nxid,
      password: password,
      wsUrl: wsUrl,
    );

    if (connected) {
      _isConnected = true;
      _reconnectAttempts = 0;
      _reconnectTimer?.cancel();
      _connectionStateController.add(true);

      // Listen for incoming messages
      _client!.messageStream.listen((message) {
        if (message.body != null) {
          try {
            final data = jsonDecode(message.body!);
            print(
                '📥 NxConnection received message: type=${data['type']}, from=${message.from}');

            // Route to appropriate stream based on message type
            if (data['type'] != null && _isSignalingMessage(data['type'])) {
              // Inject normalized sender NX ID so CallManager routes responses correctly
              if (message.from != null) {
                data['fromNxId'] = NxIdUtils.bare(message.from!);
              }
              print('📥 NxConnection routing to signaling stream');
              _signalingController.add(data);
            } else {
              print('📥 NxConnection routing to message stream');
              _messageController.add(data);
            }
          } catch (e) {
            // If not JSON, check if it's a Nexacon plain-text call URL
            // e.g. "Incoming p2p call. Click to join: https://...?room=call_xxx&caller=7888111189&..."
            final body = message.body ?? '';
            if (body.contains('/nexacon-call.html') ||
                body.contains('room=call_')) {
              try {
                // Extract the URL part
                final urlMatch = RegExp(r'https://\S+').firstMatch(body);
                if (urlMatch != null) {
                  final uri = Uri.tryParse(urlMatch.group(0)!);
                  if (uri != null) {
                    final roomId = uri.queryParameters['room'];
                    final callerNum = uri.queryParameters['caller'];
                    if (roomId != null && callerNum != null) {
                      final domain = _nxid?.split('@').length == 2
                          ? _nxid!.split('@')[1]
                          : 'nxservice.quantumvision-tech.com';
                      final callerNxId = callerNum.contains('@')
                          ? callerNum
                          : '$callerNum@$domain';
                      _signalingController.add({
                        'type': 'call_invitation',
                        'roomId': roomId,
                        'callType': uri.queryParameters['type'] ?? 'audio',
                        'fromNxId': message.from ?? callerNxId,
                        'fromName': callerNum,
                        'timestamp': DateTime.now().millisecondsSinceEpoch,
                      });
                      return;
                    }
                  }
                }
              } catch (_) {}
            }
            // Generic plain text message
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
      _client!.presenceStream.listen((presence) {
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
      'call_accepted',
      'call_end',
      'webrtc_offer',
      'webrtc_answer',
      'webrtc_ice_candidate',
    };
    return signalingTypes.contains(type);
  }

  /// Send a message to a specific NX ID
  void sendMessage(String to, String message) {
    if (!_isConnected || _client == null) {
      throw Exception('NX not connected');
    }
    final formattedTo = NxIdUtils.bare(to);
    print('📤 NxConnection: sending to $formattedTo (from: $to)');
    _client!.sendMessage(formattedTo, message);
  }

  /// Disconnect from NX server
  Future<void> disconnect() async {
    if (_client != null) {
      _client!.disconnect();
      _client!.dispose();
      _client = null;
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
      if (_isConnected && _client != null) {
        _client!.sendPresence();
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
      if (!_isConnected && _nxid != null) {
        // Note: Would need stored password/wsUrl for full reconnect
        // For now, just reset attempts
        _reconnectAttempts = 0;
      }
    });
  }
}
