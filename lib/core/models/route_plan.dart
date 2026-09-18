import 'package:flutter/material.dart';
import 'crowd_density.dart';

/// ETA Confidence Band color rating.
/// Never a single fake-precise number — color-coded with explanation.
enum ConfidenceLevel {
  green, // High confidence (normal operations, stable crowds)
  amber, // Moderate confidence (crowds rising, minor delays)
  red; // Low confidence (active disruption, heavy rerouting)

  String get label {
    switch (this) {
      case ConfidenceLevel.green:
        return 'High Confidence';
      case ConfidenceLevel.amber:
        return 'Moderate Confidence';
      case ConfidenceLevel.red:
        return 'Low Confidence';
    }
  }

  Color get color {
    switch (this) {
      case ConfidenceLevel.green:
        return const Color(0xFF10B981);
      case ConfidenceLevel.amber:
        return const Color(0xFFF59E0B);
      case ConfidenceLevel.red:
        return const Color(0xFFEF4444);
    }
  }
}

/// A leg of a multi-modal door-to-door journey.
class RouteLeg {
  final String mode; // 'WALK', 'SUBWAY', 'BUS', 'SHUTTLE'
  final String? lineOrService; // e.g. 'EWL', '190', 'SHUTTLE-EWL'
  final String departureStop;
  final String arrivalStop;
  final String? departureStationCode;
  final String? arrivalStationCode;
  final CrowdLevel crowdLevel;
  final int durationSeconds;
  final double distanceMeters;
  final List<List<double>> coordinates; // [[lat, lon], ...]
  final bool isSheltered;
  final bool isDisrupted;
  final String? instruction;

  const RouteLeg({
    required this.mode,
    this.lineOrService,
    required this.departureStop,
    required this.arrivalStop,
    this.departureStationCode,
    this.arrivalStationCode,
    this.crowdLevel = CrowdLevel.na,
    required this.durationSeconds,
    this.distanceMeters = 0.0,
    this.coordinates = const [],
    this.isSheltered = false,
    this.isDisrupted = false,
    this.instruction,
  });

  int get durationMinutes => (durationSeconds / 60).round();
}

/// Complete door-to-door route plan.
class RoutePlan {
  final String id;
  final String origin;
  final String destination;
  final int totalDurationMinutes;
  final double totalWalkDistanceMeters;
  final String title;
  final String? badge;
  final List<RouteLeg> legs;
  final bool isRerouted;
  final String? rerouteReason;
  final ConfidenceLevel confidence;
  final String confidenceReason;
  final bool hasRainRisk;
  final bool usesShelteredWalkways;
  final RoutePlan? alternativeRoute; // Shown side-by-side
  final Map<String, CrowdLevel> stationCrowds;
  final bool isSimulated;

  const RoutePlan({
    required this.id,
    required this.origin,
    required this.destination,
    required this.totalDurationMinutes,
    this.totalWalkDistanceMeters = 0.0,
    this.title = 'Fastest Transit Route',
    this.badge,
    required this.legs,
    this.isRerouted = false,
    this.rerouteReason,
    this.confidence = ConfidenceLevel.green,
    required this.confidenceReason,
    this.hasRainRisk = false,
    this.usesShelteredWalkways = false,
    this.alternativeRoute,
    this.stationCrowds = const {},
    this.isSimulated = false,
  });

  RoutePlan copyWith({
    String? id,
    String? origin,
    String? destination,
    int? totalDurationMinutes,
    double? totalWalkDistanceMeters,
    String? title,
    String? badge,
    List<RouteLeg>? legs,
    bool? isRerouted,
    String? rerouteReason,
    ConfidenceLevel? confidence,
    String? confidenceReason,
    bool? hasRainRisk,
    bool? usesShelteredWalkways,
    RoutePlan? alternativeRoute,
    Map<String, CrowdLevel>? stationCrowds,
    bool? isSimulated,
  }) {
    return RoutePlan(
      id: id ?? this.id,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      totalDurationMinutes: totalDurationMinutes ?? this.totalDurationMinutes,
      totalWalkDistanceMeters:
          totalWalkDistanceMeters ?? this.totalWalkDistanceMeters,
      title: title ?? this.title,
      badge: badge ?? this.badge,
      legs: legs ?? this.legs,
      isRerouted: isRerouted ?? this.isRerouted,
      rerouteReason: rerouteReason ?? this.rerouteReason,
      confidence: confidence ?? this.confidence,
      confidenceReason: confidenceReason ?? this.confidenceReason,
      hasRainRisk: hasRainRisk ?? this.hasRainRisk,
      usesShelteredWalkways:
          usesShelteredWalkways ?? this.usesShelteredWalkways,
      alternativeRoute: alternativeRoute ?? this.alternativeRoute,
      stationCrowds: stationCrowds ?? this.stationCrowds,
      isSimulated: isSimulated ?? this.isSimulated,
    );
  }

  /// Realistic ETA band with confidence interval instead of a single fake-precise number
  String get etaBand {
    switch (confidence) {
      case ConfidenceLevel.green:
        // High confidence: small realistic window e.g. 35 - 38 min
        return '$totalDurationMinutes–${totalDurationMinutes + 3} min';
      case ConfidenceLevel.amber:
        // Moderate confidence: platform crowding or delay window
        return '$totalDurationMinutes–${totalDurationMinutes + 8} min';
      case ConfidenceLevel.red:
        // Low confidence: major disruption with high uncertainty
        return '$totalDurationMinutes–${totalDurationMinutes + 20}+ min';
    }
  }

  /// Calculates the time difference compared to the alternative/original route (in minutes)
  int? get delayDifferenceMinutes {
    if (alternativeRoute == null) return null;
    return totalDurationMinutes - alternativeRoute!.totalDurationMinutes;
  }

  /// All transit lines used in this route
  List<String> get transitLinesUsed => legs
      .where((l) => l.mode == 'SUBWAY' && l.lineOrService != null)
      .map((l) => l.lineOrService!)
      .toSet()
      .toList();

  /// Coordinates for unaffected segments
  List<List<double>> get unaffectedCoordinates {
    final coords = <List<double>>[];
    for (final leg in legs) {
      if (!leg.isDisrupted) {
        coords.addAll(leg.coordinates);
      }
    }
    return coords;
  }

  /// Coordinates for affected/disrupted segments
  List<List<double>> get affectedCoordinates {
    final coords = <List<double>>[];
    for (final leg in legs) {
      if (leg.isDisrupted) {
        coords.addAll(leg.coordinates);
      }
    }
    return coords;
  }

  /// Sheltered walkway coordinates
  List<List<double>> get shelteredCoordinates {
    final coords = <List<double>>[];
    for (final leg in legs) {
      if (leg.isSheltered) {
        coords.addAll(leg.coordinates);
      }
    }
    return coords;
  }
}

