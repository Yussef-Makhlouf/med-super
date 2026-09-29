import 'package:med_super/features/notifications/domain/entities/notification_preference.dart';

class NotificationPreferenceDto {
  static const _tiers = {
    'TRANSACTIONAL',
    'INFORMATIONAL',
    'SAFETY_CRITICAL',
    'MARKETING',
  };
  static const _channels = {'PUSH', 'SMS'};

  const NotificationPreferenceDto({
    required this.tier,
    required this.channel,
    required this.enabled,
    required this.userDisableable,
  });

  factory NotificationPreferenceDto.fromJson(Map<String, dynamic> json) {
    final tier = json['tier'];
    final channel = json['channel'];
    final enabled = json['enabled'];
    final userDisableable = json['userDisableable'] ?? json['user_disableable'];
    if (tier is! String ||
        !_tiers.contains(tier) ||
        channel is! String ||
        !_channels.contains(channel) ||
        enabled is! bool ||
        userDisableable is! bool) {
      throw const FormatException('Malformed notification preference');
    }
    final canDisable = userDisableable && tier != 'SAFETY_CRITICAL';

    return NotificationPreferenceDto(
      tier: tier,
      channel: channel,
      // Treat the backend's non-disableable flag as authoritative even if a
      // stale stored row reports false for a SAFETY_CRITICAL preference.
      enabled: canDisable ? enabled : true,
      userDisableable: canDisable,
    );
  }

  final String tier;
  final String channel;
  final bool enabled;
  final bool userDisableable;

  factory NotificationPreferenceDto.fromEntity(NotificationPreference value) =>
      NotificationPreferenceDto(
        tier: value.tier,
        channel: value.channel,
        enabled: value.userDisableable ? value.enabled : true,
        userDisableable: value.userDisableable,
      );

  NotificationPreference toEntity() => NotificationPreference(
    tier: tier,
    channel: channel,
    enabled: enabled,
    userDisableable: userDisableable,
  );

  Map<String, dynamic> toJson() => {
    'tier': tier,
    'channel': channel,
    'enabled': userDisableable ? enabled : true,
  };
}
