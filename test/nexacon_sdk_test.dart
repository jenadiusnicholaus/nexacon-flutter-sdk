import 'package:flutter_test/flutter_test.dart';
import 'package:nexacon_sdk/nexacon_sdk.dart';

void main() {
  test('NexaconClient initialization', () {
    final client = NexaconClient(
      apiKey: 'test_key',
      secretKey: 'test_secret',
    );
    expect(client.apiKey, 'test_key');
    expect(client.secretKey, 'test_secret');
    client.close();
  });
}
