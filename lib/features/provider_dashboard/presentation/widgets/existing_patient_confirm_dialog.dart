import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Before a walk-in booking submits a phone number that already belongs to
/// an account under a different name, this confirms clinic staff actually
/// mean that existing patient — the backend reuses the account as-is and
/// never renames it, so a false "yes" here would book a real appointment
/// onto the wrong patient's record.
///
/// Returns `true` if staff confirm it's the same patient, `false`/`null`
/// otherwise (caller should keep editing the phone number).
Future<bool?> showExistingPatientConfirmDialog(
  BuildContext context, {
  required String existingName,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('provider_dashboard.walk_in.existing_patient_title'.tr()),
      content: Text(
        'provider_dashboard.walk_in.existing_patient_message'.tr(
          namedArgs: {'name': existingName},
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'provider_dashboard.walk_in.existing_patient_deny'.tr(),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            'provider_dashboard.walk_in.existing_patient_confirm'.tr(),
          ),
        ),
      ],
    ),
  );
}
