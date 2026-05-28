import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/exceptions.dart';
import '../auth/auth.dart';
import '../messaging/messaging.dart';
import '../calls/calls.dart';
import '../calls/call_manager.dart';
import '../devices/devices.dart';
import '../rooms/rooms.dart';
import '../presence/presence.dart';

/// Nexacon SDK Main Client
class NexaconClient {
  final String apiKey;
  final String secretKey;
  final String baseUrl;
  final Duration timeout;

  late final http.Client _httpClient;
  String? _nxToken;

  late final Auth auth;
  late final Messaging messaging;
  late final Calls calls;
  late final Devices devices;
  late final Rooms rooms;
  late final Presence presence;

  NexaconClient({
    required this.apiKey,
    required this.secretKey,
    this.baseUrl = 'https://nxservice.quantumvision-tech.com/api/v1.0',
    this.timeout = const Duration(seconds: 30),
  }) {
    _httpClient = http.Client();
    auth = Auth(this);
    messaging = Messaging(this);
    calls = Calls(this);
    devices = Devices(this);
    rooms = Rooms(this);
    presence = Presence(this);
  }

  Future<Map<String, dynamic>> request(
    String method,
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint').replace(queryParameters: params);

    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      'X-API-Key': apiKey,
      'X-Secret-Key': secretKey,
    };

    if (_nxToken != null) {
      requestHeaders['X-NX-Token'] = _nxToken!;
    }

    if (headers != null) {
      requestHeaders.addAll(headers);
    }

    http.Response response;
    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _httpClient
              .get(url, headers: requestHeaders)
              .timeout(timeout);
          break;
        case 'POST':
          response = await _httpClient
              .post(url, headers: requestHeaders, body: json.encode(data))
              .timeout(timeout);
          break;
        case 'PUT':
          response = await _httpClient
              .put(url, headers: requestHeaders, body: json.encode(data))
              .timeout(timeout);
          break;
        case 'DELETE':
          response = await _httpClient
              .delete(
                url,
                headers: requestHeaders,
                body: data != null ? json.encode(data) : null,
              )
              .timeout(timeout);
          break;
        default:
          throw APIException('Unsupported HTTP method: $method');
      }
    } on TimeoutException {
      throw APIException('Request timeout');
    } catch (e) {
      throw APIException('Request failed: $e');
    }

    if (response.statusCode == 401) {
      throw AuthenticationException('Authentication failed');
    } else if (response.statusCode == 429) {
      throw RateLimitException('Rate limit exceeded');
    } else if (response.statusCode >= 400) {
      try {
        final errorData = json.decode(response.body);
        throw APIException(
          errorData['error'] ?? 'API request failed',
          statusCode: response.statusCode,
          response: errorData,
        );
      } catch (e) {
        throw APIException(
          'API request failed with status ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    }

    return json.decode(response.body);
  }

  void setToken(String token) {
    _nxToken = token;
  }

  String? getToken() {
    return _nxToken;
  }

  void close() {
    _httpClient.close();
  }

  /// Create a CallManager instance for P2P calling
  /// Automatically initializes NX connection if nxtoken is provided
  Future<CallManager> createCallManager({
    String? nxtoken,
    String? nxid,
    String? wsUrl,
    String? name,
    Function(CallState)? onCallStateChanged,
    Function(String)? onIncomingCall,
    Function(String)? onCallEnded,
    Function(String)? onError,
    Function(dynamic)? onLocalStream,
    Function(dynamic)? onRemoteStream,
  }) async {
    final callManager = CallManager(
      this,
      onCallStateChanged: onCallStateChanged,
      onIncomingCall: onIncomingCall,
      onCallEnded: onCallEnded,
      onError: onError,
      onLocalStream: onLocalStream,
      onRemoteStream: onRemoteStream,
    );

    // Auto-initialize XMPP if credentials provided
    if (nxtoken != null && nxid != null && wsUrl != null) {
      final initialized = await callManager.initialize(
        nxid: nxid,
        nxtoken: nxtoken,
        wsUrl: wsUrl,
        name: name,
      );
      if (!initialized) {
        onError?.call('Failed to initialize XMPP connection');
      }
    }

    return callManager;
  }
}
