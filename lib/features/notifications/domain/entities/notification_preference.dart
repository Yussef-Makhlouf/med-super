class NotificationPreference {
  const NotificationPreference({
    required this.tier,
    required this.channel,
    required this.enabled,
    required this.userDisableable,
  });

  final String tier;
  final String channel;
  final bool enabled;
  final bool userDisableable;

  NotificationPreference copyWith({bool? enabled}) => NotificationPreference(
    tier: tier,
    channel: channel,
    enabled: enabled ?? this.enabled,
    userDisableable: userDisableable,
  );

  /// Critical notifications are always enabled by the backend contract.
  bool get effectiveEnabled => !userDisableable || enabled;
}
