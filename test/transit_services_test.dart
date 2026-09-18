import 'package:flutter_test/flutter_test.dart';
import 'package:travelcompanion/core/models/disruption_alert.dart';
import 'package:travelcompanion/core/models/route_plan.dart';
import 'package:travelcompanion/core/services/lta_service.dart';
import 'package:travelcompanion/core/services/onemap_service.dart';
import 'package:travelcompanion/core/services/transit_routing_engine.dart';
import 'package:travelcompanion/core/services/weather_service.dart';

void main() {
  group('TrainServiceAlert & Mitigation Parsing', () {
    test('correctly parses nested AffectedSegments and FreeMRTShuttle mitigations', () {
      final sampleJson = {
        'Status': 2,
        'AffectedSegments': [
          {
            'Line': 'EWL',
            'Direction': 'Both',
            'Stations': 'EW2,EW3,EW4,EW5,EW6',
            'FreePublicBus': 'Free bus service island wide',
            'FreeMRTShuttle': 'Tampines to Raffles Place',
            'MRTShuttleDirection': 'Both',
          }
        ],
        'Message': [
          {
            'Content': 'Signalling fault on EWL. Bridging buses activated.',
            'CreatedDate': '2026-09-18 07:45:00',
          }
        ]
      };

      final alert = TrainServiceAlert.fromJson(sampleJson);
      expect(alert.status, equals(2));
      expect(alert.isDisrupted, isTrue);
      expect(alert.affectedSegments.length, equals(1));

      final seg = alert.affectedSegments.first;
      expect(seg.line, equals('EWL'));
      expect(seg.hasFreeBus, isTrue);
      expect(seg.hasMrtShuttle, isTrue);
      expect(seg.isStationAffected('EW2'), isTrue);
      expect(seg.isStationAffected('EW14'), isFalse);
    });
  });

  group('WeatherService 2-Hour Nowcast', () {
    test('detects rain conditions to trigger covered walkway routing', () async {
      final weatherService = WeatherService();

      final rainResult = await weatherService.checkRainNowcast(
        area: 'Bedok',
        simulateRain: true,
      );
      expect(rainResult.isRainingOrImminent, isTrue);
      expect(rainResult.forecast, equals('Thundery Showers'));
    });
  });

  group('TransitRoutingEngine Decision Logic', () {
    late TransitRoutingEngine engine;

    setUp(() {
      engine = TransitRoutingEngine(
        oneMapService: OneMapService(),
        ltaService: LtaDataMallService(),
        weatherService: WeatherService(),
      );
    });

    test('Rachel: Normal operations yield high confidence route with door-to-door walking', () async {
      final plan = await engine.planCommuterJourney(
        originName: 'Tampines',
        startLat: 1.3533,
        startLon: 103.9452,
        destinationName: 'Raffles Place',
        endLat: 1.2830,
        endLon: 103.8513,
        persona: 'rachel',
      );

      expect(plan.isRerouted, isFalse);
      expect(plan.confidence, equals(ConfidenceLevel.green));
      expect(plan.legs.first.mode, equals('WALK'));
      expect(plan.legs.last.mode, equals('WALK'));
      expect(plan.transitLinesUsed, contains('EWL'));
    });

    test('Rachel: Proactive warning when crowd forecast indicates high density', () async {
      final plan = await engine.planCommuterJourney(
        originName: 'Tampines',
        startLat: 1.3533,
        startLon: 103.9452,
        destinationName: 'Raffles Place',
        endLat: 1.2830,
        endLon: 103.8513,
        persona: 'rachel',
        forceHighCrowd: true,
      );

      expect(plan.confidence, equals(ConfidenceLevel.amber));
      expect(plan.confidenceReason, contains('High platform crowding forecast'));
    });

    test('Rachel: Reroutes automatically during disruption using real LTA shuttle mitigation', () async {
      final plan = await engine.planCommuterJourney(
        originName: 'Tampines',
        startLat: 1.3533,
        startLon: 103.9452,
        destinationName: 'Raffles Place',
        endLat: 1.2830,
        endLon: 103.8513,
        persona: 'rachel',
        simulateDisruption: true,
      );

      expect(plan.isRerouted, isTrue);
      expect(plan.rerouteReason?.toLowerCase(), contains('free mrt shuttle'));
      expect(plan.legs.any((l) => l.mode == 'SHUTTLE'), isTrue);
      // Verify original route is preserved side-by-side with delayed status
      expect(plan.alternativeRoute, isNotNull);
      expect(plan.alternativeRoute!.legs.any((l) => l.isDisrupted), isTrue);
    });

    test('Mdm Lim: Lift outage at station exit triggers wheelchair-accessible bus alternative', () async {
      final plan = await engine.planCommuterJourney(
        originName: 'Bedok',
        startLat: 1.3240,
        startLon: 103.9300,
        destinationName: 'Singapore General Hospital',
        endLat: 1.2803,
        endLon: 103.8395,
        persona: 'mdmLim',
        simulateLiftOutage: true,
      );

      expect(plan.isRerouted, isTrue);
      expect(plan.rerouteReason, contains('Lift outage'));
      expect(plan.legs.any((l) => l.mode == 'BUS' && l.lineOrService == 'Bus 197'), isTrue);
    });

    test('Mdm Lim: Rain nowcast proactively switches to CoveredLinkWay sheltered route', () async {
      final plan = await engine.planCommuterJourney(
        originName: 'Bedok',
        startLat: 1.3240,
        startLon: 103.9300,
        destinationName: 'Singapore General Hospital',
        endLat: 1.2803,
        endLon: 103.8395,
        persona: 'mdmLim',
        simulateRain: true,
      );

      expect(plan.isRerouted, isTrue);
      expect(plan.usesShelteredWalkways, isTrue);
      expect(plan.hasRainRisk, isTrue);
      expect(plan.rerouteReason, contains('CoveredLinkWay'));
    });
  });
}
