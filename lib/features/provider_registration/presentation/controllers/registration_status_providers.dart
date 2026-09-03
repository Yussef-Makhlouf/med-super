import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:med_super/features/provider_registration/domain/entities/doctor_registration_status.dart';
import 'package:med_super/features/provider_registration/presentation/controllers/registration_form_controller.dart';

part 'registration_status_providers.g.dart';

/// `GET /v1/provider/registration/status` via
/// `GetMyDoctorRegistrationStatusUseCase` — the pending-approval screen's
/// only source of truth for "has an Admin verified me yet?", since the
/// local `SettingsKeys.providerRegistrationSubmitted` flag only means "I
/// submitted the form," never "I was approved." `null` means the caller
/// never self-registered as a doctor at all (the endpoint's `404`).
/// Refetched via pull-to-refresh on that screen (autoDispose: navigating
/// away and back re-fetches too).
@riverpod
Future<DoctorRegistrationStatus?> doctorRegistrationStatus(Ref ref) async {
  final result = await ref
      .watch(myDoctorRegistrationStatusUseCaseProvider)
      .call();
  return result.when(ok: (value) => value, err: (failure) => throw failure);
}
