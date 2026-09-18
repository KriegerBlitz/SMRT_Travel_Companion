import 'package:flutter_test/flutter_test.dart';
import 'package:travelcompanion/core/debug/debug_service.dart';
import 'package:travelcompanion/core/models/crowd_density.dart';
import 'package:travelcompanion/core/models/disruption_alert.dart';
import 'package:travelcompanion/core/models/route_plan.dart';
import 'package:travelcompanion/core/services/lta_service.dart';
import 'package:travelcompanion/core/services/onemap_service.dart';
import 'package:travelcompanion/core/services/weather_service.dart';

void main() {
  setUp(() {
    DebugService.instance.resetToLiveMode();
  });

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

  group('OneMapService & LtaDataMallService Direct Integration', () {
    late OneMapService oneMapService;
    late LtaDataMallService ltaService;

    setUp(() {
      oneMapService = OneMapService();
      ltaService = LtaDataMallService();
    });

    test('Door-to-door transit route includes walking legs at both ends', () async {
      final plan = await oneMapService.planRoute(
        originName: 'Tampines',
        startLat: 1.3533,
        startLon: 103.9452,
        destinationName: 'Raffles Place',
        endLat: 1.2830,
        endLon: 103.8513,
      );

      expect(plan.isRerouted, isFalse);
      expect(plan.confidence, equals(ConfidenceLevel.green));
      expect(plan.legs.first.mode, equals('WALK'));
      expect(plan.legs.last.mode, equals('WALK'));
      expect(plan.transitLinesUsed, contains('EWL'));
    });

    test('Strict Competition Rule: When Debug Mode is OFF, simulated data is blocked', () async {
      DebugService.instance.resetToLiveMode();

      final alert = await ltaService.getTrainServiceAlerts(simulateDisruption: false);
      expect(alert.isSimulated, isFalse);
      expect(alert.isDisrupted, isFalse);

      final crowds = await ltaService.getStationCrowdRealTime('EWL');
      expect(crowds.every((c) => c.crowdLevel == CrowdLevel.na), isTrue);
    });

    test('LtaDataMallService: Simulates disruption alert with FreeMRTShuttle in Debug Mode', () async {
      DebugService.instance.setDebugMode(true);
      final alert = await ltaService.getTrainServiceAlerts(simulateDisruption: true);

      expect(alert.isSimulated, isTrue);
      expect(alert.isDisrupted, isTrue);
      expect(alert.affectedSegments.isNotEmpty, isTrue);
      expect(alert.affectedSegments.first.hasMrtShuttle, isTrue);
    });

    test('LtaDataMallService: Simulates crowd forecast in Debug Mode', () async {
      DebugService.instance.setDebugMode(true);
      final crowds = await ltaService.getStationCrowdForecast('EWL');

      expect(crowds.isNotEmpty, isTrue);
      expect(crowds.any((c) => c.isForecast), isTrue);
    });

    test('LtaDataMallService: Fetches facilities maintenance lift outages in Debug Mode', () async {
      DebugService.instance.setDebugMode(true);
      final outages = await ltaService.getFacilitiesMaintenance(stationCode: 'EW16');

      expect(outages.isNotEmpty, isTrue);
      expect(outages.any((o) => o.isOutOfService), isTrue);
    });

    test('OneMapService: Provides multi-modal options with title and badge', () {
      final options = oneMapService.getRealisticMultiModalOptions(
        originName: 'Bugis',
        startLat: 1.3005,
        startLon: 103.8558,
        destinationName: 'HarbourFront',
        endLat: 1.2654,
        endLon: 103.8222,
      );

      expect(options.length, greaterThanOrEqualTo(2));
      expect(options.any((o) => o.title.contains('Rail')), isTrue);
      expect(options.any((o) => o.badge != null), isTrue);
    });
  });
}
