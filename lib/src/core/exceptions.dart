/// Nexacon SDK Exception Classes
class NexaconException implements Exception {
  final String message;
  NexaconException(this.message);

  @override
  String toString() => 'NexaconException: $message';
}

class AuthenticationException extends NexaconException {
  AuthenticationException([String message = 'Authentication failed'])
      : super(message);
}

class APIException extends NexaconException {
  final int? statusCode;
  final dynamic response;

  APIException(String message, {this.statusCode, this.response})
      : super(message);

  @override
  String toString() => 'APIException: $message (status: $statusCode)';
}

class RateLimitException extends APIException {
  RateLimitException([String message = 'Rate limit exceeded'])
      : super(message, statusCode: 429);
}

class ValidationException extends NexaconException {
  ValidationException([String message = 'Validation failed'])
      : super(message);
}
