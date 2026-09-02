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

  /// [images]' real bytes are never actually uploaded anywhere — no object
  /// storage exists yet for prescription photos (backend's
  /// `UploadPrescriptionDto.fileUrls` is deliberately pre-hosted-URL-only,
  /// DEC-009-gated/deferred, same as `ProviderVerificationDocument.file_url`).
  /// Each image is sent as a distinct placeholder URL just so the real
  /// endpoint's quality-check/OCR pipeline runs end-to-end against something
  /// — swap this for a real upload step once object storage is decided.
  Future<void> submit({
    required List<PrescriptionImage> images,
    String? notes,
  }) async {
    state = const AsyncLoading();
    final fileUrls = images
        .map((image) => 'https://placeholder.medsuper.local/prescriptions/${image.id}.jpg')
        .toList();
    state = await AsyncValue.guard(
      () => ref
          .read(prescriptionRemoteDatasourceProvider)
          .upload(fileUrls: fileUrls, notes: notes),
    );
  }
}

final prescriptionUploadControllerProvider =
    NotifierProvider<PrescriptionUploadController, AsyncValue<PrescriptionUploadResult?>>(
      PrescriptionUploadController.new,
    );
