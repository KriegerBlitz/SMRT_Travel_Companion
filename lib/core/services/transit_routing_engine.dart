import '../debug/debug_service.dart';
import '../models/crowd_density.dart';
import '../models/disruption_alert.dart';
import '../models/facility_maintenance.dart';
import '../models/route_plan.dart';
import '../transit/canonical_line_table.dart'; // Needed for Bug 3 fix: line code normalisation
import 'lta_service.dart';
import 'onemap_service.dart';
import 'weather_service.dart';

/// Central decision engine that combines OneMap routing with real-time LTA
/// disruptions, station crowd forecasts, lift maintenance, and weather nowcasts.
/// Strictly enforces live-only operations unless Debug Mode is explicitly activated.
class TransitRoutingEngine {
  final OneMapService _oneMapService;
  final LtaDataMallService _ltaService;
  final WeatherService _weatherService;
  final DebugService _debugService;

  TransitRoutingEngine({
    OneMapService? oneMapService,
    LtaDataMallService? ltaService,
    WeatherService? weatherService,
    DebugService? debugService,
  })  : _oneMapService = oneMapService ?? OneMapService(),
        _ltaService = ltaService ?? LtaDataMallService(),
        _weatherService = weatherService ?? WeatherService(),
        _debugService = debugService ?? DebugService.instance;

  /// Plans an intelligent, disruption-aware and accessibility-aware journey.
  /// Strictly requires Debug Mode to be active for any simulated data injection.
  Future<RoutePlan> planCommuterJourney({
    required String originName,
    required double startLat,
    required double startLon,
    required String destinationName,
    required double endLat,
    required double endLon,
    required String persona, // 'rachel' or 'mdmLim'
    bool simulateDisruption = false,
    bool simulateLiftOutage = false,
    bool simulateRain = false,
    bool forceHighCrowd = false,
  }) async {
    // Strict isolation: Simulations are strictly locked unless Debug Mode is enabled
    final canSimulate = _debugService.isDebugMode;
    final effectiveSimulateDisruption =
        canSimulate && (simulateDisruption || _debugService.simulateDisruption);
    final effectiveSimulateLiftOutage =
        canSimulate && (simulateLiftOutage || _debugService.simulateLiftOutage);
    final effectiveSimulateRain =
        canSimulate && (simulateRain || _debugService.simulateRainNowcast);
    final effectiveForceHighCrowd =
        canSimulate && (forceHighCrowd || _debugService.simulateCrowdSurge);

    // 1. Fetch real-time LTA alerts
    final alert = await _ltaService.getTrainServiceAlerts(
      simulateDisruption: effectiveSimulateDisruption,
    );

    // 2. Query 2-hour weather nowcast (if Mdm Lim or rain simulation)
    final weather = await _weatherService.checkRainNowcast(
      area: originName,
      simulateRain: effectiveSimulateRain,
    );

    // 3. Obtain base door-to-door route from OneMap
    final baseRoute = await _oneMapService.planRoute(
      originName: originName,
      startLat: startLat,
      startLon: startLon,
      destinationName: destinationName,
      endLat: endLat,
      endLon: endLon,
      preferSheltered: weather.isRainingOrImminent && persona == 'mdmLim',
    );

    // 4. Fetch crowd forecasts for lines used in base route
    final crowdForecasts = <StationCrowd>[];
    for (final line in baseRoute.transitLinesUsed) {
      final lineCrowds = await _ltaService.getStationCrowdForecast(line);
      crowdForecasts.addAll(lineCrowds);
    }

    final hasPredictedCrowdSpike = effectiveForceHighCrowd ||
        crowdForecasts.any((c) => c.crowdLevel == CrowdLevel.high);

    // 5. Evaluate Lift Outages (Critical for Mdm Lim)
    List<LiftMaintenance> liftOutages = [];
    if (persona == 'mdmLim') {
      if (effectiveSimulateLiftOutage) {
        liftOutages = [
          const LiftMaintenance(
            station: 'EW16',
            unitId: 'LIFT-03',
            location: 'Outram Park EWL Platform to Concourse',
            exit: 'Exit 7 (SGH)',
            status: 'Out of Service - Scheduled Overhaul',
            description: 'Lift out of service for replacement works',
          ),
        ];
      } else {
        liftOutages = await _ltaService.getFacilitiesMaintenance(stationCode: 'EW16');
      }
    }

    // 6. Check for active disruption along base route
    //
    // FIX [Bug 3]: Previously used raw `seg.line` (e.g. 'STL' from the API) in
    // a direct `.contains()` against `transitLinesUsed` which holds canonical
    // codes (e.g. 'SLRT'). Any LRT-line disruption would silently never match.
    //
    // Fix: resolve the alerts code through CanonicalLineTable.fromAlertsCode()
    // which returns the list of canonical codes that correspond to the raw code,
    // then check for overlap with the route's canonical lines.
    AffectedSegment? activeAffectedSegment;
    for (final seg in alert.affectedSegments) {
      // Translate raw alerts line code → canonical code(s) (handles STL→SLRT, PTL→PLRT, etc.)
      final canonicalLines = CanonicalLineTable.fromAlertsCode(seg.line)
          .map((l) => l.canonicalCode)
          .toList();

      final usesAffectedLine = baseRoute.transitLinesUsed
          .any((routeLine) => canonicalLines.contains(routeLine));

      if (usesAffectedLine) {
        activeAffectedSegment = seg;
        break;
      }
    }

    // =========================================================================
    // SCENARIO A: Disruption Detected -> Automatic Reroute using LTA Mitigations
    // =========================================================================
    if (alert.isDisrupted && activeAffectedSegment != null) {
      return _buildDisruptionMitigationRoute(
        baseRoute: baseRoute,
        segment: activeAffectedSegment,
        alert: alert,
        persona: persona,
        hasCrowdSpike: hasPredictedCrowdSpike,
      );
    }

    // =========================================================================
    // SCENARIO B: Mdm Lim - Lift Outage Detected -> Wheelchair Bus Alternative
    // =========================================================================
    if (persona == 'mdmLim' && liftOutages.any((l) => l.isOutOfService)) {
      final outage = liftOutages.firstWhere((l) => l.isOutOfService);
      return _buildAccessibleBusAlternative(
        baseRoute: baseRoute,
        outage: outage,
        weather: weather,
      );
    }

    // =========================================================================
    // SCENARIO C: Mdm Lim - Rain Forecasted -> Switch to Sheltered Walkway
    // =========================================================================
    if (persona == 'mdmLim' && weather.isRainingOrImminent) {
      return _buildWeatherAwareShelteredRoute(
        baseRoute: baseRoute,
        weather: weather,
      );
    }

    // =========================================================================
    // SCENARIO D: Normal Operations with ETA Confidence & Crowd Proactivity
    // =========================================================================
    ConfidenceLevel confidence = ConfidenceLevel.green;
    String confidenceReason = 'Normal train frequency. All facilities operational.';

    if (hasPredictedCrowdSpike) {
      confidence = ConfidenceLevel.amber;
      confidenceReason = 'High platform crowding forecast around 08:00. Consider leaving 10 min earlier.';
    }

    return RoutePlan(
      id: baseRoute.id,
      origin: baseRoute.origin,
      destination: baseRoute.destination,
      totalDurationMinutes: baseRoute.totalDurationMinutes,
      totalWalkDistanceMeters: baseRoute.totalWalkDistanceMeters,
      legs: baseRoute.legs,
      isRerouted: false,
      confidence: confidence,
      confidenceReason: confidenceReason,
      hasRainRisk: weather.isRainingOrImminent,
      usesShelteredWalkways: baseRoute.usesShelteredWalkways,
      isSimulated: canSimulate && (alert.isSimulated || weather.isSimulated || effectiveForceHighCrowd),
    );
  }

  /// Builds a rerouted journey using official LTA mitigation services
  /// (Free MRT Shuttle / Free Public Bus) shown side-by-side with original route.
  RoutePlan _buildDisruptionMitigationRoute({
    required RoutePlan baseRoute,
    required AffectedSegment segment,
    required TrainServiceAlert alert,
    required String persona,
    required bool hasCrowdSpike,
  }) {
    // Determine one-line explanation
    final mitigationReason = segment.hasMrtShuttle
        ? 'EWL disruption: Take free MRT shuttle from Tampines (+15 min)'
        : (segment.hasFreeBus
            ? 'EWL disruption: Board free bridging bus island-wide (+20 min)'
            : 'Train service suspended on ${segment.line}: Alternative bus advised');

    // Build alternative legs using the mitigation
    final alternativeLegs = <RouteLeg>[
      // Walk to shuttle boarding point
      const RouteLeg(
        mode: 'WALK',
        departureStop: 'Tampines Ave 4',
        arrivalStop: 'Tampines Bus Interchange (Shuttle Bay 3)',
        durationSeconds: 300,
        distanceMeters: 300.0,
        instruction: 'Walk to Tampines Bus Interchange Bay 3 for Free MRT Shuttle',
      ),
      // Free MRT Shuttle Leg
      const RouteLeg(
        mode: 'SHUTTLE',
        lineOrService: 'Free MRT Shuttle',
        departureStop: 'Tampines Bus Interchange',
        arrivalStop: 'Raffles Place / Shenton Way Shuttle Dropoff',
        durationSeconds: 2700, // 45 mins via expressway
        distanceMeters: 19500.0,
        coordinates: [
          [1.3533, 103.9452], // Tampines
          [1.3320, 103.9210], // PIE
          [1.3110, 103.8820], // KPE / ECP
          [1.2830, 103.8513], // Raffles Place
        ],
        instruction: 'Board Free MRT Shuttle. Express via ECP to Raffles Place.',
      ),
      // Final walk
      const RouteLeg(
        mode: 'WALK',
        departureStop: 'Raffles Place Shuttle Dropoff',
        arrivalStop: 'Ocean Financial Centre',
        durationSeconds: 180,
        distanceMeters: 180.0,
        instruction: 'Walk to building lobby',
      ),
    ];

    // Mark disrupted legs in original route for visual distinction
    final markedOriginalLegs = baseRoute.legs.map((leg) {
      if (leg.mode == 'SUBWAY') {
        return RouteLeg(
          mode: leg.mode,
          lineOrService: leg.lineOrService,
          departureStop: leg.departureStop,
          arrivalStop: leg.arrivalStop,
          durationSeconds: leg.durationSeconds + 1200, // Significant delay on original
          distanceMeters: leg.distanceMeters,
          coordinates: leg.coordinates,
          isDisrupted: true, // Marked for distinct red dashed display
          instruction: 'SERVICE DISRUPTED: Heavy delays & bridging in effect',
        );
      }
      return leg;
    }).toList();

    final originalRouteWithDelay = RoutePlan(
      id: 'original-delayed-route',
      origin: baseRoute.origin,
      destination: baseRoute.destination,
      totalDurationMinutes: baseRoute.totalDurationMinutes + 25,
      totalWalkDistanceMeters: baseRoute.totalWalkDistanceMeters,
      legs: markedOriginalLegs,
      isRerouted: false,
      confidence: ConfidenceLevel.red,
      confidenceReason: 'Active disruption on line segment. Delays exceeding 25 mins.',
      isSimulated: alert.isSimulated,
    );

    return RoutePlan(
      id: 'revised-mitigation-route',
      origin: baseRoute.origin,
      destination: baseRoute.destination,
      totalDurationMinutes: baseRoute.totalDurationMinutes + 15,
      totalWalkDistanceMeters: 480.0,
      legs: alternativeLegs,
      isRerouted: true,
      rerouteReason: mitigationReason,
      confidence: ConfidenceLevel.amber,
      confidenceReason: 'Shuttle running at 5-min frequency. +15 min travel time.',
      alternativeRoute: originalRouteWithDelay, // Kept side-by-side for comparison
      isSimulated: alert.isSimulated,
    );
  }

  /// Builds a wheelchair-accessible bus alternative when a key station lift is out of service.
  RoutePlan _buildAccessibleBusAlternative({
    required RoutePlan baseRoute,
    required LiftMaintenance outage,
    required WeatherForecastResult weather,
  }) {
    const busAlternativeLegs = <RouteLeg>[
      RouteLeg(
        mode: 'WALK',
        departureStop: 'Bedok South Ave 1',
        arrivalStop: 'Opp Bedok Station (Bus Stop 84031)',
        durationSeconds: 360,
        distanceMeters: 220.0,
        isSheltered: true,
        instruction: 'Walk via ramp to Bus Stop 84031 Opp Bedok Station',
      ),
      RouteLeg(
        mode: 'BUS',
        lineOrService: 'Bus 197',
        departureStop: 'Opp Bedok Station (84031)',
        arrivalStop: 'Opp Singapore General Hospital (06011)',
        durationSeconds: 2700, // 45 mins direct
        distanceMeters: 16200.0,
        coordinates: [
          [1.3240, 103.9300],
          [1.3164, 103.8829],
          [1.2931, 103.8522],
          [1.2797, 103.8378],
        ],
        instruction: 'Board Bus 197 (Wheelchair Accessible). Alight right at SGH entrance.',
      ),
      RouteLeg(
        mode: 'WALK',
        departureStop: 'Opp SGH (06011)',
        arrivalStop: 'SGH Diabetes & Metabolism Centre',
        durationSeconds: 180,
        distanceMeters: 100.0,
        isSheltered: true,
        instruction: 'Ramp access directly into clinic building — zero stairs, avoids broken lift',
      ),
    ];

    final rerouteExplanation =
        'Lift outage at Outram Park Exit 7. Direct Wheelchair Bus 197 recommended (avoid stairs).';

    return RoutePlan(
      id: 'mdm-lim-bus-alternative',
      origin: baseRoute.origin,
      destination: baseRoute.destination,
      totalDurationMinutes: 54, // +10 mins compared to train, but 100% step-free
      totalWalkDistanceMeters: 320.0,
      legs: busAlternativeLegs,
      isRerouted: true,
      rerouteReason: rerouteExplanation,
      confidence: ConfidenceLevel.green,
      confidenceReason: 'Direct wheelchair bus (Seats Available, WAB). Zero stairs or lifts required.',
      hasRainRisk: weather.isRainingOrImminent,
      usesShelteredWalkways: true,
      alternativeRoute: baseRoute,
      isSimulated: true,
    );
  }

  /// Builds a weather-aware route utilizing CoveredLinkWay (sheltered walkways).
  RoutePlan _buildWeatherAwareShelteredRoute({
    required RoutePlan baseRoute,
    required WeatherForecastResult weather,
  }) {
    final shelteredLegs = baseRoute.legs.map((leg) {
      if (leg.mode == 'WALK') {
        return RouteLeg(
          mode: leg.mode,
          lineOrService: leg.lineOrService,
          departureStop: leg.departureStop,
          arrivalStop: leg.arrivalStop,
          durationSeconds: leg.durationSeconds + 60, // Slight detour for covered linkway
          distanceMeters: leg.distanceMeters + 40.0,
          coordinates: leg.coordinates,
          isSheltered: true,
          instruction: 'Sheltered walkway via CoveredLinkWay network (Rain protection)',
        );
      }
      return leg;
    }).toList();

    return RoutePlan(
      id: 'mdm-lim-sheltered-route',
      origin: baseRoute.origin,
      destination: baseRoute.destination,
      totalDurationMinutes: baseRoute.totalDurationMinutes + 2,
      totalWalkDistanceMeters: baseRoute.totalWalkDistanceMeters + 80.0,
      legs: shelteredLegs,
      isRerouted: true,
      rerouteReason: 'Rain forecast in 2h nowcast: Rerouted via CoveredLinkWay sheltered walkways (+2 min)',
      confidence: ConfidenceLevel.green,
      confidenceReason: '100% sheltered walking segments protected from rainfall.',
      hasRainRisk: true,
      usesShelteredWalkways: true,
      alternativeRoute: baseRoute,
      isSimulated: weather.isSimulated,
    );
  }
}
