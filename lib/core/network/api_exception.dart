class ApiException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  const ApiException({
    required this.message,
    this.code,
    this.statusCode,
  });

  @override
  String toString() => 'ApiException($statusCode): $message [code: $code]';
}

class AuthException extends ApiException {
  const AuthException({required super.message, super.code, super.statusCode});
}

class NotFoundException extends ApiException {
  const NotFoundException({required super.message, super.code})
      : super(statusCode: 404);
}

class ForbiddenException extends ApiException {
  const ForbiddenException({required super.message, super.code})
      : super(statusCode: 403);
}

class ValidationException extends ApiException {
  final List<Map<String, dynamic>> issues;

  const ValidationException({
    required super.message,
    super.code,
    this.issues = const [],
  }) : super(statusCode: 400);
}

class RateLimitException extends ApiException {
  const RateLimitException({required super.message, super.code})
      : super(statusCode: 429);
}

class NetworkException extends ApiException {
  const NetworkException({required super.message, super.code});
}
