import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/widgets/voice/voice_chat_recorder.dart';
import '../../helpers/core_screen_test_helper.dart';

void main() {
  setUpAll(() => setupTestHttpOverrides());

  Widget buildRecorder({
    Future<void> Function(String, double)? onSend,
    VoidCallback? onCancel,
  }) {
    return buildCoreScreenTestApp(
      home: Scaffold(
        body: Center(
          child: VoiceChatRecorder(
            onSend: onSend,
            onCancel: onCancel,
          ),
        ),
      ),
    );
  }

  group('VoiceChatRecorder', () {
    testWidgets('renders mic button in idle state', (tester) async {
      await tester.pumpWidget(buildRecorder());
      await tester.pump();
      expect(find.byKey(const Key('voice_mic_button')), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    testWidgets('mic button has correct color', (tester) async {
      await tester.pumpWidget(buildRecorder());
      await tester.pump();
      final icon = tester.widget<Icon>(find.byIcon(Icons.mic));
      expect(icon.color, equals(const Color(0xFFFF7F50))); // AppTheme.primaryColor
    });

    testWidgets('idle state does not show recording UI', (tester) async {
      await tester.pumpWidget(buildRecorder());
      await tester.pump();
      expect(find.byKey(const Key('voice_recording_bar')), findsNothing);
      expect(find.byKey(const Key('voice_timer')), findsNothing);
      expect(find.byKey(const Key('voice_sending_spinner')), findsNothing);
    });

    testWidgets('idle state does not show send or cancel buttons', (tester) async {
      await tester.pumpWidget(buildRecorder());
      await tester.pump();
      expect(find.byKey(const Key('voice_send_button')), findsNothing);
      expect(find.byKey(const Key('voice_cancel_button')), findsNothing);
    });

    testWidgets('widget can be created with all callbacks', (tester) async {
      bool cancelCalled = false;
      await tester.pumpWidget(buildRecorder(
        onSend: (path, dur) async {},
        onCancel: () => cancelCalled = true,
      ));
      await tester.pump();
      expect(find.byKey(const Key('voice_mic_button')), findsOneWidget);
      expect(cancelCalled, isFalse);
    });
  });
}
