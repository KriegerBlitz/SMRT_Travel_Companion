import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travelcompanion/services/simulator_service.dart';
import 'package:travelcompanion/ui/accessibility_screen.dart';
import 'package:travelcompanion/ui/home_dashboard_screen.dart';
import 'package:travelcompanion/ui/in_transit_screen.dart';
import 'package:travelcompanion/ui/plan_trip_screen.dart';
import 'package:travelcompanion/ui/main_shell.dart';
import 'package:travelcompanion/ui/route_map_screen.dart';
import 'package:travelcompanion/ui/simulator_screen.dart';
import 'package:travelcompanion/ui/station_layout_screen.dart';

void main() {
  group('UI Overhaul - 7 Screen Redesign Verification', () {
    late SimulatorService simulator;

    setUp(() {
      simulator = SimulatorService();
    });

    testWidgets('Screen 1 (Page 1) - HomeDashboardScreen displays all essential elements', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeDashboardScreen(
              simulator: simulator,
              onPlanTrip: () {},
              onOpenSimulator: () {},
              onOpenAccessibility: () {},
              onOpenStationMap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Good morning'), findsOneWidget);
      expect(find.text('Jurong East Interchange'), findsOneWidget);
      expect(find.text('SIMULATED DATA'), findsOneWidget);
      expect(find.text('Next train · NS1'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('min'), findsWidgets);
      expect(find.text('Moderate'), findsOneWidget);
      expect(find.text('North-South Line'), findsOneWidget);
      expect(find.text('East-West Line'), findsOneWidget);
    });

    testWidgets('Screen 2 (Page 2) - PlanTripScreen displays query, tags, route cards, and CTA', (tester) async {
      bool tripStarted = false;
      await tester.pumpWidget(
        MaterialApp(
          home: PlanTripScreen(
            simulator: simulator,
            onStartTrip: () {
              tripStarted = true;
            },
          ),
        ),
      );

      expect(find.text('Plan a trip'), findsOneWidget);
      expect(find.text('Parsed: '), findsOneWidget);
      expect(find.text('from Tampines'), findsOneWidget);
      expect(find.text('to Raffles Place'), findsOneWidget);
      expect(find.text('avoid crowds'), findsOneWidget);
      expect(find.text('Alternative · Shuttle from Tampines'), findsOneWidget);
      expect(find.text('37 min'), findsWidgets);
      expect(find.text('Car 4 is less crowded on this route'), findsOneWidget);
      expect(find.text('Start trip'), findsOneWidget);

      await tester.tap(find.text('Start trip'));
      expect(tripStarted, isTrue);
    });

    testWidgets('Screen 3 (Page 3) - InTransitScreen displays route header, Novena 2 min, pulse, stops accordion', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: InTransitScreen(
            simulator: simulator,
          ),
        ),
      );

      expect(find.text('Jurong East → City Hall'), findsOneWidget);
      expect(find.text('Stop 4 of 9 · NS line'), findsOneWidget);
      expect(find.text('Novena'), findsOneWidget);
      expect(find.text('2 min'), findsOneWidget);
      expect(find.text('Approaching your stop'), findsOneWidget);
      expect(find.text('Haptic + visual pulse firing now'), findsOneWidget);
      expect(find.text('View all stops'), findsOneWidget);

      // Expand accordion
      await tester.tap(find.text('View all stops'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Bukit Batok'), findsOneWidget);
      expect(find.text('City Hall'), findsOneWidget);
    });

    testWidgets('Screen 4 (Page 4) - AccessibilityScreen displays Read Aloud, Haptics, and Familiarity', (tester) async {
      bool highContrastToggled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: AccessibilityScreen(
            isHighContrast: false,
            onToggleHighContrast: (val) {
              highContrastToggled = val;
            },
          ),
        ),
      );

      expect(find.text('Accessibility'), findsOneWidget);
      expect(find.text('READ ALOUD'), findsOneWidget);
      expect(find.text('HAPTIC PATTERNS'), findsOneWidget);
      expect(find.text('Get off'), findsOneWidget);
      expect(find.text('Change line'), findsOneWidget);
      expect(find.text('Service pause'), findsOneWidget);
      expect(find.text('Route familiarity'), findsOneWidget);
      expect(find.text('Familiar · 12 visits'), findsOneWidget);
      expect(find.text('High-contrast & large text'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      expect(highContrastToggled, isTrue);
    });

    testWidgets('Screen 5 (Page 5) - StationLayoutScreen displays platform diagram and bundled legend', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StationLayoutScreen(),
        ),
      );

      expect(find.text('Station map'), findsOneWidget);
      expect(find.text('JURONG EAST · PLATFORM LAYOUT'), findsOneWidget);
      expect(find.text('NS line platform'), findsOneWidget);
      expect(find.text('EW line platform'), findsOneWidget);
      expect(find.text('Concourse'), findsOneWidget);
      expect(find.textContaining('Bundled offline: Jurong East'), findsOneWidget);
      expect(find.text('Other stations open via browser link'), findsOneWidget);
    });

    testWidgets('Screen 6 (Page 6) - SimulatorScreen provides dev toggles, crowd override, and disruption', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SimulatorScreen(
            simulator: simulator,
          ),
        ),
      );

      expect(find.text('Simulator'), findsOneWidget);
      expect(find.text('DEV ONLY'), findsOneWidget);
      expect(find.text('SIMULATED DATA — not live'), findsOneWidget);
      expect(find.text('Live API'), findsOneWidget);
      expect(find.text('Mock data'), findsOneWidget);
      expect(find.text('CROWD LEVEL OVERRIDE'), findsOneWidget);
      expect(find.text('Station: Jurong East'), findsOneWidget);
      expect(find.text('Low'), findsOneWidget);
      expect(find.text('Med'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
      expect(find.text('DEAD-RECKONING TIMER'), findsOneWidget);
      expect(find.text('Trigger disruption'), findsOneWidget);
    });

    testWidgets('Screen 7 (Page 7) - RouteMapScreen displays route map canvas, legend, and rain card', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RouteMapScreen(
            simulator: simulator,
          ),
        ),
      );

      expect(find.text('Route map'), findsOneWidget);
      expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
      expect(find.text('Original route'), findsOneWidget);
      expect(find.text('22 min'), findsOneWidget);
      expect(find.text('Alternative · shuttle bus'), findsOneWidget);
      expect(find.text('37 min'), findsOneWidget);
      expect(find.text('Low'), findsOneWidget);
      expect(find.text('Moderate'), findsOneWidget);
      expect(find.text('High crowd'), findsOneWidget);
      expect(find.textContaining('sheltered walkway'), findsOneWidget);
    });

    testWidgets('RedesignShell navigates through tabs and starts trip correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RedesignShell(simulator: simulator),
        ),
      );

      // Initially on Home (Screen 1)
      expect(find.text('Jurong East Interchange'), findsOneWidget);

      // Tap 'Plan' tab
      await tester.tap(find.text('Plan'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Plan a trip'), findsOneWidget);

      // Tap 'Start trip' -> transitions to Transit (Screen 3)
      await tester.tap(find.text('Start trip'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Jurong East → City Hall'), findsOneWidget);

      // Tap 'Access' tab
      await tester.tap(find.text('Access'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Accessibility'), findsOneWidget);

      // Tap 'Layout' tab
      await tester.tap(find.text('Layout'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Station map'), findsOneWidget);

      // Tap 'Map' tab
      await tester.tap(find.text('Map'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Route map'), findsOneWidget);
    });
  });
}
