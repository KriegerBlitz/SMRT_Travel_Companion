import 'package:flutter/material.dart';

/// Representation of station elevation/ground level matching official LTA dataset categories.
///
/// In LTA Master Plan Rail Station dataset (AmendmenttoMP2014RailStation.geojson),
/// stations are strictly classified into UNDERGROUND and ABOVEGROUND.
enum GroundLevel {
  underground,
  aboveGround;

  /// Parses a ground level string handling hyphenation, underscores, case, and dataset variants.
  static GroundLevel fromString(String? val) {
    if (val == null) return GroundLevel.aboveGround;
    final normalized = val
        .trim()
        .toLowerCase()
        .replaceAll('-', '')
        .replaceAll('_', '')
        .replaceAll(' ', '');

    switch (normalized) {
      case 'underground':
      case 'subsurface':
        return GroundLevel.underground;
      case 'aboveground':
      case 'elevated':
      case 'atgrade':
      default:
        return GroundLevel.aboveGround;
    }
  }

  /// Human-readable display label.
  String get displayName {
    switch (this) {
      case GroundLevel.underground:
        return 'Underground';
      case GroundLevel.aboveGround:
        return 'Above Ground';
    }
  }

  /// Whether the station is below surface level (where cellular and GPS signals degrade).
  bool get isUnderground => this == GroundLevel.underground;
}

/// Represents a train station on the MRT/LRT network.
class Station {
  final String name;
  final String code; // Primary station code (e.g. "EW14")
  final List<String> codes; // All line codes for interchange (e.g. ["EW14", "NS26"])
  final double lat;
  final double lon;
  final List<String> lines; // Canonical line identifiers (e.g. ["EWL", "NSL"])
  final List<String> exits;
  final GroundLevel groundLevel;

  const Station({
    required this.name,
    required this.code,
    this.codes = const [],
    required this.lat,
    required this.lon,
    required this.lines,
    this.exits = const [],
    required this.groundLevel,
  });

  /// Interchanges have multiple lines or multiple station codes
  bool get isInterchange => lines.length > 1 || allCodes.length > 1;

  /// Returns all assigned station codes (e.g. EW2 and DT32 for Tampines)
  List<String> get allCodes => codes.isNotEmpty ? codes : [code];

  /// Checks if a given station code matches this station (case-insensitive)
  bool matchesCode(String queryCode) {
    final q = queryCode.trim().toUpperCase();
    return allCodes.any((c) => c.toUpperCase() == q);
  }

  /// Checks if this station belongs to a specific line
  bool hasLine(String lineCode) {
    final q = lineCode.trim().toUpperCase();
    return lines.any((l) => l.toUpperCase() == q);
  }

  @override
  String toString() => '$name (${allCodes.join('/')}) - ${groundLevel.displayName}';
}

/// Canonical MRT and LRT lines in Singapore.
enum TransitLine {
  nsl(
    canonicalCode: 'NSL',
    name: 'North-South Line',
    color: Color(0xFFD42E12),
    alertsCode: 'NSL',
    crowdCode: 'NSL',
    stationPrefixes: ['NS'],
  ),
  ewl(
    canonicalCode: 'EWL',
    name: 'East-West Line',
    color: Color(0xFF009645),
    alertsCode: 'EWL',
    crowdCode: 'EWL',
    stationPrefixes: ['EW'],
  ),
  cgl(
    canonicalCode: 'CGL',
    name: 'Changi Airport Branch',
    color: Color(0xFF009645),
    alertsCode: 'EWL', // LTA Trap: folded into EWL in TrainServiceAlerts
    crowdCode: 'CGL', // LTA Trap: separate code CGL in PCDRealTime / Forecast
    stationPrefixes: ['CG'],
  ),
  nel(
    canonicalCode: 'NEL',
    name: 'North East Line',
    color: Color(0xFF7F2889),
    alertsCode: 'NEL',
    crowdCode: 'NEL',
    stationPrefixes: ['NE'],
  ),
  ccl(
    canonicalCode: 'CCL',
    name: 'Circle Line',
    color: Color(0xFFFA9E0D),
    alertsCode: 'CCL',
    crowdCode: 'CCL',
    stationPrefixes: ['CC'],
  ),
  cel(
    canonicalCode: 'CEL',
    name: 'Circle Line Extension',
    color: Color(0xFFFA9E0D),
    alertsCode: 'CCL', // LTA Trap: folded into CCL in TrainServiceAlerts
    crowdCode: 'CEL', // LTA Trap: separate code CEL in PCDRealTime / Forecast
    stationPrefixes: ['CE'],
  ),
  dtl(
    canonicalCode: 'DTL',
    name: 'Downtown Line',
    color: Color(0xFF005EC4),
    alertsCode: 'DTL',
    crowdCode: 'DTL',
    stationPrefixes: ['DT'],
  ),
  tel(
    canonicalCode: 'TEL',
    name: 'Thomson-East Coast Line',
    color: Color(0xFF9D5B25),
    alertsCode: 'TEL',
    crowdCode: 'TEL',
    stationPrefixes: ['TE'],
  ),
  bpl(
    canonicalCode: 'BPL',
    name: 'Bukit Panjang LRT',
    color: Color(0xFF748477),
    alertsCode: 'BPL',
    crowdCode: 'BPL',
    stationPrefixes: ['BP'],
  ),
  slrt(
    canonicalCode: 'SLRT',
    name: 'Sengkang LRT',
    color: Color(0xFF748477),
    alertsCode: 'STL', // LTA Trap: STL in TrainServiceAlerts
    crowdCode: 'SLRT', // LTA Trap: SLRT in PCDRealTime / Forecast
    stationPrefixes: ['STC', 'SE', 'SW'],
  ),
  plrt(
    canonicalCode: 'PLRT',
    name: 'Punggol LRT',
    color: Color(0xFF748477),
    alertsCode: 'PTL', // LTA Trap: PTL in TrainServiceAlerts
    crowdCode: 'PLRT', // LTA Trap: PLRT in PCDRealTime / Forecast
    stationPrefixes: ['PTC', 'PE', 'PW'],
  );

  final String canonicalCode;
  final String name;
  final Color color;

  /// The code used by DataMall TrainServiceAlerts
  final String alertsCode;

  /// The code used by DataMall PCDRealTime & PCDForecast
  final String crowdCode;

  /// Station code prefixes for this line (e.g. EW, CG, NS)
  final List<String> stationPrefixes;

  const TransitLine({
    required this.canonicalCode,
    required this.name,
    required this.color,
    required this.alertsCode,
    required this.crowdCode,
    required this.stationPrefixes,
  });
}

/// Canonical reconciliation table to resolve endpoint mismatches across LTA DataMall,
/// OneMap, and Station Crowd Density feeds.
class CanonicalLineTable {
  CanonicalLineTable._();

  /// Map of canonical line codes to TransitLine enum
  static final Map<String, TransitLine> _byCanonical = {
    for (final line in TransitLine.values) line.canonicalCode: line,
  };

  /// Resolves line from a DataMall TrainServiceAlerts line code (e.g. STL -> SLRT, PTL -> PLRT)
  static List<TransitLine> fromAlertsCode(String rawCode) {
    final code = rawCode.trim().toUpperCase();
    if (code == 'STL') return [TransitLine.slrt];
    if (code == 'PTL') return [TransitLine.plrt];
    if (code == 'EWL') return [TransitLine.ewl, TransitLine.cgl];
    if (code == 'CCL') return [TransitLine.ccl, TransitLine.cel];

    for (final line in TransitLine.values) {
      if (line.alertsCode == code) return [line];
    }
    return [];
  }

  /// Resolves line from a DataMall PCDRealTime / PCDForecast line code
  static TransitLine? fromCrowdCode(String rawCode) {
    final code = rawCode.trim().toUpperCase();
    for (final line in TransitLine.values) {
      if (line.crowdCode == code || line.canonicalCode == code) return line;
    }
    return null;
  }

  /// Resolves line from a station code (e.g. CG1 -> CGL, CE2 -> CEL, EW2 -> EWL)
  static TransitLine? fromStationCode(String stationCode) {
    final sCode = stationCode.trim().toUpperCase();
    for (final line in TransitLine.values) {
      for (final prefix in line.stationPrefixes) {
        if (sCode.startsWith(prefix)) return line;
      }
    }
    return null;
  }

  /// Translates any line/station code into the exact string required by PCDRealTime / PCDForecast
  static String toCrowdQueryLine(String lineOrStationCode) {
    final upper = lineOrStationCode.trim().toUpperCase();

    // Direct check if it matches a crowd code
    for (final line in TransitLine.values) {
      if (line.crowdCode == upper || line.canonicalCode == upper) {
        return line.crowdCode;
      }
    }

    // Check station code prefix (e.g. CG1 -> CGL, CE1 -> CEL)
    final fromStation = fromStationCode(upper);
    if (fromStation != null) {
      return fromStation.crowdCode;
    }

    // Fallbacks for known aliases
    if (upper == 'STL') return 'SLRT';
    if (upper == 'PTL') return 'PLRT';

    return upper;
  }

  /// Translates any line/station code into the exact string required by TrainServiceAlerts
  static String toAlertsLineCode(String lineOrStationCode) {
    final upper = lineOrStationCode.trim().toUpperCase();

    for (final line in TransitLine.values) {
      if (line.canonicalCode == upper || line.crowdCode == upper) {
        return line.alertsCode;
      }
    }

    final fromStation = fromStationCode(upper);
    if (fromStation != null) {
      return fromStation.alertsCode;
    }

    if (upper == 'SLRT') return 'STL';
    if (upper == 'PLRT') return 'PTL';

    return upper;
  }

  /// Normalizes any input line code to canonical code
  static String normalize(String rawCode) {
    final upper = rawCode.trim().toUpperCase();
    if (upper == 'STL') return 'SLRT';
    if (upper == 'PTL') return 'PLRT';
    final line = _byCanonical[upper] ?? fromCrowdCode(upper);
    return line?.canonicalCode ?? upper;
  }

  /// Parses comma-separated station codes from TrainServiceAlerts (e.g. "NE1,NE3,NE4,NE5,NE6")
  static List<String> parseAffectedStations(String raw) {
    if (raw.trim().isEmpty) return [];
    return raw
        .split(',')
        .map((s) => s.trim().toUpperCase())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Resolves a station by exact station code (e.g. EW28, NS24, DT14) or station name
  static Station? findStationByCodeOrName(String query) {
    final clean = query.trim();
    if (clean.isEmpty) return null;
    final upper = clean.toUpperCase();

    // 1. Direct station code match (e.g. EW28, DT14, NE1, CC19)
    for (final s in allStations) {
      if (s.matchesCode(upper)) return s;
    }

    // 2. Exact station name match (case-insensitive)
    final lower = clean.toLowerCase();
    for (final s in allStations) {
      if (s.name.toLowerCase() == lower) return s;
    }

    // 3. Substring match
    for (final s in allStations) {
      if (s.name.toLowerCase().contains(lower) || lower.contains(s.name.toLowerCase())) {
        return s;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Pre-mapped Singapore MRT / LRT Stations
  // ---------------------------------------------------------------------------
  static final List<Station> allStations = [
    const Station(
      name: 'Admiralty',
      code: 'NS10',
      codes: ['NS10'],
      lat: 1.44053,
      lon: 103.80089,
      lines: ['NSL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Aljunied',
      code: 'EW9',
      codes: ['EW9'],
      lat: 1.31641,
      lon: 103.883,
      lines: ['EWL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Ang Mo Kio',
      code: 'NS16',
      codes: ['NS16'],
      lat: 1.36989,
      lon: 103.84971,
      lines: ['NSL'],
      exits: ['A', 'B', 'C', 'D'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Bakau',
      code: 'SE3',
      codes: ['SE3'],
      lat: 1.38806,
      lon: 103.9055,
      lines: ['SLRT'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Bangkit',
      code: 'BP9',
      codes: ['BP9'],
      lat: 1.38002,
      lon: 103.77265,
      lines: ['BPL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Bartley',
      code: 'CC12',
      codes: ['CC12'],
      lat: 1.34297,
      lon: 103.87956,
      lines: ['CCL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Bayfront',
      code: 'CE1',
      codes: ['CE1', 'DT16'],
      lat: 1.28181,
      lon: 103.85915,
      lines: ['CEL', 'DTL'],
      exits: ['A', 'B', 'C', 'D', 'E'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Bayshore',
      code: 'TE29',
      codes: ['TE29'],
      lat: 1.31283,
      lon: 103.94231,
      lines: ['TEL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Beauty World',
      code: 'DT5',
      codes: ['DT5'],
      lat: 1.34089,
      lon: 103.77571,
      lines: ['DTL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Bedok',
      code: 'EW5',
      codes: ['EW5'],
      lat: 1.324,
      lon: 103.93021,
      lines: ['EWL'],
      exits: ['A', 'B', 'C'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Bedok North',
      code: 'DT29',
      codes: ['DT29'],
      lat: 1.3346,
      lon: 103.91831,
      lines: ['DTL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Bedok Reservoir',
      code: 'DT30',
      codes: ['DT30'],
      lat: 1.33653,
      lon: 103.93259,
      lines: ['DTL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Bencoolen',
      code: 'DT21',
      codes: ['DT21'],
      lat: 1.29879,
      lon: 103.85034,
      lines: ['DTL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Bendemeer',
      code: 'DT23',
      codes: ['DT23'],
      lat: 1.31364,
      lon: 103.86272,
      lines: ['DTL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Bishan',
      code: 'NS17',
      codes: ['NS17', 'CC15'],
      lat: 1.35064,
      lon: 103.84817,
      lines: ['NSL', 'CCL'],
      exits: ['A', 'B', 'C', 'D', 'E'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Boon Keng',
      code: 'NE9',
      codes: ['NE9'],
      lat: 1.31912,
      lon: 103.86142,
      lines: ['NEL'],
      exits: ['A', 'B', 'C'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Boon Lay',
      code: 'EW27',
      codes: ['EW27'],
      lat: 1.33871,
      lon: 103.70628,
      lines: ['EWL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Botanic Gardens',
      code: 'CC19',
      codes: ['CC19', 'DT9'],
      lat: 1.32207,
      lon: 103.81502,
      lines: ['CCL', 'DTL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Braddell',
      code: 'NS18',
      codes: ['NS18'],
      lat: 1.34052,
      lon: 103.84679,
      lines: ['NSL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Bras Basah',
      code: 'CC2',
      codes: ['CC2'],
      lat: 1.29699,
      lon: 103.85066,
      lines: ['CCL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Bright Hill',
      code: 'TE7',
      codes: ['TE7'],
      lat: 1.36299,
      lon: 103.83286,
      lines: ['TEL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Buangkok',
      code: 'NE15',
      codes: ['NE15'],
      lat: 1.38279,
      lon: 103.89314,
      lines: ['NEL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Bugis',
      code: 'EW12',
      codes: ['EW12', 'DT14'],
      lat: 1.29985,
      lon: 103.85653,
      lines: ['EWL', 'DTL'],
      exits: ['A', 'B', 'C', 'D'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Bukit Batok',
      code: 'NS2',
      codes: ['NS2'],
      lat: 1.3489,
      lon: 103.74946,
      lines: ['NSL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Bukit Gombak',
      code: 'NS3',
      codes: ['NS3'],
      lat: 1.35835,
      lon: 103.75186,
      lines: ['NSL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Bukit Panjang',
      code: 'DT1',
      codes: ['DT1', 'BP6'],
      lat: 1.3779,
      lon: 103.76305,
      lines: ['DTL', 'BPL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Buona Vista',
      code: 'EW21',
      codes: ['EW21', 'CC22'],
      lat: 1.30725,
      lon: 103.78972,
      lines: ['EWL', 'CCL'],
      exits: ['A', 'B', 'C', 'D'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Caldecott',
      code: 'CC17',
      codes: ['CC17', 'TE9'],
      lat: 1.33756,
      lon: 103.83957,
      lines: ['CCL', 'TEL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Canberra',
      code: 'NS12',
      codes: ['NS12'],
      lat: 1.44321,
      lon: 103.82963,
      lines: ['NSL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Cashew',
      code: 'DT2',
      codes: ['DT2'],
      lat: 1.36938,
      lon: 103.76472,
      lines: ['DTL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Changi Airport',
      code: 'CG2',
      codes: ['CG2'],
      lat: 1.35725,
      lon: 103.98851,
      lines: ['CGL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Cheng Lim',
      code: 'SW1',
      codes: ['SW1'],
      lat: 1.39622,
      lon: 103.89396,
      lines: ['SLRT'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Chinatown',
      code: 'NE4',
      codes: ['NE4', 'DT19'],
      lat: 1.28449,
      lon: 103.84346,
      lines: ['NEL', 'DTL'],
      exits: ['A', 'B', 'C', 'D', 'E'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Chinese Garden',
      code: 'EW25',
      codes: ['EW25'],
      lat: 1.34221,
      lon: 103.73263,
      lines: ['EWL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Choa Chu Kang',
      code: 'NS4',
      codes: ['NS4', 'BP1'],
      lat: 1.38485,
      lon: 103.74455,
      lines: ['NSL', 'BPL'],
      exits: ['A', 'B', 'C', 'D'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'City Hall',
      code: 'EW13',
      codes: ['EW13', 'NS25'],
      lat: 1.29298,
      lon: 103.85267,
      lines: ['EWL', 'NSL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Clarke Quay',
      code: 'NE5',
      codes: ['NE5'],
      lat: 1.28812,
      lon: 103.84641,
      lines: ['NEL'],
      exits: ['A', 'B', 'C'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Clementi',
      code: 'EW23',
      codes: ['EW23'],
      lat: 1.31495,
      lon: 103.76527,
      lines: ['EWL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Commonwealth',
      code: 'EW20',
      codes: ['EW20'],
      lat: 1.30235,
      lon: 103.79838,
      lines: ['EWL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Compassvale',
      code: 'SE1',
      codes: ['SE1'],
      lat: 1.39445,
      lon: 103.9006,
      lines: ['SLRT'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Coral Edge',
      code: 'PE3',
      codes: ['PE3'],
      lat: 1.39396,
      lon: 103.91251,
      lines: ['PLRT'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Cove',
      code: 'PE1',
      codes: ['PE1'],
      lat: 1.39939,
      lon: 103.90586,
      lines: ['PLRT'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Dakota',
      code: 'CC8',
      codes: ['CC8'],
      lat: 1.3083,
      lon: 103.88849,
      lines: ['CCL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Damai',
      code: 'PE7',
      codes: ['PE7'],
      lat: 1.40536,
      lon: 103.90846,
      lines: ['PLRT'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Dhoby Ghaut',
      code: 'NS24',
      codes: ['NS24', 'NE6', 'CC1'],
      lat: 1.29986,
      lon: 103.84558,
      lines: ['NSL', 'NEL', 'CCL'],
      exits: ['A', 'B', 'C', 'D', 'E', 'F'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Dover',
      code: 'EW22',
      codes: ['EW22'],
      lat: 1.3113,
      lon: 103.77879,
      lines: ['EWL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Downtown',
      code: 'DT17',
      codes: ['DT17'],
      lat: 1.27951,
      lon: 103.85279,
      lines: ['DTL'],
      exits: ['A', 'B', 'C', 'D', 'E', 'F'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Esplanade',
      code: 'CC3',
      codes: ['CC3'],
      lat: 1.29322,
      lon: 103.85579,
      lines: ['CCL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Eunos',
      code: 'EW7',
      codes: ['EW7'],
      lat: 1.31985,
      lon: 103.90349,
      lines: ['EWL'],
      exits: ['A', 'B', 'C'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Expo',
      code: 'CG1',
      codes: ['CG1', 'DT35'],
      lat: 1.33446,
      lon: 103.96142,
      lines: ['CGL', 'DTL'],
      exits: ['A', 'B', 'C', 'D', 'E', 'F', 'G'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Fajar',
      code: 'BP10',
      codes: ['BP10'],
      lat: 1.3845,
      lon: 103.77079,
      lines: ['BPL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Farmway',
      code: 'SW2',
      codes: ['SW2'],
      lat: 1.39714,
      lon: 103.88944,
      lines: ['SLRT'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Farrer Park',
      code: 'NE8',
      codes: ['NE8'],
      lat: 1.31227,
      lon: 103.85416,
      lines: ['NEL'],
      exits: ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Farrer Road',
      code: 'CC20',
      codes: ['CC20'],
      lat: 1.31759,
      lon: 103.80761,
      lines: ['CCL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Fernvale',
      code: 'SW5',
      codes: ['SW5'],
      lat: 1.39205,
      lon: 103.8762,
      lines: ['SLRT'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Fort Canning',
      code: 'DT20',
      codes: ['DT20'],
      lat: 1.29284,
      lon: 103.84445,
      lines: ['DTL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Gardens By The Bay',
      code: 'TE22',
      codes: ['TE22'],
      lat: 1.27923,
      lon: 103.86795,
      lines: ['TEL'],
      exits: ['1', '2', '3'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Geylang Bahru',
      code: 'DT24',
      codes: ['DT24'],
      lat: 1.32151,
      lon: 103.87196,
      lines: ['DTL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Great World',
      code: 'TE15',
      codes: ['TE15'],
      lat: 1.29419,
      lon: 103.83312,
      lines: ['TEL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Gul Circle',
      code: 'EW30',
      codes: ['EW30'],
      lat: 1.31943,
      lon: 103.66051,
      lines: ['EWL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Harbourfront',
      code: 'NE1',
      codes: ['NE1', 'CC29'],
      lat: 1.26557,
      lon: 103.8213,
      lines: ['NEL', 'CCL'],
      exits: ['A', 'B', 'C', 'D', 'E'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Havelock',
      code: 'TE16',
      codes: ['TE16'],
      lat: 1.28849,
      lon: 103.83362,
      lines: ['TEL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Haw Par Villa',
      code: 'CC25',
      codes: ['CC25'],
      lat: 1.28248,
      lon: 103.78187,
      lines: ['CCL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Hillview',
      code: 'DT3',
      codes: ['DT3'],
      lat: 1.36238,
      lon: 103.76741,
      lines: ['DTL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Holland Village',
      code: 'CC21',
      codes: ['CC21'],
      lat: 1.31177,
      lon: 103.79617,
      lines: ['CCL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Hougang',
      code: 'NE14',
      codes: ['NE14'],
      lat: 1.37114,
      lon: 103.89249,
      lines: ['NEL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Jalan Besar',
      code: 'DT22',
      codes: ['DT22'],
      lat: 1.30554,
      lon: 103.85565,
      lines: ['DTL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Jelapang',
      code: 'BP12',
      codes: ['BP12'],
      lat: 1.38669,
      lon: 103.76451,
      lines: ['BPL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Joo Koon',
      code: 'EW29',
      codes: ['EW29'],
      lat: 1.32775,
      lon: 103.67828,
      lines: ['EWL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Jurong East',
      code: 'EW24',
      codes: ['EW24', 'NS1'],
      lat: 1.33339,
      lon: 103.74213,
      lines: ['EWL', 'NSL'],
      exits: ['A', 'B', 'C', 'D'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Kadaloor',
      code: 'PE5',
      codes: ['PE5'],
      lat: 1.39961,
      lon: 103.91645,
      lines: ['PLRT'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Kaki Bukit',
      code: 'DT28',
      codes: ['DT28'],
      lat: 1.33507,
      lon: 103.90837,
      lines: ['DTL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Kallang',
      code: 'EW10',
      codes: ['EW10'],
      lat: 1.31142,
      lon: 103.87143,
      lines: ['EWL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Kangkar',
      code: 'SE4',
      codes: ['SE4'],
      lat: 1.38397,
      lon: 103.90224,
      lines: ['SLRT'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Katong Park',
      code: 'TE24',
      codes: ['TE24'],
      lat: 1.29796,
      lon: 103.88622,
      lines: ['TEL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Keat Hong',
      code: 'BP3',
      codes: ['BP3'],
      lat: 1.37864,
      lon: 103.74899,
      lines: ['BPL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Kembangan',
      code: 'EW6',
      codes: ['EW6'],
      lat: 1.3211,
      lon: 103.91291,
      lines: ['EWL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Kent Ridge',
      code: 'CC24',
      codes: ['CC24'],
      lat: 1.29345,
      lon: 103.78455,
      lines: ['CCL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Khatib',
      code: 'NS14',
      codes: ['NS14'],
      lat: 1.41757,
      lon: 103.83305,
      lines: ['NSL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'King Albert Park',
      code: 'DT6',
      codes: ['DT6'],
      lat: 1.33413,
      lon: 103.78279,
      lines: ['DTL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Kovan',
      code: 'NE13',
      codes: ['NE13'],
      lat: 1.36013,
      lon: 103.8851,
      lines: ['NEL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Kranji',
      code: 'NS7',
      codes: ['NS7'],
      lat: 1.42506,
      lon: 103.76174,
      lines: ['NSL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Kupang',
      code: 'SW3',
      codes: ['SW3'],
      lat: 1.39818,
      lon: 103.88143,
      lines: ['SLRT'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Labrador Park',
      code: 'CC27',
      codes: ['CC27'],
      lat: 1.27239,
      lon: 103.80307,
      lines: ['CCL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Lakeside',
      code: 'EW26',
      codes: ['EW26'],
      lat: 1.34439,
      lon: 103.72121,
      lines: ['EWL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Lavender',
      code: 'EW11',
      codes: ['EW11'],
      lat: 1.30728,
      lon: 103.86287,
      lines: ['EWL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Layar',
      code: 'SW6',
      codes: ['SW6'],
      lat: 1.39208,
      lon: 103.8801,
      lines: ['SLRT'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Lentor',
      code: 'TE5',
      codes: ['TE5'],
      lat: 1.38461,
      lon: 103.83675,
      lines: ['TEL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Little India',
      code: 'NE7',
      codes: ['NE7', 'DT12'],
      lat: 1.30703,
      lon: 103.8498,
      lines: ['NEL', 'DTL'],
      exits: ['A', 'B', 'C', 'D', 'E'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Lorong Chuan',
      code: 'CC14',
      codes: ['CC14'],
      lat: 1.35161,
      lon: 103.86409,
      lines: ['CCL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Macpherson',
      code: 'CC10',
      codes: ['CC10', 'DT26'],
      lat: 1.32601,
      lon: 103.88934,
      lines: ['CCL', 'DTL'],
      exits: ['A', 'B', 'C', 'D'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Marina Bay',
      code: 'NS27',
      codes: ['NS27', 'CE2', 'TE20'],
      lat: 1.27606,
      lon: 103.85525,
      lines: ['NSL', 'CEL', 'TEL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Marina South',
      code: 'TE21',
      codes: ['TE21'],
      lat: 1.27431,
      lon: 103.86289,
      lines: ['TEL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Marina South Pier',
      code: 'NS28',
      codes: ['NS28'],
      lat: 1.27145,
      lon: 103.86282,
      lines: ['NSL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Marine Parade',
      code: 'TE26',
      codes: ['TE26'],
      lat: 1.30371,
      lon: 103.90707,
      lines: ['TEL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Marine Terrace',
      code: 'TE27',
      codes: ['TE27'],
      lat: 1.3066,
      lon: 103.91506,
      lines: ['TEL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Marsiling',
      code: 'NS8',
      codes: ['NS8'],
      lat: 1.43257,
      lon: 103.77406,
      lines: ['NSL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Marymount',
      code: 'CC16',
      codes: ['CC16'],
      lat: 1.34864,
      lon: 103.83948,
      lines: ['CCL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Mattar',
      code: 'DT25',
      codes: ['DT25'],
      lat: 1.32686,
      lon: 103.88326,
      lines: ['DTL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Maxwell',
      code: 'TE18',
      codes: ['TE18'],
      lat: 1.28062,
      lon: 103.84388,
      lines: ['TEL'],
      exits: ['1', '2', '3'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Mayflower',
      code: 'TE6',
      codes: ['TE6'],
      lat: 1.37233,
      lon: 103.8369,
      lines: ['TEL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Meridian',
      code: 'PE2',
      codes: ['PE2'],
      lat: 1.39683,
      lon: 103.90905,
      lines: ['PLRT'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Mountbatten',
      code: 'CC7',
      codes: ['CC7'],
      lat: 1.30625,
      lon: 103.88249,
      lines: ['CCL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Napier',
      code: 'TE12',
      codes: ['TE12'],
      lat: 1.30676,
      lon: 103.81931,
      lines: ['TEL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Newton',
      code: 'NS21',
      codes: ['NS21', 'DT11'],
      lat: 1.31229,
      lon: 103.83801,
      lines: ['NSL', 'DTL'],
      exits: ['A', 'B', 'C'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Nibong',
      code: 'PW5',
      codes: ['PW5'],
      lat: 1.41181,
      lon: 103.90031,
      lines: ['PLRT'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Nicoll Highway',
      code: 'CC5',
      codes: ['CC5'],
      lat: 1.29982,
      lon: 103.86363,
      lines: ['CCL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Novena',
      code: 'NS20',
      codes: ['NS20'],
      lat: 1.32029,
      lon: 103.84368,
      lines: ['NSL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Oasis',
      code: 'PE6',
      codes: ['PE6'],
      lat: 1.4024,
      lon: 103.91259,
      lines: ['PLRT'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Orchard',
      code: 'NS22',
      codes: ['NS22', 'TE14'],
      lat: 1.30303,
      lon: 103.83175,
      lines: ['NSL', 'TEL'],
      exits: ['1', '2', '3', '4', 'A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Orchard Boulevard',
      code: 'TE13',
      codes: ['TE13'],
      lat: 1.30319,
      lon: 103.82387,
      lines: ['TEL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Outram Park',
      code: 'EW16',
      codes: ['EW16', 'NE3', 'TE17'],
      lat: 1.28138,
      lon: 103.8391,
      lines: ['EWL', 'NEL', 'TEL'],
      exits: ['1', '2', '3', '4', '5', '6', '7', '8'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Pasir Panjang',
      code: 'CC26',
      codes: ['CC26'],
      lat: 1.2762,
      lon: 103.79126,
      lines: ['CCL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Pasir Ris',
      code: 'EW1',
      codes: ['EW1'],
      lat: 1.37314,
      lon: 103.94936,
      lines: ['EWL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Paya Lebar',
      code: 'EW8',
      codes: ['EW8', 'CC9'],
      lat: 1.31811,
      lon: 103.89315,
      lines: ['EWL', 'CCL'],
      exits: ['A', 'B', 'C', 'D', 'E', 'F'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Pending',
      code: 'BP8',
      codes: ['BP8'],
      lat: 1.37612,
      lon: 103.77125,
      lines: ['BPL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Petir',
      code: 'BP7',
      codes: ['BP7'],
      lat: 1.37774,
      lon: 103.76666,
      lines: ['BPL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Phoenix',
      code: 'BP5',
      codes: ['BP5'],
      lat: 1.37859,
      lon: 103.75804,
      lines: ['BPL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Pioneer',
      code: 'EW28',
      codes: ['EW28'],
      lat: 1.33759,
      lon: 103.69743,
      lines: ['EWL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Potong Pasir',
      code: 'NE10',
      codes: ['NE10'],
      lat: 1.33139,
      lon: 103.86904,
      lines: ['NEL'],
      exits: ['A', 'B', 'C'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Promenade',
      code: 'CC4',
      codes: ['CC4', 'DT15'],
      lat: 1.29322,
      lon: 103.86073,
      lines: ['CCL', 'DTL'],
      exits: ['A', 'B', 'C'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Punggol',
      code: 'NE17',
      codes: ['NE17', 'PTC'],
      lat: 1.40523,
      lon: 103.90245,
      lines: ['NEL', 'PLRT'],
      exits: ['A', 'B', 'C', 'D'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Punggol Coast',
      code: 'NE18',
      codes: ['NE18'],
      lat: 1.41497,
      lon: 103.91012,
      lines: ['NEL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Punggol Point',
      code: 'PW3',
      codes: ['PW3'],
      lat: 1.41695,
      lon: 103.90649,
      lines: ['PLRT'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Queenstown',
      code: 'EW19',
      codes: ['EW19'],
      lat: 1.29451,
      lon: 103.80607,
      lines: ['EWL'],
      exits: ['A', 'B', 'C', 'D'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Raffles Place',
      code: 'EW14',
      codes: ['EW14', 'NS26'],
      lat: 1.28346,
      lon: 103.85139,
      lines: ['EWL', 'NSL'],
      exits: ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Ranggung',
      code: 'SE5',
      codes: ['SE5'],
      lat: 1.38387,
      lon: 103.89752,
      lines: ['SLRT'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Redhill',
      code: 'EW18',
      codes: ['EW18'],
      lat: 1.28963,
      lon: 103.81684,
      lines: ['EWL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Renjong',
      code: 'SW8',
      codes: ['SW8'],
      lat: 1.38672,
      lon: 103.89048,
      lines: ['SLRT'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Riviera',
      code: 'PE4',
      codes: ['PE4'],
      lat: 1.3946,
      lon: 103.91618,
      lines: ['PLRT'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Rochor',
      code: 'DT13',
      codes: ['DT13'],
      lat: 1.30408,
      lon: 103.85284,
      lines: ['DTL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Rumbia',
      code: 'SE2',
      codes: ['SE2'],
      lat: 1.39152,
      lon: 103.90592,
      lines: ['SLRT'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Sam Kee',
      code: 'PW1',
      codes: ['PW1'],
      lat: 1.40972,
      lon: 103.90488,
      lines: ['PLRT'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Samudera',
      code: 'PW4',
      codes: ['PW4'],
      lat: 1.41587,
      lon: 103.90212,
      lines: ['PLRT'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Segar',
      code: 'BP11',
      codes: ['BP11'],
      lat: 1.38772,
      lon: 103.76968,
      lines: ['BPL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Sembawang',
      code: 'NS11',
      codes: ['NS11'],
      lat: 1.44916,
      lon: 103.82053,
      lines: ['NSL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Sengkang',
      code: 'NE16',
      codes: ['NE16', 'STC'],
      lat: 1.39136,
      lon: 103.89533,
      lines: ['NEL', 'SLRT'],
      exits: ['A', 'B', 'C', 'D'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Senja',
      code: 'BP13',
      codes: ['BP13'],
      lat: 1.38268,
      lon: 103.76238,
      lines: ['BPL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Serangoon',
      code: 'NE12',
      codes: ['NE12', 'CC13'],
      lat: 1.3504,
      lon: 103.87266,
      lines: ['NEL', 'CCL'],
      exits: ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Shenton Way',
      code: 'TE19',
      codes: ['TE19'],
      lat: 1.27754,
      lon: 103.85077,
      lines: ['TEL'],
      exits: ['1', '2', '3', '4', '5', '6'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Siglap',
      code: 'TE28',
      codes: ['TE28'],
      lat: 1.30959,
      lon: 103.93002,
      lines: ['TEL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Simei',
      code: 'EW3',
      codes: ['EW3'],
      lat: 1.34331,
      lon: 103.95325,
      lines: ['EWL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Sixth Avenue',
      code: 'DT7',
      codes: ['DT7'],
      lat: 1.33073,
      lon: 103.79721,
      lines: ['DTL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Somerset',
      code: 'NS23',
      codes: ['NS23'],
      lat: 1.30026,
      lon: 103.83903,
      lines: ['NSL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Soo Teck',
      code: 'PW7',
      codes: ['PW7'],
      lat: 1.40514,
      lon: 103.89723,
      lines: ['PLRT'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'South View',
      code: 'BP2',
      codes: ['BP2'],
      lat: 1.38028,
      lon: 103.7453,
      lines: ['BPL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Springleaf',
      code: 'TE4',
      codes: ['TE4'],
      lat: 1.39812,
      lon: 103.81787,
      lines: ['TEL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Stadium',
      code: 'CC6',
      codes: ['CC6'],
      lat: 1.30294,
      lon: 103.87531,
      lines: ['CCL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Stevens',
      code: 'DT10',
      codes: ['DT10', 'TE11'],
      lat: 1.31998,
      lon: 103.82576,
      lines: ['DTL', 'TEL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Sumang',
      code: 'PW6',
      codes: ['PW6'],
      lat: 1.40836,
      lon: 103.89852,
      lines: ['PLRT'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Tai Seng',
      code: 'CC11',
      codes: ['CC11'],
      lat: 1.33537,
      lon: 103.88807,
      lines: ['CCL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Tampines',
      code: 'EW2',
      codes: ['EW2', 'DT32'],
      lat: 1.35511,
      lon: 103.94298,
      lines: ['EWL', 'DTL'],
      exits: ['A', 'B', 'C', 'D', 'E', 'F', 'G'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Tampines East',
      code: 'DT33',
      codes: ['DT33'],
      lat: 1.35621,
      lon: 103.95477,
      lines: ['DTL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Tampines West',
      code: 'DT31',
      codes: ['DT31'],
      lat: 1.3456,
      lon: 103.93844,
      lines: ['DTL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Tan Kah Kee',
      code: 'DT8',
      codes: ['DT8'],
      lat: 1.3259,
      lon: 103.80726,
      lines: ['DTL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Tanah Merah',
      code: 'EW4',
      codes: ['EW4'],
      lat: 1.32731,
      lon: 103.94684,
      lines: ['EWL', 'CGL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Tanjong Katong',
      code: 'TE25',
      codes: ['TE25'],
      lat: 1.29959,
      lon: 103.89738,
      lines: ['TEL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Tanjong Pagar',
      code: 'EW15',
      codes: ['EW15'],
      lat: 1.27683,
      lon: 103.84661,
      lines: ['EWL'],
      exits: ['A', 'B', 'C', 'D', 'E', 'F', 'G'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Tanjong Rhu',
      code: 'TE23',
      codes: ['TE23'],
      lat: 1.29734,
      lon: 103.87346,
      lines: ['TEL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Teck Lee',
      code: 'PW2',
      codes: ['PW2'],
      lat: 1.41283,
      lon: 103.90659,
      lines: ['PLRT'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Teck Whye',
      code: 'BP4',
      codes: ['BP4'],
      lat: 1.37658,
      lon: 103.75374,
      lines: ['BPL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Telok Ayer',
      code: 'DT18',
      codes: ['DT18'],
      lat: 1.28234,
      lon: 103.84833,
      lines: ['DTL'],
      exits: ['A', 'B', 'C'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Telok Blangah',
      code: 'CC28',
      codes: ['CC28'],
      lat: 1.2706,
      lon: 103.80979,
      lines: ['CCL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Ten Mile Junction',
      code: 'BP14',
      codes: ['BP14'],
      lat: 1.37996,
      lon: 103.76024,
      lines: ['BPL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Thanggam',
      code: 'SW4',
      codes: ['SW4'],
      lat: 1.39738,
      lon: 103.87566,
      lines: ['SLRT'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Tiong Bahru',
      code: 'EW17',
      codes: ['EW17'],
      lat: 1.2862,
      lon: 103.82722,
      lines: ['EWL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Toa Payoh',
      code: 'NS19',
      codes: ['NS19'],
      lat: 1.33281,
      lon: 103.84712,
      lines: ['NSL'],
      exits: ['A', 'B', 'C', 'D'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Tongkang',
      code: 'SW7',
      codes: ['SW7'],
      lat: 1.3893,
      lon: 103.88598,
      lines: ['SLRT'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Tuas Crescent',
      code: 'EW31',
      codes: ['EW31'],
      lat: 1.32112,
      lon: 103.64899,
      lines: ['EWL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Tuas Link',
      code: 'EW33',
      codes: ['EW33'],
      lat: 1.34098,
      lon: 103.63698,
      lines: ['EWL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Tuas West Road',
      code: 'EW32',
      codes: ['EW32'],
      lat: 1.33006,
      lon: 103.63954,
      lines: ['EWL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Ubi',
      code: 'DT27',
      codes: ['DT27'],
      lat: 1.32996,
      lon: 103.89936,
      lines: ['DTL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Upper Changi',
      code: 'DT34',
      codes: ['DT34'],
      lat: 1.34184,
      lon: 103.96146,
      lines: ['DTL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Upper Thomson',
      code: 'TE8',
      codes: ['TE8'],
      lat: 1.35462,
      lon: 103.83277,
      lines: ['TEL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Woodlands',
      code: 'NS9',
      codes: ['NS9', 'TE2'],
      lat: 1.43688,
      lon: 103.78608,
      lines: ['NSL', 'TEL'],
      exits: ['1', '2', '3', '4', '5', '6', '7'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Woodlands North',
      code: 'TE1',
      codes: ['TE1'],
      lat: 1.44829,
      lon: 103.78571,
      lines: ['TEL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Woodlands South',
      code: 'TE3',
      codes: ['TE3'],
      lat: 1.42673,
      lon: 103.79378,
      lines: ['TEL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Woodleigh',
      code: 'NE11',
      codes: ['NE11'],
      lat: 1.33904,
      lon: 103.87075,
      lines: ['NEL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Yew Tee',
      code: 'NS5',
      codes: ['NS5'],
      lat: 1.39746,
      lon: 103.74745,
      lines: ['NSL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Yio Chu Kang',
      code: 'NS15',
      codes: ['NS15'],
      lat: 1.38182,
      lon: 103.84472,
      lines: ['NSL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Yishun',
      code: 'NS13',
      codes: ['NS13'],
      lat: 1.42941,
      lon: 103.83503,
      lines: ['NSL'],
      exits: ['A', 'B', 'C', 'D'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'one-north',
      code: 'CC23',
      codes: ['CC23'],
      lat: 1.29965,
      lon: 103.78739,
      lines: ['CCL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
  ];

  /// Finds a station by its exact code (e.g. 'EW2', 'EW14', 'DT32')
  static Station? findStationByCode(String code) {
    final target = code.trim().toUpperCase();
    for (final s in allStations) {
      if (s.matchesCode(target)) return s;
    }
    return null;
  }

  /// Finds a station by its name (e.g. 'Tampines', 'Bedok', 'Raffles Place')
  static Station? findStationByName(String name) {
    final target = name.trim().toLowerCase();
    for (final s in allStations) {
      if (s.name.toLowerCase() == target) return s;
    }
    return null;
  }

  /// Returns all stations on a given line code
  static List<Station> findStationsOnLine(String lineCode) {
    final upper = normalize(lineCode);
    return allStations.where((s) => s.hasLine(upper)).toList();
  }
}
