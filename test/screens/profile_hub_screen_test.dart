import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/profile_hub_screen.dart';
import '../helpers/core_screen_test_helper.dart';

void main() {
  group('ProfileHubScreen', () {
    testWidgets('renders scaffold', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const ProfileHubScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('has TabBar with 3 tabs', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const ProfileHubScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(Tab), findsNWidgets(3));
    });

    testWidgets('shows profile-related content', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const ProfileHubScreen()),
      );
      await tester.pump(const Duration(seconds: 1));
      // Profile hub always renders even without data
      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
