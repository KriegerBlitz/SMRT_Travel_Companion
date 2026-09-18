import 'package:flutter/material.dart';

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
  final List<RouteLeg> legs;
  final bool isRerouted;
  final String? rerouteReason;
  final ConfidenceLevel confidence;
  final String confidenceReason;
  final bool hasRainRisk;
  final bool usesShelteredWalkways;
  final RoutePlan? alternativeRoute; // Shown side-by-side
  final bool isSimulated;

  const RoutePlan({
    required this.id,
    required this.origin,
    required this.destination,
    required this.totalDurationMinutes,
    this.totalWalkDistanceMeters = 0.0,
    required this.legs,
    this.isRerouted = false,
    this.rerouteReason,
    this.confidence = ConfidenceLevel.green,
    required this.confidenceReason,
    this.hasRainRisk = false,
    this.usesShelteredWalkways = false,
    this.alternativeRoute,
    this.isSimulated = false,
  });

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
