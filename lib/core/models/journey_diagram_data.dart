import 'package:flutter/material.dart';

/// Type of node in a transit diagram schematic.
enum DiagramNodeType {
  origin,
  destination,
  transfer,
  intermediate,
  walkStep,
  shuttleStep,
}

/// A station or waypoint node rendered on the schematic transit diagram.
class DiagramStationNode {
  final String name;
  final String? code;
  final List<String> allCodes;
  final DiagramNodeType nodeType;
  final Color color;
  final bool isImportant;
  final bool isUnderground;
  final String? subtitle;
  final String? timeDisplay;

  const DiagramStationNode({
    required this.name,
    this.code,
    this.allCodes = const [],
    required this.nodeType,
    required this.color,
    this.isImportant = false,
    this.isUnderground = false,
    this.subtitle,
    this.timeDisplay,
  });

  /// True if this node represents an interchange with multiple lines
  bool get isInterchange => allCodes.length > 1;
}

/// A segment of the journey (e.g. a train ride along a line, or a walking transfer).
class DiagramSegment {
  final String mode; // 'SUBWAY', 'WALK', 'BUS', 'SHUTTLE'
  final String title;
  final String? lineCode; // e.g. 'DTL', 'NEL', 'EWL'
  final Color color;
  final int durationMinutes;
  final double distanceMeters;
  final bool isSheltered;
  final String? instruction;
  final List<DiagramStationNode> stations;

  const DiagramSegment({
    required this.mode,
    required this.title,
    this.lineCode,
    required this.color,
    required this.durationMinutes,
    this.distanceMeters = 0.0,
    this.isSheltered = false,
    this.instruction,
    required this.stations,
  });

  bool get isSubway => mode == 'SUBWAY';
  bool get isWalk => mode == 'WALK';
  bool get isShuttle => mode == 'SHUTTLE' || mode == 'BUS';
}

/// Complete diagram data ready for schematic rendering in the UI.
class JourneyDiagramData {
  final String origin;
  final String destination;
  final int totalDurationMinutes;
  final String etaConfidenceLabel;
  final Color etaConfidenceColor;
  final String confidenceReason;
  final bool isRerouted;
  final String? rerouteReason;
  final List<DiagramSegment> segments;

  const JourneyDiagramData({
    required this.origin,
    required this.destination,
    required this.totalDurationMinutes,
    required this.etaConfidenceLabel,
    required this.etaConfidenceColor,
    required this.confidenceReason,
    this.isRerouted = false,
    this.rerouteReason,
    required this.segments,
  });

  /// Total count of train stations traversed
  int get totalStationCount {
    int count = 0;
    for (final seg in segments) {
      if (seg.isSubway) {
        count += seg.stations.length;
      }
    }
    return count;
  }
}
