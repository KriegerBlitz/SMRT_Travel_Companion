import '../core/canonical_line_codes.dart';
import '../ui/map/leaflet_controller.dart';
import 'geospatial_service.dart';

enum ETAConfidence {
  green('High Confidence', '#22C55E'),
  amber('Moderate Confidence', '#F59E0B'),
  red('Low / High Delay Risk', '#EF4444');

  final String label;
  final String hexColor;
  const ETAConfidence(this.label, this.hexColor);
}

class RouteLeg {
  final String mode; // 'WALK' | 'MRT' | 'BUS' | 'SHUTTLE'
  final String instruction;
  final int durationMinutes;
  final double distanceMeters;
  final List<LatLng> pathCoordinates;
  final bool isSheltered;
  final bool isBarrierFree;
  final String? serviceCode; // e.g. 'EWL', '147', 'SHUTTLE-TAMPINES'

  const RouteLeg({
    required this.mode,
    required this.instruction,
    required this.durationMinutes,
    required this.distanceMeters,
    required this.pathCoordinates,
    this.isSheltered = false,
    this.isBarrierFree = true,
    this.serviceCode,
  });
}

class DoorToDoorRoute {
  final String id;
  final String title;
  final String originName;
  final String destinationName;
  final int totalMinutes;
  final int baseMinutes;
  final int delayMinutes;
  final ETAConfidence confidence;
  final String confidenceReason;
  final List<RouteLeg> legs;
  final String? revisionReason; // 1-line reason if revised
  final bool isAlternative;
  final bool usesShelteredWalkway;
  final bool isStepFree;

  const DoorToDoorRoute({
    required this.id,
    required this.title,
    required this.originName,
    required this.destinationName,
    required this.totalMinutes,
    required this.baseMinutes,
    this.delayMinutes = 0,
    required this.confidence,
    required this.confidenceReason,
    required this.legs,
    this.revisionReason,
    this.isAlternative = false,
    this.usesShelteredWalkway = false,
    this.isStepFree = true,
  });

  List<LatLng> get allCoordinates {
    final List<LatLng> coords = [];
    for (final leg in legs) {
      coords.addAll(leg.pathCoordinates);
    }
    return coords;
  }
}

class OneMapService {
  /// Builds door-to-door route for Rachel (Tampines -> Raffles Place)
  /// Door-to-door: Walking leg at start + MRT leg + Walking leg at end.
  static DoorToDoorRoute buildRachelRoute({
    bool isDisrupted = false,
    bool crowdSpike = false,
    String? disruptionReason,
  }) {
    final tampines = CanonicalLineCodes.findStationByCode('EW2')!;
    final raffles = CanonicalLineCodes.findStationByCode('EW14')!;
    final mrtStations = CanonicalLineCodes.getRouteSequence(tampines, raffles);

    // Walking start leg: Tampines Blk 215 -> Tampines MRT
    final walkStartLeg = RouteLeg(
      mode: 'WALK',
      instruction: 'Walk 320m from Tampines Central to Tampines MRT (EW2) Exit A',
      durationMinutes: 4,
      distanceMeters: 320,
      pathCoordinates: [
        const LatLng(1.3550, 103.9440),
        const LatLng(1.3542, 103.9446),
        LatLng(tampines.lat, tampines.lng),
      ],
      isSheltered: false,
    );

    // Walking end leg: Raffles Place MRT Exit G -> One Raffles Place Office
    final walkEndLeg = RouteLeg(
      mode: 'WALK',
      instruction: 'Walk 180m from Raffles Place MRT Exit G to One Raffles Place',
      durationMinutes: 3,
      distanceMeters: 180,
      pathCoordinates: [
        LatLng(raffles.lat, raffles.lng),
        const LatLng(1.2843, 103.8510),
        const LatLng(1.2848, 103.8508),
      ],
      isSheltered: true,
    );

    if (isDisrupted) {
      // Disruption detected: Uses real LTA mitigation data (Free MRT Shuttle Bus from Tampines)
      final shuttleLeg = RouteLeg(
        mode: 'SHUTTLE',
        instruction:
            'Board Free MRT Shuttle Bus at Tampines Bus Interchange Bay 8 towards Bugis',
        durationMinutes: 32,
        distanceMeters: 12500,
        serviceCode: 'FREE-MRT-SHUTTLE',
        pathCoordinates: [
          LatLng(tampines.lat, tampines.lng),
          const LatLng(1.3400, 103.9200),
          const LatLng(1.3200, 103.8800),
          const LatLng(1.3005, 103.8560), // Bugis
        ],
      );

      final transferMrtLeg = RouteLeg(
        mode: 'MRT',
        instruction: 'Transfer to Downtown Line / EWL from Bugis to Raffles Place',
        durationMinutes: 6,
        distanceMeters: 1800,
        serviceCode: 'DTL/EWL',
        pathCoordinates: [
          const LatLng(1.3005, 103.8560), // Bugis
          const LatLng(1.2931, 103.8521), // City Hall
          LatLng(raffles.lat, raffles.lng),
        ],
      );

      return DoorToDoorRoute(
        id: 'rachel_route_disrupted',
        title: 'Mitigation Route (Free Shuttle)',
        originName: 'Tampines Central',
        destinationName: 'One Raffles Place',
        totalMinutes: 45,
        baseMinutes: 35,
        delayMinutes: 10,
        confidence: ETAConfidence.amber,
        confidenceReason:
            'Delay likely today (+10 min): Active EWL signal alert near Pasir Ris/Tampines. Shuttle bus running.',
        revisionReason: disruptionReason ??
            'Signal fault detected between Tampines and Pasir Ris — rerouted via LTA Free MRT Shuttle.',
        isAlternative: true,
        legs: [walkStartLeg, shuttleLeg, transferMrtLeg, walkEndLeg],
      );
    }

    // Normal train leg
    final mrtLeg = RouteLeg(
      mode: 'MRT',
      instruction:
          'Take East-West Line from Tampines (EW2) to Raffles Place (EW14) (12 stops)',
      durationMinutes: 28,
      distanceMeters: 14200,
      serviceCode: 'EWL',
      pathCoordinates: mrtStations.map((s) => LatLng(s.lat, s.lng)).toList(),
    );

    ETAConfidence conf = ETAConfidence.green;
    String confReason = 'Normal schedule. All EWL segments running on time.';
    int total = 35;
    int delay = 0;

    if (crowdSpike) {
      conf = ETAConfidence.amber;
      confReason =
          'Platform crowd forecast rising to HIGH at Tampines between 07:45 - 08:15. Leave 10 min earlier.';
      total = 38;
      delay = 3;
    }

    return DoorToDoorRoute(
      id: 'rachel_route_normal',
      title: 'Standard Commute (EWL Direct)',
      originName: 'Tampines Central',
      destinationName: 'One Raffles Place',
      totalMinutes: total,
      baseMinutes: 35,
      delayMinutes: delay,
      confidence: conf,
      confidenceReason: confReason,
      legs: [walkStartLeg, mrtLeg, walkEndLeg],
      revisionReason: crowdSpike
          ? 'Platform crowd rising: leave 10 min early to avoid boarding delays.'
          : null,
    );
  }

  /// Builds door-to-door route for Mdm Lim (Bedok -> SGH)
  /// Door-to-door: Step-free, lifts, and sheltered walkway options.
  static DoorToDoorRoute buildMdmLimRoute({
    bool liftDown = false,
    bool isRaining = false,
  }) {
    final bedok = CanonicalLineCodes.findStationByCode('EW5')!;
    final outram = CanonicalLineCodes.findStationByCode('EW16')!;
    final mrtStations = CanonicalLineCodes.getRouteSequence(bedok, outram);

    // Bedok start leg: Bedok South Ave 3 to Bedok MRT Exit B (via CoveredLinkWay ramp)
    final startWalk = RouteLeg(
      mode: 'WALK',
      instruction: 'Take ramp to Bedok MRT Exit B via covered walkway (250m, step-free)',
      durationMinutes: 5,
      distanceMeters: 250,
      isSheltered: true,
      isBarrierFree: true,
      pathCoordinates: [
        const LatLng(1.3255, 103.9310),
        const LatLng(1.3248, 103.9304),
        LatLng(bedok.lat, bedok.lng),
      ],
    );

    if (liftDown) {
      // Lift outage at Outram Park Exit 1 -> Suggested Wheelchair-Accessible Bus 147
      final wabBusLeg = RouteLeg(
        mode: 'BUS',
        instruction:
            'Board Wheelchair-Accessible Bus 147 at Bedok Int to Outram Park Stn/SGH (Stop 06011)',
        durationMinutes: 24,
        distanceMeters: 11000,
        serviceCode: 'BUS 147 (WAB)',
        isBarrierFree: true,
        pathCoordinates: [
          LatLng(bedok.lat, bedok.lng),
          const LatLng(1.3180, 103.8930),
          const LatLng(1.3000, 103.8550),
          const LatLng(1.2803, 103.8395),
        ],
      );

      final shortWalkToSGH = RouteLeg(
        mode: 'WALK',
        instruction: 'Wheelchair ramp from bus stop 06011 directly into SGH Block 4 (120m)',
        durationMinutes: 3,
        distanceMeters: 120,
        isSheltered: true,
        isBarrierFree: true,
        pathCoordinates: [
          const LatLng(1.2803, 103.8395),
          const LatLng(1.2795, 103.8375),
          const LatLng(1.2789, 103.8355),
        ],
      );

      return DoorToDoorRoute(
        id: 'mdm_lim_route_wab',
        title: 'Step-Free Alternative (WAB Bus 147)',
        originName: 'Bedok South Ave 3',
        destinationName: 'Singapore General Hospital (SGH)',
        totalMinutes: 32,
        baseMinutes: 28,
        delayMinutes: 4,
        confidence: ETAConfidence.green,
        confidenceReason:
            'Verified accessible: Bus 147 is double-deck WAB with Seats Available (SEA).',
        revisionReason:
            'Outram Park Exit 1 Lift 2 out of service — revised to direct Wheelchair-Accessible Bus 147.',
        isAlternative: true,
        usesShelteredWalkway: true,
        isStepFree: true,
        legs: [startWalk, wabBusLeg, shortWalkToSGH],
      );
    }

    // Normal MRT leg: Bedok -> Outram Park
    final mrtLeg = RouteLeg(
      mode: 'MRT',
      instruction:
          'Take East-West Line from Bedok (EW5) to Outram Park (EW16) (8 stops)',
      durationMinutes: 18,
      distanceMeters: 9600,
      serviceCode: 'EWL',
      isBarrierFree: true,
      pathCoordinates: mrtStations.map((s) => LatLng(s.lat, s.lng)).toList(),
    );

    // Last mile walking leg: Outram Park to SGH
    RouteLeg endWalk;
    if (isRaining) {
      // Weather-aware routing: uses CoveredLinkWay sheltered linkway
      endWalk = RouteLeg(
        mode: 'WALK',
        instruction:
            'Take Exit 1 Lift to Hospital Drive CoveredLinkWay (Sheltered path to SGH Block 4)',
        durationMinutes: 7,
        distanceMeters: 450,
        isSheltered: true,
        isBarrierFree: true,
        pathCoordinates: GeospatialService.coveredWalkways.first.coordinates,
      );
    } else {
      // Standard step-free walk
      endWalk = RouteLeg(
        mode: 'WALK',
        instruction:
            'Take Exit 1 Lift to Hospital Drive path to SGH Main Complex (380m)',
        durationMinutes: 5,
        distanceMeters: 380,
        isSheltered: false,
        isBarrierFree: true,
        pathCoordinates: GeospatialService.uncoveredWalkwayToSGH,
      );
    }

    return DoorToDoorRoute(
      id: isRaining ? 'mdm_lim_route_sheltered' : 'mdm_lim_route_normal',
      title: isRaining ? 'Sheltered Step-Free Route' : 'Step-Free MRT Route',
      originName: 'Bedok South Ave 3',
      destinationName: 'Singapore General Hospital (SGH)',
      totalMinutes: isRaining ? 30 : 28,
      baseMinutes: 28,
      delayMinutes: isRaining ? 2 : 0,
      confidence: ETAConfidence.green,
      confidenceReason: isRaining
          ? 'Rain nowcast active: Sheltered CoveredLinkWay path active. All lifts operating.'
          : 'All lifts and ramps operational. Low platform crowding.',
      revisionReason: isRaining
          ? 'Passing showers forecast in Outram/Bukit Merah — proactively switched to CoveredLinkWay.'
          : null,
      usesShelteredWalkway: isRaining,
      isStepFree: true,
      legs: [startWalk, mrtLeg, endWalk],
    );
  }
}
