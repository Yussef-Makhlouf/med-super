import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_request_image.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_service_type.dart';

part 'lab_upload_providers.g.dart';

/// Images the patient has attached to the lab request on screen 1
/// ("تحميل طلب المختبر"). Starts empty on purpose — at least one image is a
/// hard requirement before the "اختيار المختبر" CTA activates (see
/// [canContinueFromUploadProvider]).
@riverpod
class UploadedLabRequestImages extends _$UploadedLabRequestImages {
  int _nextId = 0;

  @override
  List<LabRequestImage> build() => const [];

  /// Appends a single freshly-picked image, identified by its local path
  /// (or a remote URL once/if the app starts uploading eagerly) plus the
  /// raw bytes needed to render it via `Image.memory` on every platform.
  void addImage(String path, [Uint8List? bytes]) {
    state = [
      ...state,
      LabRequestImage(id: '${_nextId++}', path: path, bytes: bytes),
    ];
  }

  /// Appends every (path, bytes) pair in [files], preserving order — used
  /// by the multi-select file picker on the upload box / "+" tile.
  void addImages(Iterable<({String path, Uint8List? bytes})> files) {
    final additions = [
      for (final file in files)
        LabRequestImage(id: '${_nextId++}', path: file.path, bytes: file.bytes),
    ];
    if (additions.isEmpty) return;
    state = [...state, ...additions];
  }

  /// Removes the image with [id] (tap on its red delete badge).
  void removeImage(String id) {
    state = state.where((image) => image.id != id).toList();
  }
}

/// Which service type ("نوع الخدمة") the patient picked. Deliberately has
/// no default value — the Figma mockup shows a card pre-selected, but the
/// plan explicitly calls for no default so the continue CTA stays disabled
/// until the patient makes an explicit choice.
@riverpod
class SelectedLabServiceType extends _$SelectedLabServiceType {
  @override
  LabServiceType? build() => null;

  void select(LabServiceType type) => state = type;
}

/// True once both screen-1 disable-conditions are satisfied: at least one
/// image attached AND a service type chosen. Drives the enabled/disabled
/// state of the "اختيار المختبر" bottom CTA.
@riverpod
bool canContinueFromUpload(Ref ref) {
  final hasImage = ref.watch(uploadedLabRequestImagesProvider).isNotEmpty;
  final hasServiceType = ref.watch(selectedLabServiceTypeProvider) != null;
  return hasImage && hasServiceType;
}
