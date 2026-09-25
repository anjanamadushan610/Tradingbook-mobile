/// Every failed API call surfaces as one of these. Branch on [code] (the
/// backend's machine-readable `error.code`), never on [message] — messages are
/// wording and may change.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
  });

  final String message;
  final int? statusCode;
  final String? code;

  bool get isNetwork => statusCode == null;
  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
  bool get isRateLimited => statusCode == 429;

  static const network = ApiException(
    message: 'No connection. Check your internet and try again.',
  );

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}

/// Friendly copy for the error codes a user can actually act on. Anything not
/// listed falls back to the server's own message, which the backend writes to
/// be user-presentable.
String friendlyErrorMessage(Object error) {
  if (error is! ApiException) return 'Something went wrong. Please try again.';
  switch (error.code) {
    case 'invalid_credentials':
      return 'Incorrect email or password.';
    case 'email_taken':
      return 'An account with this email already exists.';
    case 'email_registered_with_social':
      return 'This email uses Google or Apple sign-in. Use that button instead.';
    case 'email_registered_with_password':
      return 'This email already has a password account. Sign in with your password.';
    case 'disposable_email':
      return 'Please use a permanent email address.';
    case 'rate_limit_exceeded':
    case 'too_many_requests':
      return 'Too many attempts. Please wait a bit and try again.';
    case 'file_too_large':
      return 'That file is too large.';
    case 'unsupported_image_type':
      return 'That image format is not supported. Use JPEG, PNG, GIF or WebP.';
    case 'market_data_unavailable':
      return 'Prices are temporarily unavailable.';
    case 'post_not_live':
      return 'Only published posts can be saved.';
  }
  if (error.statusCode != null && error.statusCode! >= 500) {
    return 'The server had a problem. Please try again shortly.';
  }
  return error.message;
}
