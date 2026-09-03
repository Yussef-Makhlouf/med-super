import 'dart:typed_data';

/// A single image attached to the prescription during the upload step.
///
/// [path] is either a local file-system path (image just picked on-device,
/// not uploaded yet) or a remote URL once the upload usecase persists it.
/// [bytes] is the raw image data read at pick time — kept alongside [path]
/// so the thumbnail can render via `Image.memory` on every platform
/// (`dart:io`'s `File`/`Image.file` doesn't work on Flutter Web, where
/// [path] is just a display name, not a real filesystem path).
class PrescriptionImage {
  const PrescriptionImage({required this.id, required this.path, this.bytes});

  final String id;
  final String path;
  final Uint8List? bytes;
}
