import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/welcome_screen.dart';
import '../helpers/core_screen_test_helper.dart';

void main() {
  group('WelcomeScreen', () {
    testWidgets('renders scaffold', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const WelcomeScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('shows flame/fire icon', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const WelcomeScreen()),
      );
      await tester.pumpAndSettle();
      final hasFireIcon =
          find.byIcon(Icons.local_fire_department).evaluate().isNotEmpty ||
              find.byIcon(Icons.whatshot).evaluate().isNotEmpty;
      expect(hasFireIcon, isTrue);
    });

    testWidgets('shows at least one action button', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const WelcomeScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ElevatedButton), findsAtLeastNWidgets(1));
    });

    testWidgets('shows terms or privacy text', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const WelcomeScreen()),
      );
      await tester.pumpAndSettle();
      final hasLegalText =
          find.textContaining('Terms').evaluate().isNotEmpty ||
              find.textContaining('Privacy').evaluate().isNotEmpty ||
              find.textContaining('terms').evaluate().isNotEmpty ||
              find.textContaining('privacy').evaluate().isNotEmpty;
      expect(hasLegalText, isTrue);
    });
  });
}
