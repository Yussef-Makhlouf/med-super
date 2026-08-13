import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/delivery_method.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/prescription_image.dart';

/// Images the patient has attached to the prescription on screen 1
/// ("تحميل الوصفة الطبية"). Starts empty on purpose — at least one image is
/// a hard requirement before the "إرسال للصيدلية" CTA activates (see
/// [canSubmitPrescriptionUploadProvider]).
class UploadedPrescriptionImages extends Notifier<List<PrescriptionImage>> {
  int _nextId = 0;

  @override
  List<PrescriptionImage> build() => const [];

  /// Appends every (path, bytes) pair in [files], preserving order — used
  /// by the multi-select file picker on the upload box / "+" tile.
  void addImages(Iterable<({String path, Uint8List? bytes})> files) {
    final additions = [
      for (final file in files)
        PrescriptionImage(
          id: '${_nextId++}',
          path: file.path,
          bytes: file.bytes,
        ),
    ];
    if (additions.isEmpty) return;
    state = [...state, ...additions];
  }

  /// Removes the image with [id] (tap on its red delete badge).
  void removeImage(String id) {
    state = state.where((image) => image.id != id).toList();
  }
}

final uploadedPrescriptionImagesProvider =
    NotifierProvider<UploadedPrescriptionImages, List<PrescriptionImage>>(
      UploadedPrescriptionImages.new,
    );

/// Which delivery method ("طريقة الاستلام") the patient wants. Defaults to
/// [DeliveryMethod.homeDelivery] — unlike the lab booking flow's service
/// type, the mockup shows this card pre-selected.
class SelectedDeliveryMethod extends Notifier<DeliveryMethod> {
  @override
  DeliveryMethod build() => DeliveryMethod.homeDelivery;

  void select(DeliveryMethod method) => state = method;
}

final selectedDeliveryMethodProvider =
    NotifierProvider<SelectedDeliveryMethod, DeliveryMethod>(
      SelectedDeliveryMethod.new,
    );

/// True once at least one prescription image is attached. Drives the
/// enabled/disabled state of the "إرسال للصيدلية" bottom CTA — the delivery
/// method always has a default, so it is not part of this gate.
final canSubmitPrescriptionUploadProvider = Provider<bool>((ref) {
  return ref.watch(uploadedPrescriptionImagesProvider).isNotEmpty;
});
