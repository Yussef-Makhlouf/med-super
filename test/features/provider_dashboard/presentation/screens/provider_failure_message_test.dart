import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/error/failure.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/provider_failure_message.dart';
import '../../../../helpers/pump_localized_widget.dart';

class _FailureMessage extends StatelessWidget {
  const _FailureMessage(this.failure);

  final Failure failure;

  @override
  Widget build(BuildContext context) => Text(providerFailureMessage(failure));
}

void main() {
  testWidgets('maps visit lifecycle server codes to localized provider copy', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      const _FailureMessage(
        Failure.validation({}, code: 'APPOINTMENT_VISIT_IN_PROGRESS'),
      ),
    );
    expect(
      find.text('لا يمكن إلغاء الموعد أو إعادة جدولته بعد بدء زيارة المريض.'),
      findsOneWidget,
    );

    await pumpLocalizedWidget(
      tester,
      const _FailureMessage(
        Failure.validation({}, code: 'VISIT_STATUS_TOO_EARLY'),
      ),
    );
    expect(
      find.text('لا يمكن تغيير حالة الزيارة قبل موعد المريض المسموح به.'),
      findsOneWidget,
    );

    await pumpLocalizedWidget(
      tester,
      const _FailureMessage(
        Failure.validation({}, code: 'VISIT_STATUS_OUTSIDE_APPOINTMENT_WINDOW'),
      ),
    );
    expect(
      find.text('تغيير حالة الزيارة متاح فقط خلال وقت الموعد المحدد.'),
      findsOneWidget,
    );
  });
}
