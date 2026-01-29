/// AI service exceptions.
library;

abstract class AiException implements Exception {
  final String message;
  final String? code;

  const AiException({required this.message, this.code});

  @override
  String toString() => 'AiException: $message${code != null ? ' ($code)' : ''}';
}

class AiConfigurationException extends AiException {
  const AiConfigurationException({required super.message, super.code});
}

class AiApiException extends AiException {
  final int? statusCode;

  const AiApiException({
    required super.message,
    super.code,
    this.statusCode,
  });

  @override
  String toString() =>
      'AiApiException: $message${statusCode != null ? ' (HTTP $statusCode)' : ''}';
}

class AiParseException extends AiException {
  const AiParseException({required super.message, super.code});
}

class AiTimeoutException extends AiException {
  const AiTimeoutException({
    super.message = 'AI request timed out',
    super.code,
  });
}

class AiRateLimitException extends AiException {
  final Duration? retryAfter;

  const AiRateLimitException({
    super.message = 'Rate limit exceeded',
    super.code,
    this.retryAfter,
  });
}
