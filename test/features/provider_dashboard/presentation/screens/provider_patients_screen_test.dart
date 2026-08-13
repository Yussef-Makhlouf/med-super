import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/core/network/dio_client.dart';
import 'package:med_super/core/storage/secure_storage_service.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_patients_screen.dart';

void main() {
  testWidgets(
      'ProviderPatientsScreen enters search query and taps filter chips',
      (tester) async {
    final storage = SecureStorageService(const FlutterSecureStorage());
    final dio = buildDioClient(storage: storage);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dioProvider.overrideWithValue(dio),
        ],
        child: const MaterialApp(
          home: ProviderPatientsScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('قائمة المرضى'), findsOneWidget);
    expect(find.text('قائمة المرضى المؤكدين'), findsOneWidget);

    // Enter search text into search field
    final searchField = find.byType(TextField);
    expect(searchField, findsOneWidget);
    await tester.enterText(searchField, 'سارة');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    // Tap filter chip 'اليوم'
    final todayChip = find.text('اليوم');
    expect(todayChip, findsOneWidget);
    await tester.tap(todayChip);
    await tester.pumpAndSettle();
  });
}
