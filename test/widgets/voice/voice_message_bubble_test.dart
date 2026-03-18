import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/widgets/voice/voice_message_bubble.dart';
import '../../helpers/core_screen_test_helper.dart';

void main() {
  setUpAll(() => setupTestHttpOverrides());

  Widget buildBubble({
    bool isSender = true,
    double duration = 12.0,
  }) {
    return buildCoreScreenTestApp(
      home: Scaffold(
        body: Center(
          child: VoiceMessageBubble(
            audioUrl: 'https://example.com/audio.m4a',
            durationSeconds: duration,
            timestamp: DateTime(2026, 3, 15, 14, 30),
            isSender: isSender,
          ),
        ),
      ),
    );
  }

  group('VoiceMessageBubble', () {
    testWidgets('renders with formatted duration text', (tester) async {
      await tester.pumpWidget(buildBubble(duration: 45.0));
      await tester.pump();
      expect(find.text('0:45'), findsOneWidget);
    });

    testWidgets('renders timestamp', (tester) async {
      await tester.pumpWidget(buildBubble());
      await tester.pump();
      expect(find.text('14:30'), findsOneWidget);
    });

    testWidgets('shows play button initially', (tester) async {
      await tester.pumpWidget(buildBubble());
      await tester.pump();
      expect(find.byIcon(Icons.play_circle_fill), findsOneWidget);
      expect(find.byIcon(Icons.pause_circle_filled), findsNothing);
    });

    testWidgets('formats duration correctly for > 1 minute', (tester) async {
      await tester.pumpWidget(buildBubble(duration: 75.0));
      await tester.pump();
      expect(find.text('1:15'), findsOneWidget);
    });

    testWidgets('sender bubble uses primary color background', (tester) async {
      await tester.pumpWidget(buildBubble(isSender: true));
      await tester.pump();
      // The Container with BoxDecoration(color: primaryColor)
      final containers = tester.widgetList<Container>(find.byType(Container));
      final decorated = containers.where((c) {
        final dec = c.decoration;
        if (dec is BoxDecoration) {
          return dec.color == const Color(0xFFFF7F50); // AppTheme.primaryColor
        }
        return false;
      });
      expect(decorated, isNotEmpty, reason: 'Sender should have coral background');
    });

    testWidgets('receiver bubble uses surfaceElevated background', (tester) async {
      await tester.pumpWidget(buildBubble(isSender: false));
      await tester.pump();
      final containers = tester.widgetList<Container>(find.byType(Container));
      final decorated = containers.where((c) {
        final dec = c.decoration;
        if (dec is BoxDecoration) {
          return dec.color == const Color(0xFF252540); // AppTheme.surfaceElevated
        }
        return false;
      });
      expect(decorated, isNotEmpty, reason: 'Receiver should have dark background');
    });

    testWidgets('waveform bars are rendered', (tester) async {
      await tester.pumpWidget(buildBubble());
      await tester.pump();
      // 20 waveform bar containers exist inside the bubble
      // Each bar is a Container with 3px width
      // Just verify the waveform SizedBox with height 24 exists
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final waveformBox = sizedBoxes.where((s) => s.height == 24);
      expect(waveformBox, isNotEmpty, reason: 'Waveform container should exist');
    });
  });
}
