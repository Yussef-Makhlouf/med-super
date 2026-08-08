// Configured Dio instance with the full interceptor chain attached:
// CorrelationIdInterceptor -> AuthInterceptor -> IdempotencyKeyInterceptor ->
// LoggingInterceptor (debug only) -> ErrorInterceptor -> RetryInterceptor.
