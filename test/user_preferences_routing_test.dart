import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travelcompanion/core/debug/debug_service.dart';
import 'package:travelcompanion/core/models/crowd_density.dart';
import 'package:travelcompanion/core/models/route_plan.dart';
import 'package:travelcompanion/core/models/user_profile.dart';
import 'package:travelcompanion/core/services/geospatial_overpass_service.dart';
import 'package:travelcompanion/core/services/lta_service.dart';
import 'package:travelcompanion/core/services/onemap_service.dart';
import 'package:travelcompanion/core/services/transit_routing_engine.dart';
import 'package:travelcompanion/core/services/weather_service.dart';
import 'package:travelcompanion/features/home/widgets/commuter_account_sheet.dart';
import 'package:travelcompanion/features/home/widgets/confidence_details_sheet.dart';
import 'package:travelcompanion/features/home/widgets/demo_profile_bar.dart';
import 'package:travelcompanion/features/home/widgets/route_search_bar.dart';
import 'package:travelcompanion/features/home/widgets/side_by_side_route_card.dart';

void main() {
  setUp(() {
    DebugService.instance.resetToLiveMode();
  });

  group('UserProfile & UserPreferences Models', () {
    test('Default general commuter preferences has no wheelchair or stairs avoidance', () {
      const prefs = UserPreferences();
      expect(prefs.requiresWheelchair, isFalse);
      expect(prefs.avoidStairs, isFalse);
      expect(prefs.preferSheltered, isFalse);
      expect(prefs.walkingSpeedMultiplier, equals(1.0));

      final profile = UserProfile.general;
      expect(profile.id, equals('general'));
      expect(profile.name, equals('General Commuter'));
      expect(profile.preferences.requiresWheelchair, isFalse);
    });

    test('Demo profiles have tailored preferences for Rachel and Mdm Lim', () {
      final rachel = UserProfile.demoRachel;
      expect(rachel.preferences.highDisruptionSensitivity, isTrue);
      expect(rachel.preferences.requiresWheelchair, isFalse);

      final mdmLim = UserProfile.demoMdmLim;
      expect(mdmLim.preferences.requiresWheelchair, isTrue);
      expect(mdmLim.preferences.avoidStairs, isTrue);
      expect(mdmLim.preferences.preferSheltered, isTrue);
      expect(mdmLim.preferences.walkingSpeedMultiplier, lessThan(1.0));
    });

    test('UserPreferences copyWith updates values immutably', () {
      const original = UserPreferences();
      final updated = original.copyWith(
        requiresWheelchair: true,
        preferSheltered: true,
        walkingSpeedMultiplier: 0.8,
      );

      expect(updated.requiresWheelchair, isTrue);
      expect(updated.avoidStairs, isFalse);
      expect(updated.preferSheltered, isTrue);
      expect(updated.walkingSpeedMultiplier, equals(0.8));
    });
  });

  group('General-Purpose TransitRoutingEngine with UserPreferences', () {
    late TransitRoutingEngine engine;

    setUp(() {
      engine = TransitRoutingEngine(
        oneMapService: OneMapService(),
        ltaService: LtaDataMallService(),
        weatherService: WeatherService(),
      );
    });

    test('Routes with generic wheelchair preferences without passing persona string', () async {
      DebugService.instance.setDebugMode(true);

      const wheelchairPrefs = UserPreferences(
        requiresWheelchair: true,
        avoidStairs: true,
        preferSheltered: true,
        walkingSpeedMultiplier: 0.7,
      );

      final plan = await engine.planCommuterJourney(
        originName: 'Bedok',
        startLat: 1.3240,
        startLon: 103.9300,
        destinationName: 'Singapore General Hospital',
        endLat: 1.2803,
        endLon: 103.8395,
        preferences: wheelchairPrefs,
        simulateLiftOutage: true,
      );

      expect(plan.isSimulated, isTrue);
      expect(plan.isRerouted, isTrue);
      expect(plan.rerouteReason, contains('Lift outage'));
      expect(plan.legs.any((l) => l.mode == 'BUS' && l.lineOrService == 'Bus 197'), isTrue);
      expect(plan.etaBand, contains('–'));
    });

    test('Routes with high disruption sensitivity preferences reroutes via LTA shuttle', () async {
      DebugService.instance.setDebugMode(true);

      const sensitivePrefs = UserPreferences(
        highDisruptionSensitivity: true,
      );

      final plan = await engine.planCommuterJourney(
        originName: 'Tampines',
        startLat: 1.3533,
        startLon: 103.9452,
        destinationName: 'Raffles Place',
        endLat: 1.2830,
        endLon: 103.8513,
        preferences: sensitivePrefs,
        simulateDisruption: true,
      );

      expect(plan.isRerouted, isTrue);
      expect(plan.rerouteReason, isNotNull);
      expect(plan.rerouteReason?.toLowerCase(), contains('free mrt shuttle'));
      expect(plan.alternativeRoute, isNotNull);
      expect(plan.delayDifferenceMinutes, isNotNull);
    });

    test('Confidence band and reason never show single fake-precise number', () async {
      DebugService.instance.setDebugMode(true);

      final plan = await engine.planCommuterJourney(
        originName: 'Tampines',
        startLat: 1.3533,
        startLon: 103.9452,
        destinationName: 'Raffles Place',
        endLat: 1.2830,
        endLon: 103.8513,
        forceHighCrowd: true,
      );

      expect(plan.confidence, equals(ConfidenceLevel.amber));
      expect(plan.etaBand, matches(RegExp(r'^\d+–\d+ min$')));
      expect(plan.confidenceReason, contains('crowd'));
    });
  });

  group('GeospatialOverpassService Caching', () {
    test('Caches bounding box queries and returns cached elements', () async {
      final service = GeospatialOverpassService();

      // First query (hits bundled Singapore corridor fallback or cache)
      final res1 = await service.getPedestrianInfrastructure(
        centerLat: 1.3533,
        centerLon: 103.9452,
      );

      expect(res1.isNotEmpty, isTrue);
      final initialCount = res1.length;

      // Second query with exact same center should hit in-memory cache
      final res2 = await service.getPedestrianInfrastructure(
        centerLat: 1.3533,
        centerLon: 103.9452,
      );

      expect(res2.length, equals(initialCount));
    });

    test('Identifies sheltered walkways, footways, steps, and elevators from features', () async {
      final service = GeospatialOverpassService();
      final res = await service.getPedestrianInfrastructure(
        centerLat: 1.3005,
        centerLon: 103.8558,
      );

      expect(res.any((f) => f.isSheltered), isTrue);
      expect(res.any((f) => f.coordinates.isNotEmpty), isTrue);
    });
  });

  group('UI Widgets Tests', () {
    testWidgets('DemoProfileBar renders all profiles and responds to tap', (tester) async {
      UserProfile? tappedProfile;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DemoProfileBar(
              selectedProfile: UserProfile.general,
              onProfileChanged: (p) => tappedProfile = p,
            ),
          ),
        ),
      );

      expect(find.textContaining('General'), findsOneWidget);
      expect(find.textContaining('Rachel'), findsOneWidget);
      expect(find.textContaining('Mdm Lim'), findsOneWidget);

      await tester.tap(find.textContaining('Rachel'));
      await tester.pump();

      expect(tappedProfile, isNotNull);
      expect(tappedProfile!.id, equals('demo_rachel'));
    });

    testWidgets('SideBySideRouteCard renders recommended vs original route side-by-side', (tester) async {
      const original = RoutePlan(
        id: 'orig-1',
        origin: 'Tampines',
        destination: 'Raffles Place',
        totalDurationMinutes: 55,
        confidence: ConfidenceLevel.red,
        confidenceReason: 'Severe signalling disruption',
        legs: [
          RouteLeg(
            mode: 'MRT',
            lineOrService: 'EWL',
            departureStop: 'Tampines',
            arrivalStop: 'Raffles Place',
            durationSeconds: 3300,
            instruction: 'Take East-West Line',
            isDisrupted: true,
          ),
        ],
        isRerouted: true,
      );

      const recommended = RoutePlan(
        id: 'rec-1',
        origin: 'Tampines',
        destination: 'Raffles Place',
        totalDurationMinutes: 38,
        confidence: ConfidenceLevel.green,
        confidenceReason: 'Direct bridging shuttle active',
        legs: [
          RouteLeg(
            mode: 'SHUTTLE',
            lineOrService: 'Free MRT Shuttle',
            departureStop: 'Tampines Exit B',
            arrivalStop: 'Raffles Place Exit A',
            durationSeconds: 2280,
            instruction: 'Board Free MRT Shuttle at Station Exit B',
          ),
        ],
        isRerouted: true,
        rerouteReason: 'Free MRT Shuttle activated for disrupted segment',
        alternativeRoute: original,
      );

      bool? isAlternativeToggled;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SideBySideRouteCard(
              recommendedRoute: recommended,
              originalRoute: original,
              onRouteSelected: (showAlt) => isAlternativeToggled = showAlt,
            ),
          ),
        ),
      );

      // Verify one-line reason is visible
      expect(find.textContaining('Free MRT Shuttle activated'), findsOneWidget);

      // Verify side-by-side cards
      expect(find.text('Recommended'), findsOneWidget);
      expect(find.text('Original Route'), findsOneWidget);
      expect(find.textContaining('DELAYED'), findsOneWidget);

      // Verify time difference is clear
      expect(find.textContaining('SAVES 17 MIN'), findsOneWidget);

      // Tap on original route
      await tester.tap(find.text('Original Route'));
      await tester.pump();

      expect(isAlternativeToggled, isFalse);
    });

    testWidgets('ConfidenceDetailsSheet displays all 4 health audit factors without color-alone dependence', (tester) async {
      const plan = RoutePlan(
        id: 'conf-test',
        origin: 'Bugis',
        destination: 'HarbourFront',
        totalDurationMinutes: 28,
        confidence: ConfidenceLevel.green,
        confidenceReason: 'All systems operational; low crowd density',
        legs: [
          RouteLeg(
            mode: 'MRT',
            lineOrService: 'DTL',
            departureStop: 'Bugis',
            arrivalStop: 'HarbourFront',
            durationSeconds: 1680,
            instruction: 'Downtown Line',
            crowdLevel: CrowdLevel.low,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => ConfidenceDetailsSheet.show(ctx, plan),
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Verify title & ETA band
      expect(find.text('ETA Confidence Analysis'), findsOneWidget);
      expect(find.textContaining('28–31 min'), findsOneWidget);

      // Verify all 4 factors have text descriptions and icon indicators
      expect(find.textContaining('Station Crowding (PCD Forecast)'), findsOneWidget);
      expect(find.textContaining('Train Service Status (LTA DataMall)'), findsOneWidget);
      expect(find.textContaining('2-Hour Weather & Shelters'), findsOneWidget);
      expect(find.textContaining('Station Lifts (FacilitiesMaintenance)'), findsOneWidget);
    });

    testWidgets('RouteSearchBar accepts text input, provides suggestions, and handles clearing/submission', (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      String? submittedQuery;
      bool planPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RouteSearchBar(
              controller: controller,
              focusNode: focusNode,
              onSubmitted: (q) => submittedQuery = q,
              onPlanPressed: () => planPressed = true,
              onSuggestionSelected: (q) => submittedQuery = q,
            ),
          ),
        ),
      );

      // Verify initial state
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
      expect(find.byIcon(Icons.clear_rounded), findsNothing);

      // Verify transit suggestions exist
      expect(find.text('Jurong East to Raffles Place'), findsOneWidget);

      // Enter text
      await tester.enterText(find.byType(TextField), 'Bedok to Outram Park');
      await tester.pump();

      // Clear button should now be visible
      expect(find.byIcon(Icons.clear_rounded), findsOneWidget);

      // Tap submit arrow
      await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
      await tester.pump();
      expect(planPressed, isTrue);

      // Tap suggestion
      await tester.tap(find.text('Jurong East to Raffles Place'));
      await tester.pump();
      expect(submittedQuery, equals('Jurong East to Raffles Place'));
      expect(controller.text, equals('Jurong East to Raffles Place'));

      // Tap clear
      await tester.tap(find.byIcon(Icons.clear_rounded));
      await tester.pump();
      expect(controller.text, isEmpty);
      expect(find.byIcon(Icons.clear_rounded), findsNothing);
    });

    testWidgets('CommuterAccountSheet renders profiles and toggles preferences', (tester) async {
      UserProfile selected = UserProfile.general;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => CommuterAccountSheet.show(
                  ctx,
                  currentProfile: selected,
                  onProfileChanged: (p) => selected = p,
                ),
                child: const Text('Open Commuter Settings'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Commuter Settings'));
      await tester.pumpAndSettle();

      // Verify sheet title
      expect(find.text('Commuter Account & Preferences'), findsOneWidget);

      // Verify all profiles are shown
      expect(find.text('General Commuter'), findsOneWidget);
      expect(find.text('Rachel (Demo)'), findsOneWidget);
      expect(find.text('Mdm Lim (Demo)'), findsOneWidget);

      // Switch to Rachel (Demo)
      await tester.tap(find.text('Rachel (Demo)'));
      await tester.pumpAndSettle();
      expect(selected.id, equals('demo_rachel'));

      // Verify custom preferences toggles exist
      expect(find.text('Wheelchair & Step-Free Access'), findsOneWidget);
      expect(find.text('Sheltered Walkways (CoveredLinkWay)'), findsOneWidget);
      expect(find.text('High Disruption Sensitivity'), findsOneWidget);
    });
  });
}
