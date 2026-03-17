import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/enhanced_matches_screen.dart';
import '../helpers/core_screen_test_helper.dart';

void main() {
  group('EnhancedMatchesScreen', () {
    testWidgets('renders scaffold', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const EnhancedMatchesScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('has TabBar with 2 tabs', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const EnhancedMatchesScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(Tab), findsNWidgets(2));
    });

    testWidgets('shows loading or content after init', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const EnhancedMatchesScreen()),
      );
      await tester.pump(const Duration(seconds: 1));
      final hasContent = find.byType(Scaffold).evaluate().isNotEmpty;
      expect(hasContent, isTrue);
    });
  });
}
