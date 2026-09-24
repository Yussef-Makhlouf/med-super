import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/auth/domain/entities/user.dart';
import 'package:med_super/features/auth/domain/entities/user_role.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_branch.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_branch_search_providers.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy_order_detail.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/pharmacy_search_providers.dart';
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
    expect(find.text('اعتماد وإرسال للصيدلية'), findsOneWidget);
    expect(find.text('اعتماد وتوقيع'), findsOneWidget);
    expect(find.text('رفض'), findsOneWidget);
  });

  testWidgets('shows the pharmacy quote, fulfillment, and status ownership', (
    tester,
  ) async {
    final prescription = ProviderPrescription(
      id: 'rx-quoted',
      patientId: 'patient-1',
      status: 'ACCEPTED',
      version: 1,
      createdAt: DateTime.utc(2026, 9, 23),
      createdByRole: 'DOCTOR',
      items: const [
        ProviderPrescriptionItem(drugName: 'Medicine', quantity: 1),
      ],
    );
    const order = PharmacyOrderDetail(
      id: 'order-1',
      patientId: 'patient-1',
      prescriptionId: 'rx-quoted',
      status: 'READY_FOR_PICKUP',
      fulfillmentType: 'CLINIC_HANDOVER',
      createdAt: '2026-09-23T10:00:00Z',
      updatedAt: '2026-09-23T10:30:00Z',
      pharmacyName: null,
      doctorName: null,
      quote: PharmacyOrderQuote(
        totalPrice: '125.00',
        currency: 'EGP',
        estimatedReadyMinutes: 30,
        note: 'Ready today',
        quotedAt: '2026-09-23T10:30:00Z',
      ),
      patientNote: null,
      staffNote: null,
      prescriptionImages: [],
      rejection: null,
    );

    await pumpLocalizedWidget(
      tester,
      const ProviderClinicalRequestsScreen(
        patientId: 'patient-1',
        patientName: 'Sara',
      ),
      overrides: [
        sessionControllerProvider.overrideWith(_DoctorSessionController.new),
        providerPrescriptionsProvider.overrideWith((ref) async => [prescription]),
        providerPrescriptionDetailProvider.overrideWith(
          (ref, id) async => prescription,
        ),
        providerPharmacyOrdersProvider.overrideWith((ref) async => [order]),
        providerLabOrdersProvider.overrideWith((ref) async => const []),
      ],
    );

    await tester.pumpAndSettle();
    expect(find.text('استلام من العيادة'), findsOneWidget);
    expect(find.text('تسعير الصيدلية'), findsOneWidget);
    expect(find.text('125.00 EGP'), findsOneWidget);
    expect(find.text('جهز هذا المبلغ قبل الاستلام.'), findsOneWidget);
    expect(
      find.text('يتم تحديث حالة تنفيذ الطلب من فريق الصيدلية.'),
      findsOneWidget,
    );
  });

  testWidgets('provider prescription form requests an image attachment', (
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
        pharmaciesProvider.overrideWith(
          (ref) async => const [
            Pharmacy(
              id: 'branch-1',
              name: 'El Dawaa Pharmacy',
              address: 'Cairo',
              deliveryCapable: true,
            ),
          ],
        ),
      ],
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('إنشاء روشتة'));
    await tester.pumpAndSettle();

    expect(find.text('إرفاق صور الروشتة أو طلب التحاليل'), findsOneWidget);
    expect(find.text('تجهيز طلب الصيدلية'), findsOneWidget);
    expect(find.text('استلام من الصيدلية'), findsOneWidget);
    expect(find.text('أرفق صورة واحدة على الأقل للمتابعة.'), findsNothing);
  });

  testWidgets('lab request form groups collection and branch selection', (
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
        labBranchesProvider.overrideWith(
          (ref) async => const [
            LabBranch(
              id: 'lab-1',
              name: 'Al Borg Lab',
              address: 'Cairo',
              homeCollectionCapable: true,
            ),
          ],
        ),
      ],
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('طلبات التحاليل'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('طلب تحاليل'));
    await tester.pumpAndSettle();

    expect(find.text('اختر طريقة السحب والفرع، ثم أرفق طلب التحاليل قبل الإرسال.'), findsOneWidget);
    expect(find.text('زيارة فرع المعمل'), findsOneWidget);
    expect(find.text('سحب العينة من المنزل'), findsOneWidget);
    expect(find.text('مرفقات طلب التحاليل'), findsOneWidget);
    expect(
      find.text('اختر فرع المعمل وأرفق صورة واحدة على الأقل للمتابعة.'),
      findsOneWidget,
    );
  });
}
