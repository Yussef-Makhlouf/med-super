// Every core singleton exactly once: dioProvider, hiveServiceProvider,
// secureStorageProvider, each *ServiceProvider. Riverpod is the only DI
// mechanism in this app — no get_it/service-locator layered on top.
