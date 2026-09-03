/// Per-call cache policy — set explicitly per repository call, never global.
enum CachePolicy {
  /// Return cached data immediately; refresh in background.
  cacheFirst,

  /// Try network first; fall back to cache on failure.
  networkFirst,

  /// Always fetch from network; never read or write cache.
  networkOnly,

  /// Always return from cache; never hit the network.
  cacheOnly,
}
