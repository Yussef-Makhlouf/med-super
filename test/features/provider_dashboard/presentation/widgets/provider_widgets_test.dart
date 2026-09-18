import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/provider_bottom_nav_bar.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/provider_page_header.dart';
import 'package:solar_icons/solar_icons.dart';
import '../../../../helpers/pump_localized_widget.dart';

void main() {
  testWidgets('ProviderBottomNavBar renders items and triggers callback', (
    tester,
  ) async {
    int tappedIndex = -1;

    await pumpLocalizedWidget(
      tester,
      Scaffold(
        bottomNavigationBar: ProviderBottomNavBar(
          selectedIndex: 0,
          onDestinationSelected: (index) => tappedIndex = index,
        ),
      ),
    );

    expect(find.text('الرئيسية'), findsAtLeastNWidgets(1));
    expect(find.text('المواعيد'), findsAtLeastNWidgets(1));
    expect(find.text('المرضى'), findsAtLeastNWidgets(1));
    expect(find.text('الملف الشخصي'), findsAtLeastNWidgets(1));

    await tester.tap(find.byIcon(SolarIconsOutline.usersGroupRounded));
    expect(tappedIndex, 2);
  });

  testWidgets('ProviderPageHeader renders title and triggers avatar tap', (
    tester,
  ) async {
    bool avatarTapped = false;

    await pumpLocalizedWidget(
      tester,
      ProviderPageHeader(
        title: 'عنوان الصفحة',
        onAvatarTap: () => avatarTapped = true,
      ),
    );

    expect(find.text('عنوان الصفحة'), findsOneWidget);
    await tester.tap(find.byType(CircleAvatar));
    expect(avatarTapped, isTrue);
  });
}
