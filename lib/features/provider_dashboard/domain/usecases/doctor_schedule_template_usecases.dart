import 'package:med_super/core/error/result.dart';
import '../entities/doctor_schedule_template.dart';
import '../repositories/provider_dashboard_repository.dart';

/// `GET /v1/doctors/me/schedule-templates`. Omitting [affiliationId] returns
/// every affiliation the caller owns.
class GetMyScheduleTemplatesUseCase {
  const GetMyScheduleTemplatesUseCase(this._repository);

  final ProviderDashboardRepository _repository;

  Future<Result<List<DoctorScheduleTemplate>>> call({String? affiliationId}) {
    return _repository.getMyScheduleTemplates(affiliationId: affiliationId);
  }
}

/// `POST /v1/doctors/me/schedule-templates`.
class CreateMyScheduleTemplateUseCase {
  const CreateMyScheduleTemplateUseCase(this._repository);

  final ProviderDashboardRepository _repository;

  Future<Result<DoctorScheduleTemplate>> call(
    NewDoctorScheduleTemplate template,
  ) {
    return _repository.createMyScheduleTemplate(template);
  }
}

/// `PATCH /v1/doctors/me/schedule-templates/{id}`.
///
/// Pass the `version` from the row being edited to get a `409` on a
/// concurrent change instead of silently overwriting it.
class UpdateMyScheduleTemplateUseCase {
  const UpdateMyScheduleTemplateUseCase(this._repository);

  final ProviderDashboardRepository _repository;

  Future<Result<DoctorScheduleTemplate>> call({
    required String templateId,
    required DoctorScheduleTemplatePatch patch,
  }) {
    return _repository.updateMyScheduleTemplate(
      templateId: templateId,
      patch: patch,
    );
  }
}

/// `DELETE /v1/doctors/me/schedule-templates/{id}`.
///
/// Stops future slot generation from this window. Slots already generated —
/// including ones patients hold or have booked — are deliberately untouched.
class DeleteMyScheduleTemplateUseCase {
  const DeleteMyScheduleTemplateUseCase(this._repository);

  final ProviderDashboardRepository _repository;

  Future<Result<void>> call({required String templateId, int? version}) {
    return _repository.deleteMyScheduleTemplate(
      templateId: templateId,
      version: version,
    );
  }
}
