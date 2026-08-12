/// Central configuration for the Nexacon Calls SDK.
///
/// Edit this file to change hosts, base URLs, WebSocket paths,
/// NX domains, STUN/TURN servers, and other environment-specific values.
abstract class NexaconConfig {
  /// Host domain for Nexacon services.
  static const String host = 'nxservice.quantumvision-tech.com';

  /// NX domain (used for NX IDs and signaling).
  static const String nxDomain = 'nxservice.quantumvision-tech.com';

  /// REST API base URL.
  static const String baseUrl = 'https://nxservice.quantumvision-tech.com/api/v1.0';

  /// NX WebSocket URL (used internally for signaling).
  static const String wsUrl = 'wss://nxservice.quantumvision-tech.com/nx-websocket/';

  /// Default HTTP request timeout.
  static const Duration defaultTimeout = Duration(seconds: 30);

  /// WebSocket connection timeout.
  static const Duration wsConnectTimeout = Duration(seconds: 15);

  /// WebSocket authentication timeout.
  static const Duration wsAuthTimeout = Duration(seconds: 15);

  /// Default WebSocket ping interval.
  static const Duration pingInterval = Duration(seconds: 30);

  /// Heartbeat interval for NX connection.
  static const Duration heartbeatInterval = Duration(seconds: 30);

  /// Reconnect backoff settings.
  static const Duration reconnectInitialDelay = Duration(seconds: 1);
  static const Duration reconnectIncrement = Duration(seconds: 2);
  static const Duration reconnectMaxDelay = Duration(seconds: 30);
  static const int maxReconnectAttempts = 10;

  /// Call response timeout (how long to wait for callee to answer).
  static const Duration callResponseTimeout = Duration(seconds: 60);

  /// Call state transition delay.
  static const Duration callStateDelay = Duration(seconds: 1);

  /// Call stats polling interval.
  static const Duration statsInterval = Duration(seconds: 2);

  /// WebRTC ICE gathering timeout.
  static const Duration iceGatheringTimeout = Duration(seconds: 15);

  /// STUN servers for NAT traversal.
  static const List<Map<String, dynamic>> stunServers = [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
    {'urls': 'stun:nxservice.quantumvision-tech.com:3478'},
  ];

  // -- API Endpoints --

  /// NX token authentication.
  static const String nxTokenEndpoint = '/nexacon-auth/nxm-token/';
  static const String nxTokenRefreshEndpoint = '/nexacon-auth/nxm-token/refresh/';

  /// Call endpoints.
  static const String callEndpoint = '/nx/call/';
  static const String groupCallEndpoint = '/nx/group-call/';
  static const String callUrlEndpoint = '/nx/call-url/';
  static const String callDeclineEndpoint = '/nx/call/decline/';
  static const String callAnalyticsEndpoint = '/nx/call-analytics/';
  static const String callHistoryEndpoint = '/nx/call-history/';

  /// WebRTC endpoints.
  static const String webrtcCredentialsEndpoint = '/nx/webrtc/credentials/';
  static const String webrtcCallEndpoint = '/nx/webrtc/call/';

  /// Messaging endpoints.
  static const String messageEndpoint = '/nx/message/';
  static const String broadcastEndpoint = '/nx/broadcast/';
  static const String historyEndpoint = '/nx/history/';

  /// Contacts endpoints.
  static const String contactsEndpoint = '/nx/contacts/';

  /// Presence endpoint.
  static const String presenceEndpoint = '/nx/presence/';

  /// Rooms endpoints.
  static const String roomsEndpoint = '/nx/rooms/';

  /// Devices endpoints.
  static const String registerDeviceEndpoint = '/nx/register-device/';
  static const String devicesEndpoint = '/nx/devices/';
}
