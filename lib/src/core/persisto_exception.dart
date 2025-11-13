/// Base exception class for all Persisto-related errors.
abstract class PersistoException implements Exception {
  /// Creates a new PersistoException with an optional [message] and [cause].
  PersistoException(this.message, [this.cause]);

  /// Human-readable error message.
  final String message;

  /// The underlying exception that caused this error, if any.
  final dynamic cause;

  @override
  String toString() {
    if (cause != null) {
      return '$runtimeType: $message\nCaused by: $cause';
    }
    return '$runtimeType: $message';
  }
}

/// Thrown when a network request fails (timeout, connection error, etc.).
class NetworkException extends PersistoException {
  /// Creates a new NetworkException.
  NetworkException(super.message, [super.cause]);
}

/// Thrown when an HTTP request returns a non-success status code.
class HttpException extends PersistoException {
  /// Creates a new HttpException with [statusCode] and optional [responseBody].
  HttpException(
    String message,
    this.statusCode, {
    this.responseBody,
    dynamic cause,
  }) : super(message, cause);

  /// HTTP status code (e.g., 404, 500).
  final int statusCode;

  /// Response body, if available.
  final dynamic responseBody;

  /// Whether this is a client error (4xx).
  bool get isClientError => statusCode >= 400 && statusCode < 500;

  /// Whether this is a server error (5xx).
  bool get isServerError => statusCode >= 500 && statusCode < 600;

  @override
  String toString() {
    final buffer = StringBuffer('$runtimeType: $message (Status: $statusCode)');
    if (responseBody != null) {
      buffer.write('\nResponse: $responseBody');
    }
    if (cause != null) {
      buffer.write('\nCaused by: $cause');
    }
    return buffer.toString();
  }
}

/// Thrown when cache operations fail or cache is unavailable.
class CacheException extends PersistoException {
  /// Creates a new CacheException.
  CacheException(super.message, [super.cause]);
}

/// Thrown when an adapter operation fails.
class AdapterException extends PersistoException {
  /// Creates a new AdapterException.
  AdapterException(super.message, [super.cause]);
}

/// Thrown when a cache policy is invalid or missing.
class PolicyException extends PersistoException {
  /// Creates a new PolicyException.
  PolicyException(super.message, [super.cause]);
}

