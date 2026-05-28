// ignore_for_file: unused_field

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' hide log;
import 'package:web_socket_client/web_socket_client.dart' as ws_client;

/// Connection states for the WebSocket XMPP client
enum XmppState {
  disconnected,
  connecting,
  connected,
  authenticating,
  authenticated,
  failed,
}

/// Represents an incoming XMPP message
class XmppMessage {
  final String? id;
  final String? from;
  final String? to;
  final String? body;
  final String? type;
  final int timestamp;

  XmppMessage({
    this.id,
    this.from,
    this.to,
    this.body,
    this.type,
    required this.timestamp,
  });
}

/// Represents a presence update
class XmppPresence {
  final String? from;
  final String? type;
  final String? show;

  XmppPresence({this.from, this.type, this.show});
}

/// Pure Dart WebSocket-based client.
/// Connects via wss:// for real-time communication.
class XmppClient {
  ws_client.WebSocket? _socket;
  XmppState _state = XmppState.disconnected;
  String? _jid;
  String? _password;
  String? _wsUrl;
  String? _domain;
  String? _resource;
  String? _boundJid;

  // Stream controllers for events
  final _messageController = StreamController<XmppMessage>.broadcast();
  final _presenceController = StreamController<XmppPresence>.broadcast();
  final _stateController = StreamController<XmppState>.broadcast();

  // Subscriptions
  StreamSubscription? _messageSub;
  StreamSubscription? _connectionSub;

  // Ping
  Timer? _pingTimer;
  bool _intentionalDisconnect = false;

  // Stanza buffer for building multi-frame stanzas
  StringBuffer _stanzaBuffer = StringBuffer();
  bool _streamOpened = false;
  Completer<bool>? _authCompleter;

  // Public getters
  XmppState get state => _state;
  bool get isAuthenticated => _state == XmppState.authenticated;
  bool get isConnected =>
      _state == XmppState.authenticated || _state == XmppState.connected;
  String? get boundJid => _boundJid;
  Stream<XmppMessage> get messageStream => _messageController.stream;
  Stream<XmppPresence> get presenceStream => _presenceController.stream;
  Stream<XmppState> get stateStream => _stateController.stream;

  /// Connect to the XMPP server via WebSocket
  Future<bool> connect({
    required String jid,
    required String password,
    required String wsUrl,
    String? resource,
  }) async {
    _jid = jid;
    _password = password;
    _wsUrl = wsUrl;
    _resource = resource ?? '';
    _domain = jid.contains('@')
        ? jid.split('@')[1]
        : 'nxservice.quantumvision-tech.com';
    _intentionalDisconnect = false;

    _setState(XmppState.connecting);
    log('🔌 XmppClient: Connecting to $wsUrl as $jid');

    try {
      // Create WebSocket with built-in reconnection backoff
      _socket = ws_client.WebSocket(
        Uri.parse(wsUrl),
        protocols: ['xmpp'],
        timeout: const Duration(seconds: 15),
        backoff: ws_client.LinearBackoff(
          initial: Duration(seconds: 1),
          increment: Duration(seconds: 2),
          maximum: Duration(seconds: 30),
        ),
      );

      _authCompleter = Completer<bool>();

      // Listen to incoming messages
      _messageSub = _socket!.messages.listen(
        _onData,
        onError: _onError,
        cancelOnError: false,
      );

      // Monitor connection state for reconnects
      _connectionSub = _socket!.connection.listen(_onConnectionState);

      // Wait for Connected state, then send stream open
      await _socket!.connection
          .firstWhere(
        (s) => s is ws_client.Connected || s is ws_client.Disconnected,
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('WebSocket connection timed out');
        },
      );

      final connState = _socket!.connection.state;
      if (connState is ws_client.Disconnected) {
        throw Exception('WebSocket failed to connect');
      }

      // Send XMPP stream open (RFC 7395)
      _sendStreamOpen();

      // Wait for authentication to complete
      final authenticated = await _authCompleter!.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          log('❌ XmppClient: Authentication timed out');
          _setState(XmppState.failed);
          return false;
        },
      );

      if (authenticated) {
        _startPing();
      }

      return authenticated;
    } catch (e) {
      log('❌ XmppClient: Connection error: $e');
      _setState(XmppState.failed);
      _authCompleter?.complete(false);
      return false;
    }
  }

  void _onConnectionState(ws_client.ConnectionState state) {
    log('🔌 XmppClient connection state: $state');
    if (state is ws_client.Reconnected) {
      if (_intentionalDisconnect) {
        log('🚫 XmppClient: Ignoring reconnect — intentionally disconnected');
        _socket?.close(1000, 'Intentional disconnect');
        return;
      }
      log('🔄 XmppClient: Reconnected — re-opening XMPP stream');
      _streamOpened = false;
      _setState(XmppState.connecting);
      _authCompleter = Completer<bool>();
      _sendStreamOpen();
    } else if (state is ws_client.Disconnected) {
      if (!_intentionalDisconnect) {
        _setState(XmppState.disconnected);
      }
    }
  }

  /// Disconnect from the XMPP server
  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    _pingTimer?.cancel();
    _messageSub?.cancel();
    _connectionSub?.cancel();

    if (_socket != null && _streamOpened) {
      try {
        _send('<close xmlns="urn:ietf:params:xml:ns:xmpp-framing"/>');
      } catch (_) {}
    }

    _socket?.close(1000, 'Normal closure');
    _socket = null;
    _streamOpened = false;
    _setState(XmppState.disconnected);
    log('✅ XmppClient: Disconnected');
  }

  /// Send a chat message
  Future<void> sendMessage(String to, String body, {String? id}) async {
    if (!isAuthenticated) {
      throw Exception('Not authenticated');
    }

    final msgId = id ??
        'msg_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
    final stanza =
        '<message type="chat" to="${_escapeXml(to)}" id="$msgId" from="${_escapeXml(_boundJid ?? _jid!)}">'
        '<body>${_escapeXml(body)}</body>'
        '<request xmlns="urn:xmpp:receipts"/>'
        '</message>';

    _send(stanza);
    log('📤 XmppClient: Sent message to $to: $body');
  }

  /// Send presence
  Future<void> sendPresence({String? type, String? show}) async {
    if (!isAuthenticated) return;

    String stanza = '<presence';
    if (type != null) stanza += ' type="$type"';
    stanza += '>';
    if (show != null) stanza += '<show>$show</show>';
    stanza += '</presence>';

    _send(stanza);
  }

  /// Reconnect using stored credentials
  Future<bool> reconnect() async {
    if (_jid == null || _password == null || _wsUrl == null) return false;
    return connect(
      jid: _jid!,
      password: _password!,
      wsUrl: _wsUrl!,
      resource: _resource,
    );
  }

  /// Clean up resources
  void dispose() {
    _intentionalDisconnect = true;
    _pingTimer?.cancel();
    _messageSub?.cancel();
    _connectionSub?.cancel();
    _socket?.close(1000, 'Disposing');
    _messageController.close();
    _presenceController.close();
    _stateController.close();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Private methods
  // ──────────────────────────────────────────────────────────────────────────

  void _setState(XmppState newState) {
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }

  void _send(String data) {
    if (_socket == null) {
      log('⚠️ XmppClient: Cannot send, socket is null');
      return;
    }
    try {
      _socket!.send(data);
    } catch (e) {
      log('⚠️ XmppClient: Cannot send: $e');
    }
  }

  void _sendStreamOpen() {
    // RFC 7395: XMPP over WebSocket uses <open> frame
    final open = '<open xmlns="urn:ietf:params:xml:ns:xmpp-framing" '
        'to="$_domain" '
        'version="1.0"/>';
    _send(open);
    log('📡 XmppClient: Sent stream open to $_domain');
  }

  void _onData(dynamic data) {
    final text = data.toString();
    log(
      '📨 XmppClient raw: ${text.length > 2000 ? text.substring(0, 2000) + "..." : text}',
    );

    // Handle different XMPP stream frames
    if (text.contains('<open ') || text.contains('<stream:stream')) {
      _streamOpened = true;
      _setState(XmppState.connected);
      log('✅ XmppClient: Stream opened');
      return;
    }

    if (text.contains('</stream:stream') || text.contains('<close ')) {
      _streamOpened = false;
      _setState(XmppState.disconnected);
      return;
    }

    // Fatal stream errors — stop reconnection immediately
    if (text.contains('<stream:error') || text.contains('stream:error>')) {
      log('🚫 XmppClient: Stream error received — stopping reconnection');
      _intentionalDisconnect = true;
      _pingTimer?.cancel();
      _setState(XmppState.failed);
      if (_authCompleter != null && !_authCompleter!.isCompleted) {
        _authCompleter!.complete(false);
      }
      _socket?.close(1001, 'Stream error');
      return;
    }

    // Handle stream features (SASL mechanisms)
    if (text.contains('<stream:features') || text.contains('<features ')) {
      _handleFeatures(text);
      return;
    }

    // Handle SASL responses
    if (text.contains('<success ') || text.contains('<success>')) {
      _handleAuthSuccess();
      return;
    }

    if (text.contains('<failure ')) {
      _handleAuthFailure(text);
      return;
    }

    // Handle IQ responses (bind, session)
    if (text.contains('<iq ')) {
      _handleIq(text);
      return;
    }

    // Handle messages
    if (text.contains('<message ')) {
      _handleMessage(text);
      return;
    }

    // Handle presence
    if (text.contains('<presence ')) {
      _handlePresence(text);
      return;
    }
  }

  void _onError(dynamic error) {
    log('❌ XmppClient: WebSocket error: $error');
    _setState(XmppState.failed);
    if (_authCompleter != null && !_authCompleter!.isCompleted) {
      _authCompleter!.complete(false);
    }
  }

  void _handleFeatures(String xml) {
    log('🔐 XmppClient: Handling features');
    log('🔐 XmppClient features XML: $xml');

    if (_state == XmppState.authenticated) {
      // Post-auth features — bind resource
      _bindResource();
      return;
    }

    // Check for SASL mechanisms
    if (xml.contains('PLAIN')) {
      _setState(XmppState.authenticating);
      _authenticatePlain();
    } else if (xml.contains('mechanisms')) {
      log('⚠️ XmppClient: No supported SASL mechanism found');
      _setState(XmppState.failed);
      _authCompleter?.complete(false);
    } else {
      // Server sent features without advertising SASL mechanisms.
      // Some servers accept SASL PLAIN even when not advertised.
      // Also check if <bind> is present — if so, the server may skip SASL.
      if (xml.contains('<bind')) {
        log(
          '⚠️ XmppClient: Server sent <bind> without SASL — attempting resource bind directly',
        );
        _setState(XmppState.authenticating);
        _bindResource();
      } else {
        log(
          '⚠️ XmppClient: No mechanisms advertised — trying SASL PLAIN as fallback',
        );
        _setState(XmppState.authenticating);
        _authenticatePlain();
      }
    }
  }

  void _authenticatePlain() {
    // SASL PLAIN: \0username\0password
    final username = _jid!.split('@')[0];
    final authString = '\u0000$username\u0000$_password';
    final base64Auth = base64.encode(utf8.encode(authString));

    final stanza = '<auth xmlns="urn:ietf:params:xml:ns:xmpp-sasl" '
        'mechanism="PLAIN">$base64Auth</auth>';

    _send(stanza);
    log('🔑 XmppClient: Sent SASL PLAIN auth for $username');
  }

  void _handleAuthSuccess() {
    log('✅ XmppClient: SASL authentication successful');
    _setState(XmppState.authenticated);

    // Re-open stream after successful auth (XMPP requires this)
    _sendStreamOpen();
  }

  void _handleAuthFailure(String xml) {
    log('❌ XmppClient: SASL authentication failed: $xml');
    _intentionalDisconnect = true;
    _pingTimer?.cancel();
    _setState(XmppState.failed);
    if (_authCompleter != null && !_authCompleter!.isCompleted) {
      _authCompleter!.complete(false);
    }
    _socket?.close(1001, 'Auth failed');
  }

  void _bindResource() {
    final resource = _resource?.isNotEmpty == true
        ? _resource
        : 'nexacon_${Random().nextInt(9999)}';
    final stanza = '<iq type="set" id="bind_1">'
        '<bind xmlns="urn:ietf:params:xml:ns:xmpp-bind">'
        '<resource>$resource</resource>'
        '</bind></iq>';

    _send(stanza);
    log('🔗 XmppClient: Binding resource: $resource');
  }

  void _handleIq(String xml) {
    // Check for bind result
    if (xml.contains('bind') && xml.contains('<jid>')) {
      final jidMatch = RegExp(r'<jid>([^<]+)</jid>').firstMatch(xml);
      if (jidMatch != null) {
        _boundJid = jidMatch.group(1);
        log('✅ XmppClient: Bound JID: $_boundJid');

        // Start session
        _startSession();
      }
    } else if (xml.contains('session') || xml.contains('result')) {
      // Session established or generic result
      if (_authCompleter != null && !_authCompleter!.isCompleted) {
        log('✅ XmppClient: Session established - fully authenticated');
        _setState(XmppState.authenticated);
        _authCompleter!.complete(true);

        // Send initial presence
        sendPresence();
      }
    }
  }

  void _startSession() {
    final stanza = '<iq type="set" id="session_1">'
        '<session xmlns="urn:ietf:params:xml:ns:xmpp-session"/>'
        '</iq>';
    _send(stanza);
    log('📋 XmppClient: Starting session');
  }

  void _handleMessage(String xml) {
    // Parse message stanza — handle both single and double quoted attributes
    final typeMatch = RegExp(r'''type=['"]([^'"']*)['"]''').firstMatch(xml);
    final fromMatch = RegExp(r'''from=['"]([^'"']*)['"]''').firstMatch(xml);
    final toMatch = RegExp(r'''to=['"]([^'"']*)['"]''').firstMatch(xml);
    final idMatch = RegExp(r'''\sid=['"]([^'"']*)['"]''').firstMatch(xml);
    final bodyMatch = RegExp(r'<body[^>]*>([^<]*)</body>').firstMatch(xml);

    final type = typeMatch?.group(1);
    final from = fromMatch?.group(1);
    final to = toMatch?.group(1);
    final id = idMatch?.group(1);
    final body = bodyMatch?.group(1);

    // Skip error messages
    if (type == 'error') return;

    // Check for delivery receipts
    if (xml.contains('urn:xmpp:receipts') && xml.contains('<received')) {
      log('📬 XmppClient: Delivery receipt received');
      return;
    }

    if (body != null && body.isNotEmpty) {
      final message = XmppMessage(
        id: id,
        from: from,
        to: to,
        body: _unescapeXml(body),
        type: type,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      log('📩 XmppClient: Broadcasting message from $from to stream');
      if (!_messageController.isClosed) {
        _messageController.add(message);
        log('✅ XmppClient: Message added to stream successfully');
      } else {
        log('❌ XmppClient: Message controller is closed, cannot broadcast');
      }
      log(
        '📩 XmppClient: Message from $from: ${body.length > 50 ? body.substring(0, 50) + "..." : body}',
      );
    }
  }

  void _handlePresence(String xml) {
    final fromMatch = RegExp(r'''from=['"]([^'"']*)['"]''').firstMatch(xml);
    final typeMatch = RegExp(r'''type=['"]([^'"']*)['"]''').firstMatch(xml);
    final showMatch = RegExp(r'<show>([^<]*)</show>').firstMatch(xml);

    final presence = XmppPresence(
      from: fromMatch?.group(1),
      type: typeMatch?.group(1),
      show: showMatch?.group(1),
    );

    if (!_presenceController.isClosed) {
      _presenceController.add(presence);
    }
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (isAuthenticated) {
        final stanza =
            '<iq type="get" id="ping_${DateTime.now().millisecondsSinceEpoch}">'
            '<ping xmlns="urn:xmpp:ping"/></iq>';
        _send(stanza);
      }
    });
  }

  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  String _unescapeXml(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'");
  }
}
