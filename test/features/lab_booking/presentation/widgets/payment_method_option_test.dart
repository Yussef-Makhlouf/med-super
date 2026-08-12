import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_payment_method.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/payment_method_option.dart';

import '../../../../helpers/pump_localized_widget.dart';

void main() {
  testWidgets('renders a radio for the method inside its group', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      RadioGroup<LabPaymentMethod>(
        groupValue: LabPaymentMethod.creditCard,
        onChanged: (_) {},
        child: const PaymentMethodOption(
          method: LabPaymentMethod.creditCard,
          isSelected: true,
          onSelected: _noop,
        ),
      ),
    );

    // The label is `.tr()`-resolved, which — per the same translation
    // -timing caveat noted throughout this codebase's tests (see
    // test/helpers/pump_localized_widget.dart) — can fall back to the raw
    // key; assert the structural elements (icon, radio) instead.
    expect(find.byType(Radio<LabPaymentMethod>), findsOneWidget);
    expect(find.byIcon(Icons.credit_card), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping the row invokes onSelected', (tester) async {
    var tapped = false;
    await pumpLocalizedWidget(
      tester,
      RadioGroup<LabPaymentMethod>(
        groupValue: LabPaymentMethod.creditCard,
        onChanged: (_) {},
        child: PaymentMethodOption(
          method: LabPaymentMethod.applePay,
          isSelected: false,
          onSelected: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.phone_iphone));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });
}

void _noop() {}
