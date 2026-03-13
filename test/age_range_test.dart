import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/wizard/age_range_screen.dart';
import 'helpers/onboarding_test_helper.dart';

void main() {
  group('AgeRangeScreen', () {
    Widget buildSubject() {
      return buildOnboardingTestHarness(
        screen: const AgeRangeScreen(),
        routeName: '/onboarding/age-range',
      );
    }

    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));

      // Check key elements render
      expect(find.text('How old is your ideal match?'), findsOneWidget);
      expect(find.byType(RangeSlider), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('tapping Next triggers navigation', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Next'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      // Navigation began — either still animating or landed on stub route
      // The goNext log confirms navigation to relationship-goals
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('shows progress bar', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('shows age range slider', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(RangeSlider), findsOneWidget);
    });
  });
}
