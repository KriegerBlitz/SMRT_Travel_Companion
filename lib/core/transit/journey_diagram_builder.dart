import 'package:flutter/material.dart';
import '../models/journey_diagram_data.dart';
import '../models/route_plan.dart';
import 'canonical_line_table.dart';

/// Pure business logic service for transforming a multi-modal [RoutePlan]
/// into a structured [JourneyDiagramData] model for schematic transit rendering.
class JourneyDiagramBuilder {
  const JourneyDiagramBuilder();

  /// Builds a [JourneyDiagramData] from a [RoutePlan].
  JourneyDiagramData buildDiagram(RoutePlan plan) {
    final segments = <DiagramSegment>[];

    for (int legIndex = 0; legIndex < plan.legs.length; legIndex++) {
      final leg = plan.legs[legIndex];
      final isFirstLeg = legIndex == 0;
      final isLastLeg = legIndex == plan.legs.length - 1;

      if (leg.mode == 'SUBWAY') {
        segments.add(_buildSubwaySegment(
          leg: leg,
          isFirstLeg: isFirstLeg,
          isLastLeg: isLastLeg,
        ));
      } else if (leg.mode == 'BUS' || leg.mode == 'SHUTTLE') {
        segments.add(_buildShuttleSegment(
          leg: leg,
          isFirstLeg: isFirstLeg,
          isLastLeg: isLastLeg,
        ));
      } else {
        // WALK leg
        segments.add(_buildWalkSegment(leg: leg));
      }
    }

    return JourneyDiagramData(
      origin: plan.origin,
      destination: plan.destination,
      totalDurationMinutes: plan.totalDurationMinutes,
      etaConfidenceLabel: plan.confidence.label,
      etaConfidenceColor: plan.confidence.color,
      confidenceReason: plan.confidenceReason,
      isRerouted: plan.isRerouted,
      rerouteReason: plan.rerouteReason,
      segments: segments,
    );
  }

  DiagramSegment _buildSubwaySegment({
    required RouteLeg leg,
    required bool isFirstLeg,
    required bool isLastLeg,
  }) {
    final lineCode = leg.lineOrService ?? 'MRT';
    final transitLine = _resolveTransitLine(lineCode, leg.departureStop);
    final lineColor = transitLine?.color ?? const Color(0xFF009645); // default green

    final lineStations = _resolveStationSequence(
      line: transitLine,
      departureStop: leg.departureStop,
      arrivalStop: leg.arrivalStop,
    );

    final nodes = <DiagramStationNode>[];
    for (int i = 0; i < lineStations.length; i++) {
      final station = lineStations[i];
      final isStart = i == 0;
      final isEnd = i == lineStations.length - 1;

      DiagramNodeType nodeType;
      bool isImportant;

      if (isStart) {
        nodeType = isFirstLeg ? DiagramNodeType.origin : DiagramNodeType.transfer;
        isImportant = true;
      } else if (isEnd) {
        nodeType = isLastLeg ? DiagramNodeType.destination : DiagramNodeType.transfer;
        isImportant = true;
      } else {
        nodeType = DiagramNodeType.intermediate;
        isImportant = false;
      }

      nodes.add(
        DiagramStationNode(
          name: station.name,
          code: station.code,
          allCodes: station.allCodes,
          nodeType: nodeType,
          color: lineColor,
          isImportant: isImportant,
          isUnderground: station.groundLevel.isUnderground,
          subtitle: isStart && leg.instruction != null
              ? leg.instruction
              : (isEnd && !isLastLeg ? 'Transfer' : null),
        ),
      );
    }

    return DiagramSegment(
      mode: 'SUBWAY',
      title: transitLine?.name ?? '$lineCode Line',
      lineCode: transitLine?.canonicalCode ?? lineCode,
      color: lineColor,
      durationMinutes: leg.durationMinutes,
      distanceMeters: leg.distanceMeters,
      instruction: leg.instruction,
      stations: nodes,
    );
  }

  DiagramSegment _buildShuttleSegment({
    required RouteLeg leg,
    required bool isFirstLeg,
    required bool isLastLeg,
  }) {
    const shuttleColor = Color(0xFFF59E0B); // Amber warning / shuttle color

    final departureNode = DiagramStationNode(
      name: _cleanStopName(leg.departureStop),
      code: _extractStationCode(leg.departureStop),
      nodeType: isFirstLeg ? DiagramNodeType.origin : DiagramNodeType.transfer,
      color: shuttleColor,
      isImportant: true,
      subtitle: 'Board Free MRT Shuttle / Bus',
    );

    final arrivalNode = DiagramStationNode(
      name: _cleanStopName(leg.arrivalStop),
      code: _extractStationCode(leg.arrivalStop),
      nodeType: isLastLeg ? DiagramNodeType.destination : DiagramNodeType.transfer,
      color: shuttleColor,
      isImportant: true,
      subtitle: 'Alight Shuttle',
    );

    return DiagramSegment(
      mode: 'SHUTTLE',
      title: leg.lineOrService ?? 'Free MRT Shuttle Bus',
      lineCode: 'BUS',
      color: shuttleColor,
      durationMinutes: leg.durationMinutes,
      distanceMeters: leg.distanceMeters,
      instruction: leg.instruction,
      stations: [departureNode, arrivalNode],
    );
  }

  DiagramSegment _buildWalkSegment({
    required RouteLeg leg,
  }) {
    final walkColor = leg.isSheltered
        ? const Color(0xFF00D26A) // SMRT green sheltered
        : const Color(0xFF64748B); // Slate grey

    final fromNode = DiagramStationNode(
      name: _cleanStopName(leg.departureStop),
      code: _extractStationCode(leg.departureStop),
      nodeType: DiagramNodeType.walkStep,
      color: walkColor,
      isImportant: false,
      subtitle: leg.instruction ?? 'Walk to station',
    );

    final toNode = DiagramStationNode(
      name: _cleanStopName(leg.arrivalStop),
      code: _extractStationCode(leg.arrivalStop),
      nodeType: DiagramNodeType.walkStep,
      color: walkColor,
      isImportant: false,
      subtitle: leg.isSheltered ? 'Sheltered Walkway (Rain-safe)' : null,
    );

    return DiagramSegment(
      mode: 'WALK',
      title: leg.isSheltered ? 'Sheltered Walk' : 'Walk',
      lineCode: 'WALK',
      color: walkColor,
      durationMinutes: leg.durationMinutes,
      distanceMeters: leg.distanceMeters,
      isSheltered: leg.isSheltered,
      instruction: leg.instruction,
      stations: [fromNode, toNode],
    );
  }

  /// Resolves the ordered sequence of stations along a line between departure and arrival.
  List<Station> _resolveStationSequence({
    required TransitLine? line,
    required String departureStop,
    required String arrivalStop,
  }) {
    final depStation = _findStation(departureStop);
    final arrStation = _findStation(arrivalStop);

    if (line == null) {
      return [
        depStation ?? Station(
          name: _cleanStopName(departureStop),
          code: _extractStationCode(departureStop) ?? '',
          lat: 1.35,
          lon: 103.85,
          lines: const [],
          groundLevel: GroundLevel.aboveGround,
        ),
        arrStation ?? Station(
          name: _cleanStopName(arrivalStop),
          code: _extractStationCode(arrivalStop) ?? '',
          lat: 1.35,
          lon: 103.85,
          lines: const [],
          groundLevel: GroundLevel.aboveGround,
        ),
      ];
    }

    // Find all stations for this line
    final lineStations = CanonicalLineTable.allStations
        .where((s) => s.hasLine(line.canonicalCode) || _hasMatchingPrefix(s, line))
        .toList();

    // Sort stations by their line code number (e.g. DT1, DT2, ... DT34)
    lineStations.sort((a, b) {
      final numA = _extractCodeNumberForLine(a, line);
      final numB = _extractCodeNumberForLine(b, line);
      return numA.compareTo(numB);
    });

    final startIndex = lineStations.indexWhere(
      (s) => _isSameStation(s, depStation, departureStop),
    );
    final endIndex = lineStations.indexWhere(
      (s) => _isSameStation(s, arrStation, arrivalStop),
    );

    if (startIndex != -1 && endIndex != -1) {
      if (startIndex <= endIndex) {
        return lineStations.sublist(startIndex, endIndex + 1);
      } else {
        return lineStations.sublist(endIndex, startIndex + 1).reversed.toList();
      }
    }

    // Fallback if sequence slicing couldn't find exact match
    return [
      depStation ?? Station(
        name: _cleanStopName(departureStop),
        code: _extractStationCode(departureStop) ?? line.stationPrefixes.first,
        lat: 1.35,
        lon: 103.85,
        lines: [line.canonicalCode],
        groundLevel: GroundLevel.aboveGround,
      ),
      arrStation ?? Station(
        name: _cleanStopName(arrivalStop),
        code: _extractStationCode(arrivalStop) ?? line.stationPrefixes.first,
        lat: 1.35,
        lon: 103.85,
        lines: [line.canonicalCode],
        groundLevel: GroundLevel.aboveGround,
      ),
    ];
  }

  bool _hasMatchingPrefix(Station s, TransitLine line) {
    for (final prefix in line.stationPrefixes) {
      for (final c in s.allCodes) {
        if (c.toUpperCase().startsWith(prefix.toUpperCase())) return true;
      }
    }
    return false;
  }

  int _extractCodeNumberForLine(Station s, TransitLine line) {
    for (final prefix in line.stationPrefixes) {
      for (final c in s.allCodes) {
        if (c.toUpperCase().startsWith(prefix.toUpperCase())) {
          final digits = c.replaceAll(RegExp(r'[^0-9]'), '');
          return int.tryParse(digits) ?? 999;
        }
      }
    }
    return 999;
  }

  bool _isSameStation(Station s, Station? targetStation, String rawName) {
    if (targetStation != null && s.name.toLowerCase() == targetStation.name.toLowerCase()) {
      return true;
    }
    final clean = _cleanStopName(rawName).toLowerCase();
    return s.name.toLowerCase().contains(clean) || clean.contains(s.name.toLowerCase());
  }

  Station? _findStation(String name) {
    final clean = _cleanStopName(name).toLowerCase();
    final code = _extractStationCode(name);

    for (final s in CanonicalLineTable.allStations) {
      if (code != null && s.matchesCode(code)) return s;
      if (s.name.toLowerCase() == clean) return s;
    }

    for (final s in CanonicalLineTable.allStations) {
      if (s.name.toLowerCase().contains(clean) || clean.contains(s.name.toLowerCase())) {
        return s;
      }
    }
    return null;
  }

  TransitLine? _resolveTransitLine(String lineCode, String stopHint) {
    final upper = lineCode.trim().toUpperCase();
    for (final l in TransitLine.values) {
      if (l.canonicalCode == upper || l.alertsCode == upper || l.crowdCode == upper) {
        return l;
      }
    }

    // Check station code in stop hint (e.g. DT14 -> DTL)
    final code = _extractStationCode(stopHint);
    if (code != null) {
      return CanonicalLineTable.fromStationCode(code);
    }
    return null;
  }

  String _cleanStopName(String raw) {
    var s = raw.replaceAll(RegExp(r'\([A-Z0-9/ ]+\)'), '').trim();
    return s.isEmpty ? raw : s;
  }

  String? _extractStationCode(String raw) {
    final match = RegExp(r'\(([A-Z0-9/]+)\)').firstMatch(raw);
    if (match != null) {
      return match.group(1);
    }
    return null;
  }
}
