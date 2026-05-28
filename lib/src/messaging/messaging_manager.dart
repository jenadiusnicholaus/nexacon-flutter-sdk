import 'dart:async';
import 'dart:convert';
import '../core/xmpp_manager.dart';

/// Real-time messaging manager
/// Uses global XMPP connection for instant messaging
class MessagingManager {
  final XmppManager _xmppManager;

  // Stream for incoming chat messages
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of incoming chat messages
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  MessagingManager(this._xmppManager) {
    // Subscribe to XMPP message stream
    _xmppManager.messageStream.listen((data) {
      _messageController.add(data);
    });
  }

  /// Send a real-time message to a user
  void sendMessage({
    required String to,
    required String message,
    String messageType = 'chat',
  }) {
    final payload = jsonEncode({
      'type': messageType,
      'message': message,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    _xmppManager.sendMessage(to, payload);
  }

  /// Send a typing indicator
  void sendTypingIndicator(String to, {bool isTyping = true}) {
    final payload = jsonEncode({
      'type': 'typing',
      'is_typing': isTyping,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    _xmppManager.sendMessage(to, payload);
  }

  /// Send a read receipt
  void sendReadReceipt(String to, String messageId) {
    final payload = jsonEncode({
      'type': 'read_receipt',
      'message_id': messageId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    _xmppManager.sendMessage(to, payload);
  }

  /// Cleanup
  void dispose() {
    _messageController.close();
  }
}
