import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/profile_detail_screen.dart';
import 'package:dejtingapp/models.dart';
import '../helpers/core_screen_test_helper.dart';

MatchCandidate _dummyCandidate() => MatchCandidate(
      userId: 'test-user-1',
      displayName: 'Alice',
      age: 28,
      bio: 'Coffee lover & adventurer',
      city: 'Stockholm',
      compatibility: 0.85,
      interestsOverlap: ['hiking', 'coffee'],
      occupation: 'Engineer',
      isVerified: true,
    );

void main() {
  setUpAll(() => setupTestHttpOverrides());

  group('ProfileDetailScreen', () {
    testWidgets('renders scaffold with candidate', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: ProfileDetailScreen(candidate: _dummyCandidate()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('shows placeholder with first letter when no photos', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: ProfileDetailScreen(candidate: _dummyCandidate()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      // No photos => placeholder shows first letter of name
      expect(find.text('A'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows bio text', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: ProfileDetailScreen(candidate: _dummyCandidate()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('Coffee lover'), findsOneWidget);
    });

    testWidgets('shows interests', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: ProfileDetailScreen(candidate: _dummyCandidate()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('hiking'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows compatibility badge', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: ProfileDetailScreen(candidate: _dummyCandidate()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('85'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows Like and Skip buttons when not matched', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: ProfileDetailScreen(
            candidate: _dummyCandidate(),
            isMatched: false,
            onLike: () {},
            onSkip: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(IconButton), findsAtLeastNWidgets(1));
    });
  });
}
