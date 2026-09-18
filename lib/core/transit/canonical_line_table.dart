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

  // ---------------------------------------------------------------------------
  // Pre-mapped Singapore MRT / LRT Stations
  // ---------------------------------------------------------------------------
  static final List<Station> allStations = [
    // Rachel's commute corridor (East-West Line)
    const Station(
      name: 'Tampines',
      code: 'EW2',
      codes: ['EW2', 'DT32'],
      lat: 1.3533,
      lon: 103.9452,
      lines: ['EWL', 'DTL'],
      exits: ['A', 'B', 'C', 'D', 'E', 'F', 'G'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Simei',
      code: 'EW3',
      lat: 1.3432,
      lon: 103.9533,
      lines: ['EWL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Tanah Merah',
      code: 'EW4',
      lat: 1.3273,
      lon: 103.9463,
      lines: ['EWL', 'CGL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    // Mdm Lim's origin (Bedok)
    const Station(
      name: 'Bedok',
      code: 'EW5',
      lat: 1.3240,
      lon: 103.9300,
      lines: ['EWL'],
      exits: ['A', 'B', 'C'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Kembangan',
      code: 'EW6',
      lat: 1.3210,
      lon: 103.9129,
      lines: ['EWL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Eunos',
      code: 'EW7',
      lat: 1.3197,
      lon: 103.9031,
      lines: ['EWL'],
      exits: ['A', 'B', 'C'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Paya Lebar',
      code: 'EW8',
      codes: ['EW8', 'CC9'],
      lat: 1.3181,
      lon: 103.8931,
      lines: ['EWL', 'CCL'],
      exits: ['A', 'B', 'C', 'D', 'E', 'F'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Aljunied',
      code: 'EW9',
      lat: 1.3164,
      lon: 103.8829,
      lines: ['EWL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Kallang',
      code: 'EW10',
      lat: 1.3115,
      lon: 103.8714,
      lines: ['EWL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Lavender',
      code: 'EW11',
      lat: 1.3074,
      lon: 103.8596,
      lines: ['EWL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Bugis',
      code: 'EW12',
      codes: ['EW12', 'DT14'],
      lat: 1.3005,
      lon: 103.8558,
      lines: ['EWL', 'DTL'],
      exits: ['A', 'B', 'C', 'D'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'City Hall',
      code: 'EW13',
      codes: ['EW13', 'NS25'],
      lat: 1.2931,
      lon: 103.8522,
      lines: ['EWL', 'NSL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    // Rachel's destination (Raffles Place)
    const Station(
      name: 'Raffles Place',
      code: 'EW14',
      codes: ['EW14', 'NS26'],
      lat: 1.2830,
      lon: 103.8513,
      lines: ['EWL', 'NSL'],
      exits: ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Tanjong Pagar',
      code: 'EW15',
      lat: 1.2764,
      lon: 103.8458,
      lines: ['EWL'],
      exits: ['A', 'B', 'C', 'D', 'E', 'F', 'G'],
      groundLevel: GroundLevel.underground,
    ),
    // Mdm Lim's transit station for Singapore General Hospital (SGH)
    const Station(
      name: 'Outram Park',
      code: 'EW16',
      codes: ['EW16', 'NE3', 'TE17'],
      lat: 1.2803,
      lon: 103.8395,
      lines: ['EWL', 'NEL', 'TEL'],
      exits: ['1', '2', '3', '4', '5', '6', '7', '8'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Tiong Bahru',
      code: 'EW17',
      lat: 1.2861,
      lon: 103.8269,
      lines: ['EWL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Redhill',
      code: 'EW18',
      lat: 1.2896,
      lon: 103.8168,
      lines: ['EWL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Queenstown',
      code: 'EW19',
      lat: 1.2945,
      lon: 103.8060,
      lines: ['EWL'],
      exits: ['A', 'B', 'C', 'D'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Buona Vista',
      code: 'EW21',
      codes: ['EW21', 'CC22'],
      lat: 1.3073,
      lon: 103.7900,
      lines: ['EWL', 'CCL'],
      exits: ['A', 'B', 'C', 'D'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Clementi',
      code: 'EW23',
      lat: 1.3151,
      lon: 103.7652,
      lines: ['EWL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Jurong East',
      code: 'EW24',
      codes: ['EW24', 'NS1'],
      lat: 1.3332,
      lon: 103.7423,
      lines: ['EWL', 'NSL'],
      exits: ['A', 'B', 'C', 'D'],
      groundLevel: GroundLevel.aboveGround,
    ),
    // Changi Airport Branch
    const Station(
      name: 'Expo',
      code: 'CG1',
      codes: ['CG1', 'DT35'],
      lat: 1.3353,
      lon: 103.9616,
      lines: ['CGL', 'DTL'],
      exits: ['A', 'B', 'C', 'D', 'E', 'F', 'G'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Changi Airport',
      code: 'CG2',
      lat: 1.3574,
      lon: 103.9885,
      lines: ['CGL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    // North-South Line & Circle Line Connections
    const Station(
      name: 'Bishan',
      code: 'NS17',
      codes: ['NS17', 'CC15'],
      lat: 1.3508,
      lon: 103.8481,
      lines: ['NSL', 'CCL'],
      exits: ['A', 'B', 'C', 'D', 'E'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Dhoby Ghaut',
      code: 'NS24',
      codes: ['NS24', 'NE6', 'CC1'],
      lat: 1.2989,
      lon: 103.8459,
      lines: ['NSL', 'NEL', 'CCL'],
      exits: ['A', 'B', 'C', 'D', 'E', 'F'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Marina Bay',
      code: 'NS27',
      codes: ['NS27', 'CE2', 'TE20'],
      lat: 1.2764,
      lon: 103.8546,
      lines: ['NSL', 'CEL', 'TEL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Bayfront',
      code: 'CE1',
      codes: ['CE1', 'DT16'],
      lat: 1.2818,
      lon: 103.8591,
      lines: ['CEL', 'DTL'],
      exits: ['A', 'B', 'C', 'D', 'E'],
      groundLevel: GroundLevel.underground,
    ),
    // North East Line Connections
    const Station(
      name: 'HarbourFront',
      code: 'NE1',
      codes: ['NE1', 'CC29'],
      lat: 1.2654,
      lon: 103.8222,
      lines: ['NEL', 'CCL'],
      exits: ['A', 'B', 'C', 'D', 'E'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Chinatown',
      code: 'NE4',
      codes: ['NE4', 'DT19'],
      lat: 1.2845,
      lon: 103.8440,
      lines: ['NEL', 'DTL'],
      exits: ['A', 'B', 'C', 'D', 'E'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Serangoon',
      code: 'NE12',
      codes: ['NE12', 'CC13'],
      lat: 1.3497,
      lon: 103.8737,
      lines: ['NEL', 'CCL'],
      exits: ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Sengkang',
      code: 'NE16',
      codes: ['NE16', 'STC'],
      lat: 1.3917,
      lon: 103.8955,
      lines: ['NEL', 'SLRT'],
      exits: ['A', 'B', 'C', 'D'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Punggol',
      code: 'NE17',
      codes: ['NE17', 'PTC'],
      lat: 1.4049,
      lon: 103.9023,
      lines: ['NEL', 'PLRT'],
      exits: ['A', 'B', 'C', 'D'],
      groundLevel: GroundLevel.aboveGround,
    ),
    // North-South Line extensions
    const Station(
      name: 'Choa Chu Kang',
      code: 'NS4',
      codes: ['NS4', 'BP1'],
      lat: 1.3854,
      lon: 103.7444,
      lines: ['NSL', 'BPL'],
      exits: ['A', 'B', 'C', 'D'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Woodlands',
      code: 'NS9',
      codes: ['NS9', 'TE2'],
      lat: 1.4361,
      lon: 103.7865,
      lines: ['NSL', 'TEL'],
      exits: ['1', '2', '3', '4', '5', '6', '7'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Yishun',
      code: 'NS13',
      lat: 1.4294,
      lon: 103.8350,
      lines: ['NSL'],
      exits: ['A', 'B', 'C', 'D'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Ang Mo Kio',
      code: 'NS16',
      lat: 1.3699,
      lon: 103.8496,
      lines: ['NSL'],
      exits: ['A', 'B', 'C', 'D'],
      groundLevel: GroundLevel.aboveGround,
    ),
    const Station(
      name: 'Toa Payoh',
      code: 'NS19',
      lat: 1.3327,
      lon: 103.8475,
      lines: ['NSL'],
      exits: ['A', 'B', 'C', 'D'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Novena',
      code: 'NS20',
      lat: 1.3204,
      lon: 103.8438,
      lines: ['NSL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Newton',
      code: 'NS21',
      codes: ['NS21', 'DT11'],
      lat: 1.3129,
      lon: 103.8380,
      lines: ['NSL', 'DTL'],
      exits: ['A', 'B', 'C'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Orchard',
      code: 'NS22',
      codes: ['NS22', 'TE14'],
      lat: 1.3040,
      lon: 103.8318,
      lines: ['NSL', 'TEL'],
      exits: ['1', '2', '3', '4', 'A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Somerset',
      code: 'NS23',
      lat: 1.3003,
      lon: 103.8390,
      lines: ['NSL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    // North East Line intermediate stations
    const Station(
      name: 'Clarke Quay',
      code: 'NE5',
      lat: 1.2884,
      lon: 103.8466,
      lines: ['NEL'],
      exits: ['A', 'B', 'C'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Little India',
      code: 'NE7',
      codes: ['NE7', 'DT12'],
      lat: 1.3068,
      lon: 103.8492,
      lines: ['NEL', 'DTL'],
      exits: ['A', 'B', 'C', 'D', 'E'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Farrer Park',
      code: 'NE8',
      lat: 1.3123,
      lon: 103.8540,
      lines: ['NEL'],
      exits: ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Boon Keng',
      code: 'NE9',
      lat: 1.3194,
      lon: 103.8617,
      lines: ['NEL'],
      exits: ['A', 'B', 'C'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Potong Pasir',
      code: 'NE10',
      lat: 1.3314,
      lon: 103.8691,
      lines: ['NEL'],
      exits: ['A', 'B', 'C'],
      groundLevel: GroundLevel.underground,
    ),
    // Downtown Line & Circle Line connectors
    const Station(
      name: 'Botanic Gardens',
      code: 'CC19',
      codes: ['CC19', 'DT9'],
      lat: 1.3223,
      lon: 103.8153,
      lines: ['CCL', 'DTL'],
      exits: ['A', 'B'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Promenade',
      code: 'CC4',
      codes: ['CC4', 'DT15'],
      lat: 1.2940,
      lon: 103.8603,
      lines: ['CCL', 'DTL'],
      exits: ['A', 'B', 'C'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Downtown',
      code: 'DT17',
      lat: 1.2794,
      lon: 103.8528,
      lines: ['DTL'],
      exits: ['A', 'B', 'C', 'D', 'E', 'F'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Telok Ayer',
      code: 'DT18',
      lat: 1.2822,
      lon: 103.8486,
      lines: ['DTL'],
      exits: ['A', 'B', 'C'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'MacPherson',
      code: 'CC10',
      codes: ['CC10', 'DT26'],
      lat: 1.3262,
      lon: 103.8899,
      lines: ['CCL', 'DTL'],
      exits: ['A', 'B', 'C', 'D'],
      groundLevel: GroundLevel.underground,
    ),
    // Thomson-East Coast Line
    const Station(
      name: 'Maxwell',
      code: 'TE18',
      lat: 1.2806,
      lon: 103.8440,
      lines: ['TEL'],
      exits: ['1', '2', '3'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Shenton Way',
      code: 'TE19',
      lat: 1.2778,
      lon: 103.8505,
      lines: ['TEL'],
      exits: ['1', '2', '3', '4', '5', '6'],
      groundLevel: GroundLevel.underground,
    ),
    const Station(
      name: 'Gardens by the Bay',
      code: 'TE22',
      lat: 1.2783,
      lon: 103.8672,
      lines: ['TEL'],
      exits: ['1', '2', '3'],
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
