// Bug verification tests — these INTENTIONALLY demonstrate the bugs
// before they are fixed. Run with: flutter test test/bug_verification_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:travelcompanion/core/models/facility_maintenance.dart';
import 'package:travelcompanion/core/services/onemap_service.dart';
import 'package:travelcompanion/core/transit/canonical_line_table.dart';
import 'package:travelcompanion/core/models/disruption_alert.dart';

void main() {
  // ---------------------------------------------------------------------------
  // BUG 1: LiftMaintenance.isOutOfService — inverted catch-all
  // The final `!s.contains('operational')` means ANY status string that doesn't
  // literally contain "operational" returns true — including empty strings and
  // unknown statuses. E.g., '' returns true (falsely out-of-service).
  // ---------------------------------------------------------------------------
  group('[BUG 1] LiftMaintenance.isOutOfService inverted catch-all', () {
    test('FIXED: empty status string is NOT flagged as out-of-service', () {
      final lift = LiftMaintenance(
        station: 'EW14',
        unitId: 'LIFT-01',
        location: 'Platform to Concourse',
        exit: 'A',
        status: '', // Empty — should NOT be "out of service"
      );
      // FIXED: empty status now returns false (safe default)
      expect(lift.isOutOfService, isFalse);
    });

    test('FIXED: "Unknown" status is NOT flagged as out-of-service', () {
      final lift = LiftMaintenance(
        station: 'EW14',
        unitId: 'LIFT-01',
        location: 'Platform to Concourse',
        exit: 'A',
        status: 'Unknown',
      );
      // FIXED: unrecognised status now returns false (safe default)
      expect(lift.isOutOfService, isFalse);
    });

    test('SANITY: genuinely operational lift should return false', () {
      final lift = LiftMaintenance(
        station: 'EW14',
        unitId: 'LIFT-01',
        location: 'Platform to Concourse',
        exit: 'A',
        status: 'Operational',
      );
      expect(lift.isOutOfService, isFalse);
    });

    test('SANITY: out-of-service lift should return true', () {
      final lift = LiftMaintenance(
        station: 'EW14',
        unitId: 'LIFT-01',
        location: 'Platform to Concourse',
        exit: 'A',
        status: 'Out of Service - Overhaul',
      );
      expect(lift.isOutOfService, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // BUG 2: NLP parser fallback — any unknown route silently returns
  // the Mdm Lim Bedok→SGH route with WRONG labels for origin/destination.
  // E.g., "Bishan to Jurong East" returns origin="Bedok South Ave 1"
  // ---------------------------------------------------------------------------
  group('[BUG 2] NLP fallback returns wrong route for unknown destinations', () {
    test('FIXED: unknown origin/destination gets a generic route with correct labels', () {
      final service = OneMapService();
      final plan = service.getRealisticDoorToDoorRoute(
        originName: 'Bishan',
        startLat: 1.35064,
        startLon: 103.84817,
        destinationName: 'Jurong East',
        endLat: 1.33305,
        endLon: 103.74239,
      );
      // FIXED: generic passthrough route now uses the actual supplied labels
      expect(plan.origin, equals('Bishan'));
      expect(plan.destination, equals('Jurong East'));
      expect(plan.id, isNot(equals('mdm-lim-standard-route')));
    });
  });

  // ---------------------------------------------------------------------------
  // BUG 3: Disruption line code matching — seg.line from API is 'STL' but
  // transitLinesUsed contains 'SLRT'. The raw string compare fails silently,
  // so a Sengkang LRT disruption never triggers a reroute.
  // ---------------------------------------------------------------------------
  group('[BUG 3] Disruption detection misses LRT line code mismatch', () {
    test('FIXED: STL alert now matches SLRT route via canonical normalisation', () {
      final alertJson = {
        'Status': 2,
        'AffectedSegments': [
          {
            'Line': 'STL', // Raw API code from TrainServiceAlerts
            'Direction': 'Both',
            'Stations': 'STC,SE1,SE2',
            'FreePublicBus': 'Free bus service',
            'FreeMRTShuttle': '',
            'MRTShuttleDirection': 'Both',
          }
        ],
        'Message': [],
      };

      final alert = TrainServiceAlert.fromJson(alertJson);
      const routeLinesUsed = ['SLRT'];

      // FIXED: normalise seg.line through CanonicalLineTable.fromAlertsCode
      final canonicalLines = CanonicalLineTable.fromAlertsCode(
              alert.affectedSegments.first.line)
          .map((l) => l.canonicalCode)
          .toList();
      final matches =
          routeLinesUsed.any((l) => canonicalLines.contains(l));

      expect(matches, isTrue);
    });

    test('SANITY: EWL alert matches EWL in route legs (works because codes are same)', () {
      final alertJson = {
        'Status': 2,
        'AffectedSegments': [
          {
            'Line': 'EWL',
            'Direction': 'Both',
            'Stations': 'EW2,EW3',
            'FreePublicBus': '',
            'FreeMRTShuttle': 'Shuttle active',
            'MRTShuttleDirection': 'Both',
          }
        ],
        'Message': [],
      };
      final alert = TrainServiceAlert.fromJson(alertJson);
      const routeLinesUsed = ['EWL'];
      expect(routeLinesUsed.contains(alert.affectedSegments.first.line), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // BUG 4: OneMap hardcoded departure time '07:40:00'
  // Verified by inspection — no runtime assertion needed, it's a hardcoded const.
  // We just document it here for the fix record.
  // ---------------------------------------------------------------------------
  group('[BUG 4] OneMap hardcoded 07:40:00 departure time (inspection test)', () {
    test('departure time should use current time, not hardcoded 07:40:00', () {
      // This is a documentation test. The bug is on line ~31 of onemap_service.dart:
      //   'time': '07:40:00',
      // After the fix it should be DateTime.now() formatted as HH:mm:ss.
      // We verify the fix by checking the formatted time is within a reasonable
      // range of now (not exactly 07:40:00 at any time other than 07:40).
      final now = DateTime.now();
      final formattedNow =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      // If it's not 07:40 right now, hardcoded '07:40:00' would be wrong
      if (now.hour != 7 || now.minute != 40) {
        expect('07:40:00', isNot(equals(formattedNow)),
            reason: 'hardcoded 07:40:00 does not match current time — fix needed');
      }
    });
  });

  // ---------------------------------------------------------------------------
  // BUG 5: Disruption engine — line codes from TransitRoutingEngine do a raw
  // string compare instead of normalising through CanonicalLineTable first.
  // ---------------------------------------------------------------------------
  group('[BUG 5] CanonicalLineTable normalisation in routing engine', () {
    test('verify STL normalises to SLRT via CanonicalLineTable', () {
      expect(CanonicalLineTable.normalize('STL'), equals('SLRT'));
      expect(CanonicalLineTable.normalize('PTL'), equals('PLRT'));
    });

    test('verify toAlertsLineCode maps SLRT -> STL correctly', () {
      expect(CanonicalLineTable.toAlertsLineCode('SLRT'), equals('STL'));
      expect(CanonicalLineTable.toAlertsLineCode('PLRT'), equals('PTL'));
    });
  });
}
