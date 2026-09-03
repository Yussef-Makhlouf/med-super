/// Per-call cache policy — set explicitly per repository call, never global.
///
/// Not yet consumed by any repository (all current repositories call their
/// remote datasource directly). Declared ahead of use for when a feature
/// needs it — don't remove, but don't assume any caching currently happens.
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
