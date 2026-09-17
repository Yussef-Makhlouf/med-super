import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/provider_registration/domain/entities/uploaded_document.dart';

void main() {
  group('UploadedDocument', () {
    test('sizeMb converts bytes to megabytes', () {
      const doc = UploadedDocument(
        id: '1',
        fileName: 'license.pdf',
        sizeBytes: 1024 * 1024 * 3,
        localPath: '/tmp/license.pdf',
        type: DocumentType.medicalLicense,
      );

      expect(doc.sizeMb, 3.0);
    });

    test('sizeMb handles zero bytes', () {
      const doc = UploadedDocument(
        id: '2',
        fileName: 'empty.pdf',
        sizeBytes: 0,
        localPath: '/tmp/empty.pdf',
        type: DocumentType.nationalId,
      );

      expect(doc.sizeMb, 0.0);
    });

    test('sizeMb handles fractional megabytes', () {
      const doc = UploadedDocument(
        id: '3',
        fileName: 'photo.png',
        sizeBytes: 512 * 1024,
        localPath: '/tmp/photo.png',
        type: DocumentType.profilePhoto,
      );

      expect(doc.sizeMb, 0.5);
    });

    test('exposes every field and DocumentType value round-trips', () {
      for (final type in DocumentType.values) {
        final doc = UploadedDocument(
          id: 'id-${type.name}',
          fileName: '${type.name}.pdf',
          sizeBytes: 100,
          localPath: '/tmp/${type.name}.pdf',
          type: type,
        );
        expect(doc.type, type);
        expect(doc.id, 'id-${type.name}');
        expect(doc.fileName, '${type.name}.pdf');
        expect(doc.localPath, '/tmp/${type.name}.pdf');
        expect(doc.sizeBytes, 100);
      }
    });
  });
}
