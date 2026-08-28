/// Lifecycle status of a clinic assistant account.
enum AssistantStatus {
  active,
  suspended;

  String get apiValue => name.toUpperCase();

  static AssistantStatus fromApi(String? raw) => switch (raw?.toUpperCase()) {
    'SUSPENDED' => AssistantStatus.suspended,
    _ => AssistantStatus.active,
  };
}
