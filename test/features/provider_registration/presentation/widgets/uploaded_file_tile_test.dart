import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/provider_registration/domain/entities/uploaded_document.dart';
import 'package:med_super/features/provider_registration/presentation/widgets/uploaded_file_tile.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  testWidgets('renders file name and size for a PDF document', (tester) async {
    const document = UploadedDocument(
      id: '1',
      fileName: 'license.pdf',
      sizeBytes: 1024 * 1024 * 2,
      localPath: '/tmp/license.pdf',
      type: DocumentType.medicalLicense,
    );

    await pumpLocalizedApp(
      tester,
      UploadedFileTile(document: document, onRemove: () {}),
    );

    expect(find.text('license.pdf'), findsOneWidget);
    expect(find.textContaining('2.0 MB'), findsOneWidget);
    expect(find.byIcon(Icons.description_outlined), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows an image icon for .png/.jpg/.jpeg file names', (
    tester,
  ) async {
    const document = UploadedDocument(
      id: '2',
      fileName: 'photo.PNG',
      sizeBytes: 1024 * 512,
      localPath: '/tmp/photo.PNG',
      type: DocumentType.profilePhoto,
    );

    await pumpLocalizedApp(
      tester,
      UploadedFileTile(document: document, onRemove: () {}),
    );

    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    expect(find.byIcon(Icons.description_outlined), findsNothing);
  });

  testWidgets('invokes onRemove when the delete button is tapped', (
    tester,
  ) async {
    var removed = false;
    const document = UploadedDocument(
      id: '3',
      fileName: 'id.pdf',
      sizeBytes: 100,
      localPath: '/tmp/id.pdf',
      type: DocumentType.nationalId,
    );

    await pumpLocalizedApp(
      tester,
      UploadedFileTile(document: document, onRemove: () => removed = true),
    );

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();

    expect(removed, isTrue);
  });
}
