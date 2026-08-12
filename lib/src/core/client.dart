import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/nexacon_config.dart';
import '../core/exceptions.dart';
import '../core/nx_connection_manager.dart';
import '../auth/auth.dart';
import '../messaging/messaging.dart';
import '../messaging/messaging_manager.dart';
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
  late final NxConnectionManager nxConnection;

  NexaconClient({
    required this.apiKey,
    required this.secretKey,
    this.baseUrl = NexaconConfig.baseUrl,
    this.timeout = NexaconConfig.defaultTimeout,
  }) {
    _httpClient = http.Client();
    nxConnection = NxConnectionManager();
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
    print('📨 Client request: $method $endpoint');
    print('📨 Client params: $params');
    print('📨 Client params type: ${params.runtimeType}');

    // Convert params to Map<String, String> for queryParameters
    final stringParams =
        params?.map((key, value) => MapEntry(key, value?.toString()));
    print('📨 Client stringParams: $stringParams');

    final url =
        Uri.parse('$baseUrl$endpoint').replace(queryParameters: stringParams);
    print('📨 Client URL: $url');

    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      'X-API-Key': apiKey,
      'X-Secret-Key': secretKey,
    };

    print('📨 Client API Key: ${apiKey.substring(0, 10)}...');
    print('📨 Client Secret Key: ${secretKey.substring(0, 10)}...');

    if (_nxToken != null) {
      requestHeaders['X-NX-Token'] = _nxToken!;
      print('📨 Client using NX token: ${_nxToken!.substring(0, 20)}...');
    } else {
      print('⚠️ Client: No NX token set!');
    }

    if (headers != null) {
      requestHeaders.addAll(headers);
    }

    http.Response response;
    try {
      print('📨 Client about to make HTTP request...');
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _httpClient
              .get(url, headers: requestHeaders)
              .timeout(timeout);
          print('📨 Client HTTP GET response received');
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
      print('⚠️ Client error response status: ${response.statusCode}');
      print('⚠️ Client error response body: ${response.body}');
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

    final decoded = json.decode(response.body);
    print('📨 Client request decoded response type: ${decoded.runtimeType}');
    if (decoded is Map) {
      print('📨 Client request decoded keys: ${decoded.keys.toList()}');
    }
    return decoded;
  }

  void setToken(String token) {
    _nxToken = token;
  }

  String? getToken() {
    return _nxToken;
  }

  void close() {
    _httpClient.close();
    nxConnection.dispose();
  }

  /// Create a CallManager instance for P2P calling
  /// Automatically initializes connection if credentials provided
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
    Function()? onOtherUserJoined,
    Function()? onOtherUserLeft,
  }) async {
    final callManager = CallManager(
      this,
      nxConnection,
      onCallStateChanged: onCallStateChanged,
      onIncomingCall: onIncomingCall,
      onCallEnded: onCallEnded,
      onError: onError,
      onLocalStream: onLocalStream,
      onRemoteStream: onRemoteStream,
      onOtherUserJoined: onOtherUserJoined,
      onOtherUserLeft: onOtherUserLeft,
    );

    // Auto-initialize connection if credentials provided
    if (nxtoken != null && nxid != null && wsUrl != null) {
      final initialized = await callManager.initialize(
        nxid: nxid,
        nxtoken: nxtoken,
        wsUrl: wsUrl,
        name: name,
      );
      if (!initialized) {
        onError?.call('Failed to initialize connection');
      }
    }

    return callManager;
  }

  /// Create a MessagingManager for real-time chat
  /// Connection must be established first
  MessagingManager createMessagingManager() {
    return MessagingManager(nxConnection);
  }
}
