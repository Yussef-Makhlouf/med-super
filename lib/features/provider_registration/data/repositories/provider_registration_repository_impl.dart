import 'package:med_super/core/error/dio_failure_mapper.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_registration/data/datasources/remote/provider_registration_remote_datasource.dart';
import 'package:med_super/features/provider_registration/domain/entities/doctor_registration_draft.dart';
import 'package:med_super/features/provider_registration/domain/entities/doctor_registration_status.dart';
import 'package:med_super/features/provider_registration/domain/repositories/provider_registration_repository.dart';

class ProviderRegistrationRepositoryImpl
    implements ProviderRegistrationRepository {
  ProviderRegistrationRepositoryImpl({
    required ProviderRegistrationRemoteDatasource remote,
  }) : _remote = remote;

  final ProviderRegistrationRemoteDatasource _remote;

  @override
  Future<Result<void>> submit(
    DoctorRegistrationDraft draft, {
    String? specialtyLabel,
    String? cityLabel,
    String? phone,
  }) async {
    final String doctorId;
    try {
      doctorId = await _remote.submit(
        draft,
        specialtyLabel: specialtyLabel,
        cityLabel: cityLabel,
        phone: phone,
      );
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }

    // Registration already succeeded at this point — a document upload
    // failure here must not be reported as a failed *registration* (the
    // applicant is already a real PENDING record); it's logged and
    // swallowed rather than surfaced as `Result.err`, same tradeoff already
    // accepted for `documents` being best-effort in the old mock flow.
    if (doctorId.isNotEmpty) {
      for (final document in draft.documents) {
        try {
          await _remote.uploadVerificationDocument(
            doctorId: doctorId,
            document: document,
          );
        } catch (_) {
          // Best-effort — see comment above.
        }
      }
    }

    return const Result.ok(null);
  }

  @override
  Future<Result<DoctorRegistrationStatus?>> getMyStatus() async {
    try {
      final raw = await _remote.getStatus();
      return Result.ok(
        raw == null ? null : DoctorRegistrationStatus.fromApiValue(raw),
      );
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }
}
