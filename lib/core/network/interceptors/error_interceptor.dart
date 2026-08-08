// Normalizes any Dio failure into ApiException by parsing the backend's
// standard error envelope { error: { code, message, correlation_id } } (SRS §16).
