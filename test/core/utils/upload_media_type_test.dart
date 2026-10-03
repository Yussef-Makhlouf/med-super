import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/utils/upload_media_type.dart';

final _jpeg = Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10]);
final _png = Uint8List.fromList([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00]);
final _pdf = Uint8List.fromList('%PDF-1.7\n'.codeUnits);
// ISO-BMFF `ftyp` box with the `heic` brand, as an iPhone camera writes it.
final _heic = Uint8List.fromList([0, 0, 0, 0x18, ...'ftypheic'.codeUnits, 0, 0, 0, 0]);
final _webp = Uint8List.fromList([...'RIFF'.codeUnits, 0x24, 0, 0, 0, ...'WEBPVP8 '.codeUnits]);
final _gif = Uint8List.fromList('GIF89a'.codeUnits);

void main() {
  group('UploadMediaType.sniff (mirrors the backend signature check)', () {
    test('recognises JPEG, PNG and PDF by their bytes', () {
      expect(UploadMediaType.sniff(_jpeg), UploadMediaType.jpeg);
      expect(UploadMediaType.sniff(_png), UploadMediaType.png);
      expect(UploadMediaType.sniff(_pdf), UploadMediaType.pdf);
    });

    test('allows a PDF header within the first KiB, not after it', () {
      expect(UploadMediaType.sniff(Uint8List.fromList([...List.filled(200, 0x20), ..._pdf])), UploadMediaType.pdf);
      expect(UploadMediaType.sniff(Uint8List.fromList([...List.filled(1100, 0x20), ..._pdf])), isNull);
    });

    test('returns null for formats the backend refuses', () {
      expect(UploadMediaType.sniff(_heic), isNull);
      expect(UploadMediaType.sniff(_webp), isNull);
      expect(UploadMediaType.sniff(_gif), isNull);
      expect(UploadMediaType.sniff(const []), isNull);
      expect(UploadMediaType.sniff(Uint8List.fromList([0xff, 0xd8])), isNull);
    });

    test('only JPEG and PNG count as images', () {
      expect(UploadMediaType.jpeg.isImage, isTrue);
      expect(UploadMediaType.png.isImage, isTrue);
      expect(UploadMediaType.pdf.isImage, isFalse);
    });
  });

  group('UploadMediaType.forUpload', () {
    test('trusts the bytes over the file name', () {
      expect(UploadMediaType.forUpload(_png, 'IMG_0001.jpg').mimeType, 'image/png');
      expect(UploadMediaType.forUpload(_jpeg, 'scan.png').mimeType, 'image/jpeg');
      expect(UploadMediaType.forUpload(_pdf, 'referral').mimeType, 'application/pdf');
    });

    test('falls back to the extension when the bytes are unknown, so the server gives the refusal', () {
      expect(UploadMediaType.forUpload(_heic, 'IMG_0002.HEIC').mimeType, 'image/jpeg');
      expect(UploadMediaType.forUpload(_webp, 'x.png').mimeType, 'image/png');
    });
  });
}
