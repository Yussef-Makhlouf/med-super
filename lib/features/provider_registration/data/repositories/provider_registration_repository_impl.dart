import 'package:med_super/core/error/dio_failure_mapper.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_registration/data/datasources/remote/provider_registration_remote_datasource.dart';
import 'package:med_super/features/provider_registration/domain/entities/doctor_registration_draft.dart';
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
    try {
      await _remote.submit(
        draft,
        specialtyLabel: specialtyLabel,
        cityLabel: cityLabel,
        phone: phone,
      );
      return const Result.ok(null);
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }
}
