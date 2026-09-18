import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/features/pharmacy_booking/data/datasources/remote/prescription_remote_datasource.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/prescription_image.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/prescription_upload_result.dart';

final prescriptionRemoteDatasourceProvider = Provider<PrescriptionRemoteDatasource>(
  (ref) => PrescriptionRemoteDatasource(ref.watch(dioProvider)),
);

/// Drives `POST /v1/prescriptions/upload` from the upload screen's submit
/// button. `AsyncValue<PrescriptionUploadResult?>` doubles as both the
/// submitting/error state (`AsyncLoading`/`AsyncError`) and the last
/// successful result — `null` data means "not submitted yet", not a failure.
class PrescriptionUploadController extends Notifier<AsyncValue<PrescriptionUploadResult?>> {
  @override
  AsyncValue<PrescriptionUploadResult?> build() => const AsyncData(null);

  /// [images]' real bytes are now uploaded via `multipart/form-data` and
  /// stored in ImageKit (`prescriptions/<patientId>`, private — DEC-009 is
  /// resolved), matching `PrescriptionRemoteDatasource.upload`.
  Future<void> submit({
    required List<PrescriptionImage> images,
    String? notes,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(prescriptionRemoteDatasourceProvider)
          .upload(images: images, notes: notes),
    );
  }
}

final prescriptionUploadControllerProvider =
    NotifierProvider<PrescriptionUploadController, AsyncValue<PrescriptionUploadResult?>>(
      PrescriptionUploadController.new,
    );
