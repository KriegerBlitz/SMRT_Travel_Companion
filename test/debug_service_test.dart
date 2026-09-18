import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travelcompanion/core/debug/debug_overlay_panel.dart';
import 'package:travelcompanion/core/debug/debug_service.dart';

void main() {
  group('DebugService & Diagnostics Verification Tests', () {
    setUp(() {
      DebugService.instance.resetToLiveMode();
    });

    tearDown(() {
      DebugService.instance.resetToLiveMode();
    });

    test('Initial state is strictly Live (Debug Mode false)', () {
      final debug = DebugService.instance;
      expect(debug.isDebugMode, isFalse);
      expect(debug.simulateDisruption, isFalse);
      expect(debug.simulateLiftOutage, isFalse);
      expect(debug.simulateRainNowcast, isFalse);
      expect(debug.simulateCrowdSurge, isFalse);
      expect(debug.activeSimulationLabels, isEmpty);
    });

    test('Scenario triggers activate simulation switches when Debug Mode is enabled', () {
      final debug = DebugService.instance;

      // Rachel Disruption scenario
      debug.triggerRachelDisruptionScenario();
      expect(debug.isDebugMode, isTrue);
      expect(debug.simulateDisruption, isTrue);
      expect(debug.activeSimulationLabels, contains('EWL Disruption + Free Shuttle'));

      // Mdm Lim Lift Outage scenario
      debug.triggerMdmLimLiftOutageScenario();
      expect(debug.simulateLiftOutage, isTrue);
      expect(debug.activeSimulationLabels, contains('Outram Park Lift Outage'));

      // Rain Nowcast scenario
      debug.triggerRainNowcastScenario();
      expect(debug.simulateRainNowcast, isTrue);
      expect(debug.activeSimulationLabels, contains('2-Hour Rain Nowcast'));

      // Platform Crowd Surge scenario
      debug.triggerCrowdSurgeScenario();
      expect(debug.simulateCrowdSurge, isTrue);
      expect(debug.activeSimulationLabels, contains('High Crowd Platform Spike'));

      // Dual Barrier scenario
      debug.triggerDualAccessibilityScenario();
      expect(debug.simulateLiftOutage, isTrue);
      expect(debug.simulateRainNowcast, isTrue);

      // Reset to Live Mode neutralizes all flags
      debug.resetToLiveMode();
      expect(debug.isDebugMode, isFalse);
      expect(debug.simulateDisruption, isFalse);
      expect(debug.simulateLiftOutage, isFalse);
      expect(debug.simulateRainNowcast, isFalse);
      expect(debug.simulateCrowdSurge, isFalse);
      expect(debug.activeSimulationLabels, isEmpty);
    });

    test('Diagnostic self-verification check passes all health checks', () async {
      final report = await DebugService.instance.runDiagnosticsVerification();
      expect(report.allPassed, isTrue);
      expect(report.checks.length, greaterThanOrEqualTo(3));
      for (final check in report.checks) {
        expect(check.passed, isTrue);
      }
    });

    testWidgets('DebugOverlayPanel is hidden when Debug Mode is false and visible when true',
        (tester) async {
      DebugService.instance.resetToLiveMode();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                DebugOverlayPanel(),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      // In Live Mode: Debug chip is completely hidden
      expect(find.byType(InkWell), findsNothing);

      // Turn on Debug Mode
      DebugService.instance.enableDebugMode();
      await tester.pump();

      // Now visible
      expect(find.text('DEBUG HARNESS'), findsOneWidget);

      // Tapping opens the simulation harness sheet
      await tester.tap(find.text('DEBUG HARNESS'));
      await tester.pumpAndSettle();

      expect(find.text('Simulation & Verification Harness'), findsOneWidget);
      expect(find.text('🩺 Verify Working of All Features'), findsOneWidget);

      // Tap verify button
      await tester.tap(find.text('🩺 Verify Working of All Features'));
      await tester.pumpAndSettle();

      expect(find.text('All Features Operational (100% Passed)'), findsOneWidget);

      // Tap lock & return to live
      await tester.tap(find.text('Lock & Return to 100% Live Compliance'));
      await tester.pumpAndSettle();

      expect(DebugService.instance.isDebugMode, isFalse);
      expect(find.text('DEBUG HARNESS'), findsNothing);
    });
  });
}
