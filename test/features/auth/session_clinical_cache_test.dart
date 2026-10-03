import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/core/notifications/fcm_service.dart';
import 'package:med_super/core/notifications/push_notification_coordinator.dart';
import 'package:med_super/core/storage/hive_service.dart';
import 'package:med_super/features/auth/domain/entities/auth_tokens.dart';
import 'package:med_super/features/auth/domain/entities/user.dart';
import 'package:med_super/features/auth/domain/entities/user_role.dart';
import 'package:med_super/features/auth/domain/repositories/auth_repository.dart';
import 'package:med_super/features/auth/presentation/controllers/auth_providers.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_order_detail.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_order_list_providers.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/provider_clinical_request.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/provider_clinical_request_providers.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy_order_detail.dart';
import 'package:mocktail/mocktail.dart';

class _Hive extends Mock implements HiveService {}
class _Box extends Mock implements Box<String> {}
class _Fcm extends Mock implements FcmService {}
class _Push extends Mock implements PushNotificationCoordinator {}
class _Auth extends Mock implements AuthRepository {}
class _LabOrder extends Mock implements LabOrderDetail {}
class _Prescription extends Mock implements ProviderPrescription {}
class _PharmacyOrder extends Mock implements PharmacyOrderDetail {}

User _user(String id) => User(
  id: id, phone: '+201000000000', roles: [UserRole.patient],
  activeRole: UserRole.patient, displayName: 'Fixture', email: 'fixture@example.test',
);

class _SessionController extends SessionController {
  @override
  Future<Session?> build() async => Session(
    user: _user('account-a'), onboardingComplete: true, passwordComplete: true,
  );
}

void main() {
  test('logout and another login refetch all retained clinical caches', () async {
    final hive = _Hive();
    final settings = _Box();
    final draft = _Box();
    final fcm = _Fcm();
    final push = _Push();
    final auth = _Auth();
    var account = 'account-a';
    final requests = <String, int>{};

    when(() => hive.settingsBox).thenReturn(settings);
    when(() => hive.providerRegistrationDraftBox).thenReturn(draft);
    when(() => settings.get(any())).thenReturn('true');
    when(() => settings.put(any(), any())).thenAnswer((_) async {});
    when(() => settings.delete(any())).thenAnswer((_) async {});
    when(() => draft.get(any())).thenReturn(null);
    when(() => draft.delete(any())).thenAnswer((_) async {});
    when(() => fcm.token).thenAnswer((_) async => null);
    when(() => fcm.deleteToken()).thenAnswer((_) async {});
    when(() => push.stop()).thenAnswer((_) async {});
    when(() => push.start()).thenAnswer((_) async => false);
    when(() => auth.logout()).thenAnswer((_) async => const Result.ok(null));
    when(() => auth.loginWithPassword(
      phone: any(named: 'phone'), password: any(named: 'password'), role: UserRole.patient,
    )).thenAnswer((_) async => const Result.ok(AuthTokens(
      accessToken: 'fixture-access', refreshToken: 'fixture-refresh',
    )));
    when(() => auth.getCurrentUser()).thenAnswer((_) async => Result.ok(_user(account)));

    String mark(String key) {
      requests.update(key, (count) => count + 1, ifAbsent: () => 1);
      return account;
    }
    LabOrderDetail lab(String key) {
      final order = _LabOrder();
      when(() => order.id).thenReturn(mark(key));
      return order;
    }
    ProviderPrescription prescription(String key) {
      final value = _Prescription();
      when(() => value.id).thenReturn(mark(key));
      return value;
    }
    final container = ProviderContainer(overrides: [
      sessionControllerProvider.overrideWith(_SessionController.new),
      hiveServiceProvider.overrideWithValue(hive),
      fcmServiceProvider.overrideWithValue(fcm),
      pushNotificationCoordinatorProvider.overrideWithValue(push),
      authRepositoryProvider.overrideWithValue(auth),
      labOrdersProvider.overrideWith((ref) async => [lab('patient-lab-list')]),
      labOrderDetailProvider.overrideWith((ref, id) async => lab('patient-lab-detail')),
      providerPrescriptionsProvider.overrideWith((ref) async => [prescription('prescription-list')]),
      providerPrescriptionDetailProvider.overrideWith((ref, id) async => prescription('prescription-detail')),
      providerLabOrdersProvider.overrideWith((ref) async => [lab('provider-lab-list')]),
      providerPharmacyOrdersProvider.overrideWith((ref) async {
        final value = _PharmacyOrder();
        when(() => value.id).thenReturn(mark('provider-pharmacy-list'));
        return [value];
      }),
    ]);
    addTearDown(container.dispose);
    await container.read(sessionControllerProvider.future);

    Future<List<String>> cacheOwners() async => [
      (await container.read(labOrdersProvider.future)).single.id,
      (await container.read(labOrderDetailProvider('fixture-id').future)).id,
      (await container.read(providerPrescriptionsProvider.future)).single.id,
      (await container.read(providerPrescriptionDetailProvider('fixture-id').future)).id,
      (await container.read(providerLabOrdersProvider.future)).single.id,
      (await container.read(providerPharmacyOrdersProvider.future)).single.id,
    ];

    expect(await cacheOwners(), everyElement('account-a'));
    // Reading again within the same identity retains valid cached data.
    expect(await cacheOwners(), everyElement('account-a'));
    expect(requests.values, everyElement(1));

    await container.read(sessionControllerProvider.notifier).logout();
    expect(container.read(sessionControllerProvider).asData?.value, isNull);
    account = 'account-b';
    final login = await container.read(sessionControllerProvider.notifier).loginWithPassword(
      phone: '+201000000000', password: 'fixture-password', role: UserRole.patient,
    );
    expect(login, isA<Ok<Session>>());
    expect(await cacheOwners(), everyElement('account-b'));
    expect(requests.values, everyElement(2));
  });
}
