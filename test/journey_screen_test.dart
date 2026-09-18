import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travelcompanion/core/models/route_plan.dart';
import 'package:travelcompanion/core/transit/canonical_line_table.dart';
import 'package:travelcompanion/core/transit/journey_diagram_builder.dart';
import 'package:travelcompanion/features/journey/journey_screen.dart';
import 'package:travelcompanion/features/journey/widgets/transit_journey_diagram.dart';

void main() {
  group('JourneyDiagramBuilder Unit Tests', () {
    const builder = JourneyDiagramBuilder();

    test('builds diagram with authentic metro line colors and station dots', () {
      const plan = RoutePlan(
        id: 'test-plan',
        origin: 'Bugis',
        destination: 'HarbourFront',
        totalDurationMinutes: 24,
        confidence: ConfidenceLevel.green,
        confidenceReason: 'All barrier-free lifts operational.',
        legs: [
          RouteLeg(
            mode: 'SUBWAY',
            lineOrService: 'DTL',
            departureStop: 'Bugis (DT14)',
            arrivalStop: 'Chinatown (DT19)',
            durationSeconds: 480,
          ),
          RouteLeg(
            mode: 'SUBWAY',
            lineOrService: 'NEL',
            departureStop: 'Chinatown (NE4)',
            arrivalStop: 'HarbourFront (NE1)',
            durationSeconds: 420,
          ),
        ],
      );

      final diagram = builder.buildDiagram(plan);

      expect(diagram.origin, 'Bugis');
      expect(diagram.destination, 'HarbourFront');
      expect(diagram.totalDurationMinutes, 24);
      expect(diagram.segments.length, 2);

      // Leg 1: DTL
      final dtlSeg = diagram.segments[0];
      expect(dtlSeg.lineCode, 'DTL');
      expect(dtlSeg.color, TransitLine.dtl.color);
      expect(dtlSeg.stations.length, greaterThanOrEqualTo(2));

      // First station (Bugis): Origin -> Important (Big Dot)
      expect(dtlSeg.stations.first.name.toLowerCase(), contains('bugis'));
      expect(dtlSeg.stations.first.isImportant, isTrue);

      // Last station (Chinatown): Transfer -> Important (Big Dot)
      expect(dtlSeg.stations.last.name.toLowerCase(), contains('chinatown'));
      expect(dtlSeg.stations.last.isImportant, isTrue);

      // Intermediate stations: Small dots
      if (dtlSeg.stations.length > 2) {
        final intermediate = dtlSeg.stations[1];
        expect(intermediate.isImportant, isFalse);
      }

      // Leg 2: NEL
      final nelSeg = diagram.segments[1];
      expect(nelSeg.lineCode, 'NEL');
      expect(nelSeg.color, TransitLine.nel.color);
      expect(nelSeg.stations.first.isImportant, isTrue);
      expect(nelSeg.stations.last.name.toLowerCase(), contains('harbourfront'));
      expect(nelSeg.stations.last.isImportant, isTrue);
    });
  });

  group('JourneyScreen Widget Tests', () {
    testWidgets('renders search bar on top, displays ETA and route timeline',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: JourneyScreen(
            initialQuery: 'Bugis to Harborfront on Wheelchair',
          ),
        ),
      );

      // Initial loading
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Top search bar exists
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

      // Prominent ETA Display
      expect(find.textContaining('mins ETA'), findsOneWidget);
      expect(find.text('Bugis'), findsWidgets);
      expect(find.text('ROUTE TIMELINE'), findsOneWidget);

      // Schematic Transit Diagram is rendered
      expect(find.byType(TransitJourneyDiagram), findsOneWidget);
    });

    testWidgets('back button pops screen and returns to previous route',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).push(
                    MaterialPageRoute(
                      builder: (_) => const JourneyScreen(
                        initialQuery: 'Tampines to Raffles Place',
                      ),
                    ),
                  );
                },
                child: const Text('Go to Journey'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go to Journey'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(JourneyScreen), findsOneWidget);

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(JourneyScreen), findsNothing);
      expect(find.text('Go to Journey'), findsOneWidget);
    });
  });
}
