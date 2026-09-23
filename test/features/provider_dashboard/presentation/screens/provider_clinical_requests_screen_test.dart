import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/auth/domain/entities/user.dart';
import 'package:med_super/features/auth/domain/entities/user_role.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/provider_clinical_request.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/provider_clinical_request_providers.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_clinical_requests_screen.dart';
import '../../../../helpers/pump_localized_widget.dart';

class _DoctorSessionController extends SessionController {
  @override
  Future<Session?> build() async => Session(
    user: User(
      id: 'doctor-1',
      phone: '+201000000000',
      roles: [UserRole.doctor],
      activeRole: UserRole.doctor,
      displayName: 'Dr Test',
    ),
    onboardingComplete: true,
    passwordComplete: true,
  );
}

void main() {
  testWidgets('shows patient scoped prescription history and lab tab', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      const ProviderClinicalRequestsScreen(
        patientId: 'patient-1',
        patientName: 'Sara',
      ),
      overrides: [
        sessionControllerProvider.overrideWith(_DoctorSessionController.new),
        providerPrescriptionsProvider.overrideWith((ref) async => const []),
        providerPharmacyOrdersProvider.overrideWith((ref) async => const []),
        providerLabOrdersProvider.overrideWith((ref) async => const []),
      ],
    );

    await tester.pumpAndSettle();
    expect(find.text('الطلبات الطبية'), findsOneWidget);
    expect(find.text('إنشاء روشتة'), findsOneWidget);
    expect(
      find.text('لا توجد روشتات صادرة من فريق الرعاية حتى الآن.'),
      findsOneWidget,
    );

    await tester.tap(find.text('طلبات التحاليل'));
    await tester.pumpAndSettle();
    expect(find.text('طلب تحاليل'), findsOneWidget);
    expect(
      find.text('لا توجد طلبات تحاليل من فريق الرعاية حتى الآن.'),
      findsOneWidget,
    );
  });

  testWidgets('shows doctor signoff only for pending assistant prescription', (
    tester,
  ) async {
    final pending = ProviderPrescription(
      id: 'rx-1',
      patientId: 'patient-1',
      status: 'PENDING_DOCTOR_APPROVAL',
      version: 1,
      createdAt: DateTime.utc(2026, 9, 23),
      createdByRole: 'CLINIC_STAFF',
      items: const [
        ProviderPrescriptionItem(drugName: 'Medicine', quantity: 1),
      ],
    );
    await pumpLocalizedWidget(
      tester,
      const ProviderClinicalRequestsScreen(
        patientId: 'patient-1',
        patientName: 'Sara',
      ),
      overrides: [
        sessionControllerProvider.overrideWith(_DoctorSessionController.new),
        providerPrescriptionsProvider.overrideWith((ref) async => [pending]),
        providerPrescriptionDetailProvider.overrideWith(
          (ref, id) async => pending,
        ),
        providerPharmacyOrdersProvider.overrideWith((ref) async => const []),
        providerLabOrdersProvider.overrideWith((ref) async => const []),
      ],
    );

    await tester.pumpAndSettle();
    expect(find.text('اعتماد وتوقيع'), findsOneWidget);
    expect(find.text('رفض'), findsOneWidget);
  });
}
