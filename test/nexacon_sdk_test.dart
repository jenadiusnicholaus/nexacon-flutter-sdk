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

    test('generateXMPPToken throws ValidationException for empty username',
        () async {
      expect(
        () => client.auth.generateXMPPToken(username: ''),
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
}
