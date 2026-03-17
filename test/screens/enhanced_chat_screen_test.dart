import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/enhanced_chat_screen.dart';
import 'package:dejtingapp/models.dart';
import '../helpers/core_screen_test_helper.dart';

Match _dummyMatch() => Match(
      id: 'match-1',
      userId1: 'user-1',
      userId2: 'user-2',
      matchedAt: DateTime(2026, 3, 15),
      isActive: true,
      otherUserProfile: UserProfile(
        id: '1',
        userId: 'user-2',
        firstName: 'Bob',
        lastName: 'Smith',
        dateOfBirth: DateTime(1995, 5, 10),
        bio: 'Music lover',
        city: 'Gothenburg',
      ),
    );

void main() {
  setUpAll(() => setupTestHttpOverrides());

  group('EnhancedChatScreen', () {
    testWidgets('renders scaffold with match', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: EnhancedChatScreen(match: _dummyMatch()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('shows other user name in app bar', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: EnhancedChatScreen(match: _dummyMatch()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('Bob'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows text input field', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: EnhancedChatScreen(match: _dummyMatch()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(TextField), findsAtLeastNWidgets(1));
    });

    testWidgets('shows send button', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: EnhancedChatScreen(match: _dummyMatch()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byIcon(Icons.send), findsOneWidget);
    });
  });
}
