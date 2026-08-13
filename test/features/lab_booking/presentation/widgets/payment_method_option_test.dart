import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_payment_method.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/payment_method_option.dart';

import '../../../../helpers/pump_localized_widget.dart';

void main() {
  testWidgets('renders a radio + icon for the online-payment option', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      RadioGroup<LabPaymentMethod>(
        groupValue: LabPaymentMethod.onlinePayment,
        onChanged: (_) {},
        child: const PaymentMethodOption(
          method: LabPaymentMethod.onlinePayment,
          isSelected: true,
          onSelected: _noop,
        ),
      ),
    );

    expect(find.byType(Radio<LabPaymentMethod>), findsOneWidget);
    expect(find.byIcon(Icons.credit_card), findsOneWidget);
    // `pumpLocalizedWidget`'s placeholder-then-swap dance (see its own doc
    // comment) guarantees translations are resolved by the time this
    // assertion runs — other lab_booking widget/screen tests rely on the
    // same guarantee (e.g. `lab_partner_card_test.dart`,
    // `lab_request_upload_screen_test.dart`), so assert the real translated
    // label/subtitle here too rather than only the structural elements —
    // this is what would actually catch a wrong copy string.
    expect(
      find.text(LabPaymentMethod.onlinePayment.labelKey.tr()),
      findsOneWidget,
    );
    expect(
      find.text(LabPaymentMethod.onlinePayment.subtitleKey.tr()),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'renders the pay-at-service icon and translated copy for that option',
    (tester) async {
      await pumpLocalizedWidget(
        tester,
        RadioGroup<LabPaymentMethod>(
          groupValue: LabPaymentMethod.onlinePayment,
          onChanged: (_) {},
          child: const PaymentMethodOption(
            method: LabPaymentMethod.payAtService,
            isSelected: false,
            onSelected: _noop,
          ),
        ),
      );

      expect(find.byIcon(Icons.payments_outlined), findsOneWidget);
      expect(
        find.text(LabPaymentMethod.payAtService.labelKey.tr()),
        findsOneWidget,
      );
      expect(
        find.text(LabPaymentMethod.payAtService.subtitleKey.tr()),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('tapping the row invokes onSelected', (tester) async {
    var tapped = false;
    await pumpLocalizedWidget(
      tester,
      RadioGroup<LabPaymentMethod>(
        groupValue: LabPaymentMethod.onlinePayment,
        onChanged: (_) {},
        child: PaymentMethodOption(
          method: LabPaymentMethod.payAtService,
          isSelected: false,
          onSelected: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.payments_outlined));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });
}

void _noop() {}
