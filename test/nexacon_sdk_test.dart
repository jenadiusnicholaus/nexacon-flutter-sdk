import 'package:flutter_test/flutter_test.dart';
import 'package:nexacon_sdk/nexacon_sdk.dart';

void main() {
  group('NexaconClient', () {
    test('initialization with custom baseUrl', () {
      final client = NexaconClient(
        apiKey: 'test_key',
        secretKey: 'test_secret',
        baseUrl: 'https://custom.api.com',
      );
      expect(client.apiKey, 'test_key');
      expect(client.secretKey, 'test_secret');
      client.close();
    });

    test('initialization with default baseUrl', () {
      final client = NexaconClient(
        apiKey: 'test_key',
        secretKey: 'test_secret',
      );
      expect(client.apiKey, 'test_key');
      expect(client.secretKey, 'test_secret');
      client.close();
    });

    test('token management', () {
      final client = NexaconClient(
        apiKey: 'test_key',
        secretKey: 'test_secret',
      );

      client.setToken('test_token');
      expect(client.getToken(), 'test_token');

      client.setToken('');
      expect(client.getToken(), '');

      client.close();
    });

    test('createMessagingManager returns MessagingManager', () {
      final client = NexaconClient(
        apiKey: 'test_key',
        secretKey: 'test_secret',
      );

      final messagingManager = client.createMessagingManager();
      expect(messagingManager, isA<MessagingManager>());

      client.close();
    });
  });

  group('MessagingManager', () {
    test('createMessagingManager returns MessagingManager', () {
      final client = NexaconClient(
        apiKey: 'test_key',
        secretKey: 'test_secret',
      );

      final messagingManager = client.createMessagingManager();
      expect(messagingManager, isA<MessagingManager>());

      client.close();
    });
  });

  group('Auth', () {
    late NexaconClient client;

    setUp(() {
      client = NexaconClient(
        apiKey: 'test_key',
        secretKey: 'test_secret',
      );
    });

    tearDown(() {
      client.close();
    });

    test('getNxToken throws ValidationException for empty username', () async {
      expect(
        () => client.auth.getNxToken(username: ''),
        throwsA(isA<ValidationException>()),
      );
    });

    test('refreshXMPPToken throws ValidationException for empty refreshToken',
        () async {
      expect(
        () => client.auth.refreshXMPPToken(refreshToken: ''),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('Calls', () {
    late NexaconClient client;

    setUp(() {
      client = NexaconClient(
        apiKey: 'test_key',
        secretKey: 'test_secret',
      );
    });

    tearDown(() {
      client.close();
    });

    test('recordCall throws ValidationException for empty room', () async {
      expect(
        () => client.calls.recordCall(
          room: '',
          callType: CallType.audio,
          status: CallAnalyticsStatus.ended,
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('Messaging', () {
    late NexaconClient client;

    setUp(() {
      client = NexaconClient(
        apiKey: 'test_key',
        secretKey: 'test_secret',
      );
    });

    tearDown(() {
      client.close();
    });

    test('send throws ValidationException for empty to', () async {
      expect(
        () => client.messaging.send(to: '', message: 'test'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('send throws ValidationException for empty message', () async {
      expect(
        () => client.messaging.send(to: 'test@example.com', message: ''),
        throwsA(isA<ValidationException>()),
      );
    });

    test('addContact throws ValidationException for empty nxid', () async {
      expect(
        () => client.messaging.addContact(''),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('Devices', () {
    late NexaconClient client;

    setUp(() {
      client = NexaconClient(
        apiKey: 'test_key',
        secretKey: 'test_secret',
      );
    });

    tearDown(() {
      client.close();
    });

    test('register throws ValidationException for empty fcmToken', () async {
      expect(
        () => client.devices.register(
          platform: Platform.android,
          fcmToken: '',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('unregister throws ValidationException for empty fcmToken', () async {
      expect(
        () => client.devices.unregister(''),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('Rooms', () {
    late NexaconClient client;

    setUp(() {
      client = NexaconClient(
        apiKey: 'test_key',
        secretKey: 'test_secret',
      );
    });

    tearDown(() {
      client.close();
    });

    test('addMember throws ValidationException for empty name', () async {
      expect(
        () => client.rooms.addMember(name: '', nxid: 'test@example.com'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('addMember throws ValidationException for empty nxid', () async {
      expect(
        () => client.rooms.addMember(name: 'room123', nxid: ''),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('Presence', () {
    late NexaconClient client;

    setUp(() {
      client = NexaconClient(
        apiKey: 'test_key',
        secretKey: 'test_secret',
      );
    });

    tearDown(() {
      client.close();
    });

    test('get works without parameters', () async {
      // This would normally make an API call, but we're just testing the method exists
      expect(client.presence, isNotNull);
    });
  });

  group('SignalingMessage', () {
    test('fromJson parses call_invitation', () {
      final json = {
        'type': 'call_invitation',
        'roomId': 'room123',
        'fromJid': 'user@example.com',
      };
      final message = SignalingMessage.fromJson(json);
      expect(message.type, SignalingMessageType.callInvitation);
      expect(message.data['roomId'], 'room123');
    });

    test('fromJson parses call_response', () {
      final json = {
        'type': 'call_response',
        'roomId': 'room123',
        'accepted': true,
      };
      final message = SignalingMessage.fromJson(json);
      expect(message.type, SignalingMessageType.callResponse);
      expect(message.data['accepted'], true);
    });

    test('fromJson parses webrtc_offer', () {
      final json = {
        'type': 'webrtc_offer',
        'roomId': 'room123',
        'sdp': 'test_sdp',
        'sdp_type': 'offer',
      };
      final message = SignalingMessage.fromJson(json);
      expect(message.type, SignalingMessageType.webrtcOffer);
      expect(message.data['sdp'], 'test_sdp');
    });

    test('fromJson throws for unknown type', () {
      final json = {'type': 'unknown_type'};
      expect(
        () => SignalingMessage.fromJson(json),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('toJson serializes correctly', () {
      final message = SignalingMessage(
        type: SignalingMessageType.callInvitation,
        data: {'roomId': 'room123', 'fromJid': 'user@example.com'},
      );
      final json = message.toJson();
      expect(json['type'], 'call_invitation');
      expect(json['roomId'], 'room123');
    });
  });

  group('CallType', () {
    test('enum values', () {
      expect(CallType.audio.toString(), 'CallType.audio');
      expect(CallType.video.toString(), 'CallType.video');
      expect(CallType.p2p.toString(), 'CallType.p2p');
      expect(CallType.group.toString(), 'CallType.group');
    });
  });

  group('CallAnalyticsStatus', () {
    test('enum values', () {
      expect(CallAnalyticsStatus.initiated.toString(),
          'CallAnalyticsStatus.initiated');
      expect(CallAnalyticsStatus.calling.toString(),
          'CallAnalyticsStatus.calling');
      expect(CallAnalyticsStatus.answered.toString(),
          'CallAnalyticsStatus.answered');
      expect(CallAnalyticsStatus.declined.toString(),
          'CallAnalyticsStatus.declined');
      expect(CallAnalyticsStatus.cancelled.toString(),
          'CallAnalyticsStatus.cancelled');
      expect(
          CallAnalyticsStatus.missed.toString(), 'CallAnalyticsStatus.missed');
      expect(CallAnalyticsStatus.ended.toString(), 'CallAnalyticsStatus.ended');
      expect(
          CallAnalyticsStatus.failed.toString(), 'CallAnalyticsStatus.failed');
    });
  });

  group('Exceptions', () {
    test('ValidationException has message', () {
      final exception = ValidationException('Test error');
      expect(exception.message, 'Test error');
      expect(exception.toString(), contains('Test error'));
    });

    test('AuthenticationException has message', () {
      final exception = AuthenticationException('Auth failed');
      expect(exception.message, 'Auth failed');
      expect(exception.toString(), contains('Auth failed'));
    });

    test('APIException has message', () {
      final exception = APIException('API error');
      expect(exception.message, 'API error');
      expect(exception.toString(), contains('API error'));
    });

    test('RateLimitException has message', () {
      final exception = RateLimitException('Rate limit exceeded');
      expect(exception.message, 'Rate limit exceeded');
      expect(exception.toString(), contains('Rate limit exceeded'));
    });
  });

  group('CallState', () {
    test('CallState enum values', () {
      expect(CallState.idle.toString(), 'CallState.idle');
      expect(CallState.calling.toString(), 'CallState.calling');
      expect(CallState.incoming.toString(), 'CallState.incoming');
      expect(CallState.connected.toString(), 'CallState.connected');
      expect(CallState.ended.toString(), 'CallState.ended');
    });
  });

  group('Platform', () {
    test('Platform enum values', () {
      expect(Platform.android.toString(), 'Platform.android');
      expect(Platform.ios.toString(), 'Platform.ios');
      expect(Platform.web.toString(), 'Platform.web');
    });
  });
}
