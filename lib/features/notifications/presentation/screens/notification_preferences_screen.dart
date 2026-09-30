import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/error/failure_message.dart';
import 'package:med_super/core/theme/app_palette.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import 'package:med_super/core/widgets/skeleton_loader.dart';
import 'package:med_super/features/notifications/domain/entities/notification_preference.dart';
import 'package:med_super/features/notifications/presentation/controllers/notification_providers.dart';

class NotificationPreferencesScreen extends ConsumerWidget {
  const NotificationPreferencesScreen({super.key});

  static const _tiers = [
    'TRANSACTIONAL',
    'INFORMATIONAL',
    'SAFETY_CRITICAL',
    'MARKETING',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(notificationPreferencesControllerProvider);
    final controller = ref.read(
      notificationPreferencesControllerProvider.notifier,
    );

    return Scaffold(
      backgroundColor: AppPalette.paper,
      appBar: AppBar(
        backgroundColor: AppPalette.paper,
        scrolledUnderElevation: 0,
        title: Text('notifications.preferences_title'.tr()),
      ),
      body: AsyncValueView<NotificationPreferencesState>(
        value: asyncState,
        loadingWidget: const CardSkeletonList(count: 4),
        onRetry: controller.refresh,
        data: (state) => Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.refresh,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.only(bottom: 14),
                      child: Text(
                        'notifications.preferences_description'.tr(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppPalette.inkMuted,
                        ),
                      ),
                    ),
                    for (final tier in _tiers)
                      _TierCard(
                        tier: tier,
                        preferences: state.preferences
                            .where((preference) => preference.tier == tier)
                            .toList(growable: false),
                        isSaving: state.isSaving,
                        onChanged: controller.setEnabled,
                      ),
                    if (state.saveFailure != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          failureMessageOf(state.saveFailure!),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: state.isDirty && !state.isSaving
                        ? controller.save
                        : null,
                    child: state.isSaving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('notifications.save_preferences'.tr()),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.tier,
    required this.preferences,
    required this.isSaving,
    required this.onChanged,
  });

  final String tier;
  final List<NotificationPreference> preferences;
  final bool isSaving;
  final void Function(NotificationPreference preference, bool enabled)
  onChanged;

  @override
  Widget build(BuildContext context) {
    if (preferences.isEmpty) return const SizedBox.shrink();
    final locked = preferences.any((preference) => !preference.userDisableable);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppPalette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'notifications.tiers.$tier'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppPalette.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (locked)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'notifications.critical_always_on'.tr(),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppPalette.inkMuted),
                ),
              ),
            for (final preference in preferences)
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'notifications.channels.${preference.channel}'.tr(),
                ),
                value: preference.effectiveEnabled,
                onChanged: preference.userDisableable && !isSaving
                    ? (enabled) => onChanged(preference, enabled)
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}
