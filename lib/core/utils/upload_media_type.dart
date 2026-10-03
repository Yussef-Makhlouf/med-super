import 'package:http_parser/http_parser.dart';

/// The upload formats the backend accepts, identified by the file's own
/// leading bytes — the same signatures `clinic-reservations` checks before
/// storing anything (`media-file-validator.ts`), so a file labelled here is
/// never refused there as `FILE_CONTENT_MISMATCH`.
///
/// Extensions are not trusted: a picked photo can be HEIC or WebP whatever
/// its name says, and a renamed file keeps its real content.
enum UploadMediaType {
  jpeg('image', 'jpeg'),
  png('image', 'png'),
  pdf('application', 'pdf');

  const UploadMediaType(this.type, this.subtype);

  final String type;
  final String subtype;

  String get mimeType => '$type/$subtype';
  MediaType get mediaType => MediaType(type, subtype);
  bool get isImage => this != UploadMediaType.pdf;

  static const _png = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
  static const _pdf = [0x25, 0x50, 0x44, 0x46, 0x2d]; // %PDF-

  /// `null` for anything the backend would refuse (HEIC, WebP, GIF, ...).
  static UploadMediaType? sniff(List<int> bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return UploadMediaType.jpeg;
    }
    if (_startsWith(bytes, _png, 0)) return UploadMediaType.png;
    // A PDF header may follow up to 1 KiB of leading bytes (the backend
    // allows the same tolerance).
    final limit = bytes.length < 1024 ? bytes.length : 1024;
    for (var i = 0; i + _pdf.length <= limit; i++) {
      if (_startsWith(bytes, _pdf, i)) return UploadMediaType.pdf;
    }
    return null;
  }

  /// Picks the label for an upload: the sniffed type when known, else the
  /// extension's (the server then gives the definitive refusal).
  static MediaType forUpload(List<int> bytes, String fileName) {
    final sniffed = sniff(bytes);
    if (sniffed != null) return sniffed.mediaType;
    return switch (fileName.toLowerCase().split('.').last) {
      'png' => UploadMediaType.png.mediaType,
      'pdf' => UploadMediaType.pdf.mediaType,
      _ => UploadMediaType.jpeg.mediaType,
    };
  }

  static bool _startsWith(List<int> bytes, List<int> prefix, int offset) {
    if (bytes.length < offset + prefix.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (bytes[offset + i] != prefix[i]) return false;
    }
    return true;
  }
}
