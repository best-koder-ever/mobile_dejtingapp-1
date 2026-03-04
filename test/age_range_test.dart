import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/wizard/age_range_screen.dart';
import 'package:dejtingapp/providers/onboarding_provider.dart';
import 'package:dejtingapp/models/onboarding_data.dart';
import 'package:dejtingapp/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('AgeRangeScreen renders without errors', (tester) async {
    final data = OnboardingData();
    
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        routes: {
          '/onboarding/relationship-goals': (_) => const Scaffold(body: Text('goals')),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/onboarding/age-range') {
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => OnboardingProvider(
                data: data,
                child: const AgeRangeScreen(),
              ),
            );
          }
          return null;
        },
        initialRoute: '/onboarding/age-range',
      ),
    );
    
    // Use pump(500ms) instead of pumpAndSettle to avoid stuck animations
    await tester.pump(const Duration(milliseconds: 500));
    
    // Check key elements render
    expect(find.text('How old is your ideal match?'), findsOneWidget);
    expect(find.byType(RangeSlider), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    
    print('✅ AgeRangeScreen renders correctly!');
    
    // Test tapping Next navigates
    await tester.tap(find.text('Next'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('goals'), findsOneWidget);
    print('✅ Navigation to relationship-goals works!');
  });
}
