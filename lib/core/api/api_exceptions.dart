/// Typed API exception hierarchy.
///
/// All API errors are represented as specific exception subclasses
/// so callers can catch exactly what they need.
library;

class ApiException implements Exception {
  final int statusCode;
  final String code;
  final String message;
  final Map<String, dynamic> details;

  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.details = const {},
  });

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, code: $code, message: $message)';
}

/// 401 — token expired, missing, or invalid.
class UnauthorizedException extends ApiException {
  const UnauthorizedException({
    super.statusCode = 401,
    super.code = 'unauthorized',
    super.message = 'Authentication required',
    super.details,
  });
}

/// 422 / 400 — request body failed validation.
class ValidationException extends ApiException {
  const ValidationException({
    super.statusCode = 422,
    super.code = 'validation_error',
    super.message = 'Validation failed',
    super.details,
  });
}

/// 404 — resource not found.
class NotFoundException extends ApiException {
  const NotFoundException({
    super.statusCode = 404,
    super.code = 'not_found',
    super.message = 'Resource not found',
    super.details,
  });
}

/// 409 — conflict (e.g. duplicate phone, box already reserved).
class ConflictException extends ApiException {
  const ConflictException({
    super.statusCode = 409,
    super.code = 'conflict',
    super.message = 'Resource conflict',
    super.details,
  });
}

/// 429 — rate limit exceeded.
class RateLimitException extends ApiException {
  final Duration retryAfter;

  const RateLimitException({
    super.statusCode = 429,
    super.code = 'rate_limit',
    super.message = 'Too many requests',
    super.details,
    this.retryAfter = const Duration(seconds: 60),
  });

  @override
  String toString() =>
      'RateLimitException(retryAfter: ${retryAfter.inSeconds}s, message: $message)';
}

/// No internet, DNS failure, connection refused, etc.
class NetworkException extends ApiException {
  const NetworkException({
    super.statusCode = 0,
    super.code = 'network_error',
    super.message = 'Network connection failed',
    super.details,
  });
}

/// 500+ — something broke on the backend.
class ServerException extends ApiException {
  const ServerException({
    super.statusCode = 500,
    super.code = 'server_error',
    super.message = 'Internal server error',
    super.details,
  });
}
