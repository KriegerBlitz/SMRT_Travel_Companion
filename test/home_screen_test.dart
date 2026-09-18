import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travelcompanion/core/services/natural_language_route_service.dart';
import 'package:travelcompanion/features/home/home_screen.dart';

void main() {
  group('HomeScreen Widget Tests', () {
    testWidgets(
        'Renders HomeScreen with minimalist [placeholder [->]] search box and weather emoji',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      // Wait for entrance animation and initial weather fetch
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      // 1. Verify Top Branding & No 'LIVE' indicator at top
      expect(find.text('SMRT Travel Companion'), findsOneWidget);
      expect(find.text('LIVE'), findsNothing);
      expect(find.text('© OneMap · © OpenStreetMap contributors'), findsOneWidget);

      // 2. Verify Search Input with greyed-out placeholder
      expect(find.text('Bugis to Harborfront on Wheelchair'), findsOneWidget);

      // 3. Verify [->] Arrow is the ONLY button or icon in the text box
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsNothing);
      expect(find.byIcon(Icons.cancel_rounded), findsNothing);

      // 4. Verify Weather Forecast Bar with nowcast and emoji present
      expect(find.textContaining('Nowcast'), findsOneWidget);
      expect(find.text('LIVE NOWCAST'), findsOneWidget);

      // 5. Verify Floating Map Touch Controls
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
      expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);
    });

    testWidgets('Entering custom text in natural language text field updates input',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      // Enter query
      await tester.enterText(find.byType(TextField), 'Orchard to Marina Bay');
      await tester.pump();

      expect(find.text('Orchard to Marina Bay'), findsOneWidget);
    });

    testWidgets(
        'Tapping [->] arrow triggers route planner and displays route preview card with ETA',
        (tester) async {
      ParsedJourneyResult? receivedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            onNavigateToJourney: (result) {
              receivedResult = result;
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      // Tap the [->] arrow button
      final planButton = find.byIcon(Icons.arrow_forward_rounded);
      expect(planButton, findsOneWidget);

      await tester.tap(planButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify route was planned and preview card appears
      expect(find.textContaining('Bugis ➔ HarbourFront'), findsOneWidget);
      expect(find.textContaining('ETA'), findsOneWidget);
      expect(find.text('Wheelchair / Barrier-Free'), findsOneWidget);
      expect(find.textContaining('Journey logic planned'), findsOneWidget);
      expect(receivedResult, isNotNull);
      expect(receivedResult!.origin, 'Bugis');
      expect(receivedResult!.destination, 'HarbourFront');
      expect(receivedResult!.isWheelchairAccessible, isTrue);
    });

    testWidgets('Map floating buttons respond to tap gestures', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      // Tap Zoom In, Zoom Out, Recenter
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.my_location_rounded));
      await tester.pump();
    });
  });
}
