// Attaches bearer token from SecureStorageService; single-flight silent
// refresh on 401 (mutex-guarded), then retries the original request once.
