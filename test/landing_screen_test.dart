import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travelcompanion/features/landing/landing_screen.dart';
import 'package:travelcompanion/main.dart';

void main() {
  group('LandingScreen Widget Tests', () {
    testWidgets('Renders "Where to NEXT?" with custom typography and layout', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LandingScreen(
            onTransitionToHome: () {},
          ),
        ),
      );

      // Verify words are present
      expect(find.text('Where'), findsOneWidget);
      expect(find.text('to'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('NEXT')),
        findsOneWidget,
      );
      expect(find.text('SMRT · COMPANION'), findsOneWidget);
    });

    testWidgets('Tapping anywhere triggers transition callback', (tester) async {
      var transitioned = false;
      await tester.pumpWidget(
        MaterialApp(
          home: LandingScreen(
            onTransitionToHome: () => transitioned = true,
          ),
        ),
      );

      await tester.tap(find.text('Where'));
      await tester.pump();

      expect(transitioned, isTrue);
    });

    testWidgets('MainNavigationRoot transitions from Landing to Home on tap', (tester) async {
      await tester.pumpWidget(const SMRTTravelCompanionApp());
      await tester.pump();

      // Initially on LandingScreen
      expect(find.text('Where'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('NEXT')),
        findsOneWidget,
      );

      // Tap to transition
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      // Now on HomeScreen
      expect(find.text('SMRT Travel Companion'), findsOneWidget);
    });

    testWidgets('Hardware key press triggers transition to Home', (tester) async {
      await tester.pumpWidget(const SMRTTravelCompanionApp());
      await tester.pump();

      // Initially on LandingScreen
      expect(find.text('Where'), findsOneWidget);

      // Send any key event
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      // Transitioned to Home
      expect(find.text('SMRT Travel Companion'), findsOneWidget);
    });
  });
}
