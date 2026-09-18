import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travelcompanion/core/debug/debug_service.dart';
import 'package:travelcompanion/konamicode.dart';

void main() {
  setUp(() {
    DebugService.instance.disableDebugMode();
  });

  group('KonamiCodeDetector Keystroke Logic', () {
    test('Triggers on ↑ ↑ ↓ ↓ ← → ← → B A Enter', () {
      var triggered = false;
      final detector = KonamiCodeDetector(onTriggered: () => triggered = true);

      final sequence = [
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.keyB,
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.enter,
      ];

      for (var i = 0; i < sequence.length; i++) {
        final key = sequence[i];
        final isLast = i == sequence.length - 1;
        final res = detector.handleKeyEvent(
          KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.keyA,
            logicalKey: key,
            timeStamp: Duration.zero,
          ),
        );
        if (isLast) {
          expect(res, isTrue);
        } else {
          expect(res, isFalse);
        }
      }

      expect(triggered, isTrue);
    });

    test('Triggers on ↑ ↑ ↓ ↓ ← → ← → B A Space', () {
      var triggeredCount = 0;
      final detector = KonamiCodeDetector(onTriggered: () => triggeredCount++);

      final sequence = [
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.keyB,
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.space,
      ];

      for (final key in sequence) {
        detector.handleKeyEvent(
          KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.space,
            logicalKey: key,
            timeStamp: Duration.zero,
          ),
        );
      }

      expect(triggeredCount, equals(1));
    });

    test('Does NOT trigger on invalid sequences', () {
      var triggered = false;
      final detector = KonamiCodeDetector(onTriggered: () => triggered = true);

      final sequence = [
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.arrowUp, // wrong key!
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.keyB,
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.enter,
      ];

      for (final key in sequence) {
        detector.handleKeyEvent(
          KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.enter,
            logicalKey: key,
            timeStamp: Duration.zero,
          ),
        );
      }

      expect(triggered, isFalse);
    });

    test('Default trigger toggles DebugService', () {
      expect(DebugService.instance.isDebugMode, isFalse);

      final detector = KonamiCodeDetector();
      final sequence = [
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.keyB,
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.enter,
      ];

      for (final key in sequence) {
        detector.handleKeyEvent(
          KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.enter,
            logicalKey: key,
            timeStamp: Duration.zero,
          ),
        );
      }

      // First time unlocks debug mode
      expect(DebugService.instance.isDebugMode, isTrue);

      // Typing it again re-locks into 100% live mode
      for (final key in sequence) {
        detector.handleKeyEvent(
          KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.enter,
            logicalKey: key,
            timeStamp: Duration.zero,
          ),
        );
      }
      expect(DebugService.instance.isDebugMode, isFalse);
    });

    testWidgets('KonamiCodeListener widget renders child and responds to keystroke sequence', (tester) async {
      var triggered = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KonamiCodeListener(
              onTriggered: () => triggered = true,
              child: const Text('Child App'),
            ),
          ),
        ),
      );

      expect(find.text('Child App'), findsOneWidget);

      final sequence = [
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.keyB,
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.enter,
      ];

      for (final key in sequence) {
        await tester.sendKeyEvent(key);
        await tester.pump();
      }

      expect(triggered, isTrue);
    });
  });
}

