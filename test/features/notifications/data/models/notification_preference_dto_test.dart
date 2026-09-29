import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/notifications/data/models/notification_preference_dto.dart';
import 'package:med_super/features/notifications/domain/entities/notification_preference.dart';

void main() {
  test('maps backend preference fields to the domain entity', () {
    final dto = NotificationPreferenceDto.fromJson({
      'tier': 'MARKETING',
      'channel': 'PUSH',
      'enabled': false,
      'userDisableable': true,
    });

    expect(dto.toEntity().tier, 'MARKETING');
    expect(dto.toEntity().channel, 'PUSH');
    expect(dto.toEntity().enabled, isFalse);
    expect(dto.toEntity().userDisableable, isTrue);
  });

  test(
    'locks safety-critical rows on read and never serializes them disabled',
    () {
      final dto = NotificationPreferenceDto.fromJson({
        'tier': 'SAFETY_CRITICAL',
        'channel': 'SMS',
        'enabled': false,
        'userDisableable': false,
      });
      final attemptedDisable = NotificationPreference(
        tier: 'SAFETY_CRITICAL',
        channel: 'PUSH',
        enabled: false,
        userDisableable: false,
      );

      expect(dto.toEntity().effectiveEnabled, isTrue);
      expect(NotificationPreferenceDto.fromEntity(attemptedDisable).toJson(), {
        'tier': 'SAFETY_CRITICAL',
        'channel': 'PUSH',
        'enabled': true,
      });
    },
  );

  test('rejects a malformed row instead of silently omitting a toggle', () {
    expect(
      () => NotificationPreferenceDto.fromJson({
        'tier': 'MARKETING',
        'channel': 'PUSH',
        'enabled': 'false',
        'userDisableable': true,
      }),
      throwsFormatException,
    );
  });
}
