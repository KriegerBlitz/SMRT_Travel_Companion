import 'package:flutter/material.dart';

/// Official MRT/LRT lines with canonical codes, display names, and standard LTA brand colors.
enum MRTLine {
  ewl('EWL', 'East-West Line', Color(0xFF009645), 'Green'),
  nsl('NSL', 'North-South Line', Color(0xFFD42E12), 'Red'),
  nel('NEL', 'North-East Line', Color(0xFF8F4199), 'Purple'),
  ccl('CCL', 'Circle Line', Color(0xFFFA9E0D), 'Orange'),
  dtl('DTL', 'Downtown Line', Color(0xFF005EC4), 'Blue'),
  tel('TEL', 'Thomson-East Coast Line', Color(0xFF9D5B25), 'Brown'),
  bplrt('BPLRT', 'Bukit Panjang LRT', Color(0xFF748477), 'Grey'),
  slrt('SLRT', 'Sengkang LRT', Color(0xFF748477), 'Grey'),
  plrt('PLRT', 'Punggol LRT', Color(0xFF748477), 'Grey');

  final String code;
  final String displayName;
  final Color color;
  final String colorName;

  const MRTLine(this.code, this.displayName, this.color, this.colorName);

  static MRTLine? fromCode(String code) {
    final reconciled = CanonicalLineCodes.reconcileLineCode(code);
    for (final line in MRTLine.values) {
      if (line.code.toUpperCase() == reconciled.toUpperCase()) {
        return line;
      }
    }
    return null;
  }
}

/// Metadata for an MRT / LRT station.
class StationInfo {
  final String code; // Primary station code e.g. "EW2"
  final String name; // e.g. "Tampines"
  final MRTLine primaryLine;
  final List<String> allCodes; // e.g. ["EW2", "DT32"]
  final double lat;
  final double lng;
  final bool isInterchange;

  const StationInfo({
    required this.code,
    required this.name,
    required this.primaryLine,
    required this.allCodes,
    required this.lat,
    required this.lng,
    this.isInterchange = false,
  });

  String get codesDisplay => allCodes.join(' / ');
}

/// The single source of truth for line codes and station data across Singapore's rail network.
/// Reconciles cross-endpoint discrepancies found in LTA DataMall (e.g. STL vs SLRT, CEL vs CCL).
class CanonicalLineCodes {
  /// Raw alias mapping from various LTA endpoints (TrainServiceAlerts, PCDRealTime, PCDForecast)
  /// to canonical MRTLine codes.
  static const Map<String, String> _codeReconciliationMap = {
    // Sengkang LRT variants
    'STL': 'SLRT',
    'SK': 'SLRT',
    'SE': 'SLRT',
    'SW': 'SLRT',
    'SL': 'SLRT',

    // Punggol LRT variants
    'PEL': 'PLRT',
    'PTL': 'PLRT',
    'PG': 'PLRT',
    'PE': 'PLRT',
    'PW': 'PLRT',
    'PL': 'PLRT',

    // Bukit Panjang LRT variants
    'BPL': 'BPLRT',
    'BP': 'BPLRT',
    'BL': 'BPLRT',

    // Circle Line & Circle Extension variants
    'CEL': 'CCL',
    'CC': 'CCL',
    'CE': 'CCL',

    // Changi Airport Branch & East-West Line variants
    'CGL': 'EWL',
    'CG': 'EWL',
    'EW': 'EWL',

    // North-South Line
    'NS': 'NSL',

    // North-East Line
    'NE': 'NEL',

    // Downtown Line
    'DT': 'DTL',

    // Thomson-East Coast Line
    'TE': 'TEL',
  };

  /// Normalizes any raw endpoint line code (e.g. "STL", "CEL", "CGL", "BP") into the canonical code.
  static String reconcileLineCode(String rawCode) {
    final cleaned = rawCode.trim().toUpperCase();
    if (cleaned.isEmpty) return 'UNKNOWN';

    // Direct alias hit
    if (_codeReconciliationMap.containsKey(cleaned)) {
      return _codeReconciliationMap[cleaned]!;
    }

    // Direct match with valid enum codes
    for (final line in MRTLine.values) {
      if (line.code == cleaned) {
        return line.code;
      }
    }

    // Prefix check for composite codes (e.g. "EWL-CGL" -> "EWL")
    for (final entry in _codeReconciliationMap.entries) {
      if (cleaned.startsWith(entry.key)) {
        return entry.value;
      }
    }

    return cleaned;
  }

  /// Master list of key MRT/LRT stations with accurate coordinates and interchange associations.
  static const List<StationInfo> stations = [
    // East-West Line (EWL)
    StationInfo(
      code: 'EW1',
      name: 'Pasir Ris',
      primaryLine: MRTLine.ewl,
      allCodes: ['EW1'],
      lat: 1.3730,
      lng: 103.9493,
    ),
    StationInfo(
      code: 'EW2',
      name: 'Tampines',
      primaryLine: MRTLine.ewl,
      allCodes: ['EW2', 'DT32'],
      lat: 1.3533,
      lng: 103.9452,
      isInterchange: true,
    ),
    StationInfo(
      code: 'EW3',
      name: 'Simei',
      primaryLine: MRTLine.ewl,
      allCodes: ['EW3'],
      lat: 1.3432,
      lng: 103.9533,
    ),
    StationInfo(
      code: 'EW4',
      name: 'Tanah Merah',
      primaryLine: MRTLine.ewl,
      allCodes: ['EW4', 'CG'],
      lat: 1.3273,
      lng: 103.9464,
      isInterchange: true,
    ),
    StationInfo(
      code: 'EW5',
      name: 'Bedok',
      primaryLine: MRTLine.ewl,
      allCodes: ['EW5'],
      lat: 1.3240,
      lng: 103.9300,
    ),
    StationInfo(
      code: 'EW6',
      name: 'Kembangan',
      primaryLine: MRTLine.ewl,
      allCodes: ['EW6'],
      lat: 1.3210,
      lng: 103.9129,
    ),
    StationInfo(
      code: 'EW7',
      name: 'Eunos',
      primaryLine: MRTLine.ewl,
      allCodes: ['EW7'],
      lat: 1.3197,
      lng: 103.9030,
    ),
    StationInfo(
      code: 'EW8',
      name: 'Paya Lebar',
      primaryLine: MRTLine.ewl,
      allCodes: ['EW8', 'CC9'],
      lat: 1.3181,
      lng: 103.8931,
      isInterchange: true,
    ),
    StationInfo(
      code: 'EW9',
      name: 'Aljunied',
      primaryLine: MRTLine.ewl,
      allCodes: ['EW9'],
      lat: 1.3164,
      lng: 103.8829,
    ),
    StationInfo(
      code: 'EW10',
      name: 'Kallang',
      primaryLine: MRTLine.ewl,
      allCodes: ['EW10'],
      lat: 1.3115,
      lng: 103.8714,
    ),
    StationInfo(
      code: 'EW11',
      name: 'Lavender',
      primaryLine: MRTLine.ewl,
      allCodes: ['EW11'],
      lat: 1.3074,
      lng: 103.8628,
    ),
    StationInfo(
      code: 'EW12',
      name: 'Bugis',
      primaryLine: MRTLine.ewl,
      allCodes: ['EW12', 'DT14'],
      lat: 1.3005,
      lng: 103.8560,
      isInterchange: true,
    ),
    StationInfo(
      code: 'EW13',
      name: 'City Hall',
      primaryLine: MRTLine.ewl,
      allCodes: ['EW13', 'NS25'],
      lat: 1.2931,
      lng: 103.8521,
      isInterchange: true,
    ),
    StationInfo(
      code: 'EW14',
      name: 'Raffles Place',
      primaryLine: MRTLine.ewl,
      allCodes: ['EW14', 'NS26'],
      lat: 1.2839,
      lng: 103.8515,
      isInterchange: true,
    ),
    StationInfo(
      code: 'EW15',
      name: 'Tanjong Pagar',
      primaryLine: MRTLine.ewl,
      allCodes: ['EW15'],
      lat: 1.2764,
      lng: 103.8457,
    ),
    StationInfo(
      code: 'EW16',
      name: 'Outram Park',
      primaryLine: MRTLine.ewl,
      allCodes: ['EW16', 'NE3', 'TE17'],
      lat: 1.2803,
      lng: 103.8395,
      isInterchange: true,
    ),
    StationInfo(
      code: 'EW17',
      name: 'Tiong Bahru',
      primaryLine: MRTLine.ewl,
      allCodes: ['EW17'],
      lat: 1.2863,
      lng: 103.8270,
    ),
    StationInfo(
      code: 'EW18',
      name: 'Redhill',
      primaryLine: MRTLine.ewl,
      allCodes: ['EW18'],
      lat: 1.2896,
      lng: 103.8168,
    ),
    StationInfo(
      code: 'EW19',
      name: 'Queenstown',
      primaryLine: MRTLine.ewl,
      allCodes: ['EW19'],
      lat: 1.2944,
      lng: 103.8059,
    ),
    StationInfo(
      code: 'EW20',
      name: 'Commonwealth',
      primaryLine: MRTLine.ewl,
      allCodes: ['EW20'],
      lat: 1.3025,
      lng: 103.7983,
    ),
    StationInfo(
      code: 'EW21',
      name: 'Buona Vista',
      primaryLine: MRTLine.ewl,
      allCodes: ['EW21', 'CC22'],
      lat: 1.3073,
      lng: 103.7900,
      isInterchange: true,
    ),
    StationInfo(
      code: 'EW23',
      name: 'Clementi',
      primaryLine: MRTLine.ewl,
      allCodes: ['EW23'],
      lat: 1.3152,
      lng: 103.7652,
    ),
    StationInfo(
      code: 'EW24',
      name: 'Jurong East',
      primaryLine: MRTLine.ewl,
      allCodes: ['EW24', 'NS1'],
      lat: 1.3331,
      lng: 103.7423,
      isInterchange: true,
    ),

    // Changi Branch (CGL -> EWL)
    StationInfo(
      code: 'CG1',
      name: 'Expo',
      primaryLine: MRTLine.ewl,
      allCodes: ['CG1', 'DT35'],
      lat: 1.3354,
      lng: 103.9616,
      isInterchange: true,
    ),
    StationInfo(
      code: 'CG2',
      name: 'Changi Airport',
      primaryLine: MRTLine.ewl,
      allCodes: ['CG2'],
      lat: 1.3573,
      lng: 103.9886,
    ),

    // North-South Line (NSL)
    StationInfo(
      code: 'NS9',
      name: 'Woodlands',
      primaryLine: MRTLine.nsl,
      allCodes: ['NS9', 'TE2'],
      lat: 1.4368,
      lng: 103.7865,
      isInterchange: true,
    ),
    StationInfo(
      code: 'NS16',
      name: 'Ang Mo Kio',
      primaryLine: MRTLine.nsl,
      allCodes: ['NS16', 'CR11'],
      lat: 1.3699,
      lng: 103.8496,
    ),
    StationInfo(
      code: 'NS19',
      name: 'Toa Payoh',
      primaryLine: MRTLine.nsl,
      allCodes: ['NS19'],
      lat: 1.3327,
      lng: 103.8475,
    ),
    StationInfo(
      code: 'NS22',
      name: 'Orchard',
      primaryLine: MRTLine.nsl,
      allCodes: ['NS22', 'TE14'],
      lat: 1.3040,
      lng: 103.8319,
      isInterchange: true,
    ),
    StationInfo(
      code: 'NS24',
      name: 'Dhoby Ghaut',
      primaryLine: MRTLine.nsl,
      allCodes: ['NS24', 'NE6', 'CC1'],
      lat: 1.2987,
      lng: 103.8459,
      isInterchange: true,
    ),
    StationInfo(
      code: 'NS27',
      name: 'Marina Bay',
      primaryLine: MRTLine.nsl,
      allCodes: ['NS27', 'CE2', 'TE20'],
      lat: 1.2764,
      lng: 103.8546,
      isInterchange: true,
    ),

    // North-East Line (NEL)
    StationInfo(
      code: 'NE1',
      name: 'HarbourFront',
      primaryLine: MRTLine.nel,
      allCodes: ['NE1', 'CC29'],
      lat: 1.2654,
      lng: 103.8224,
      isInterchange: true,
    ),
    StationInfo(
      code: 'NE4',
      name: 'Chinatown',
      primaryLine: MRTLine.nel,
      allCodes: ['NE4', 'DT19'],
      lat: 1.2844,
      lng: 103.8441,
      isInterchange: true,
    ),
    StationInfo(
      code: 'NE5',
      name: 'Clarke Quay',
      primaryLine: MRTLine.nel,
      allCodes: ['NE5'],
      lat: 1.2884,
      lng: 103.8466,
    ),
    StationInfo(
      code: 'NE12',
      name: 'Serangoon',
      primaryLine: MRTLine.nel,
      allCodes: ['NE12', 'CC13'],
      lat: 1.3498,
      lng: 103.8736,
      isInterchange: true,
    ),
    StationInfo(
      code: 'NE16',
      name: 'Sengkang',
      primaryLine: MRTLine.nel,
      allCodes: ['NE16', 'STC'],
      lat: 1.3917,
      lng: 103.8955,
      isInterchange: true,
    ),
    StationInfo(
      code: 'NE17',
      name: 'Punggol',
      primaryLine: MRTLine.nel,
      allCodes: ['NE17', 'PTC'],
      lat: 1.4050,
      lng: 103.9022,
      isInterchange: true,
    ),

    // Circle Line (CCL / CEL)
    StationInfo(
      code: 'CC2',
      name: 'Bras Basah',
      primaryLine: MRTLine.ccl,
      allCodes: ['CC2'],
      lat: 1.2968,
      lng: 103.8507,
    ),
    StationInfo(
      code: 'CC4',
      name: 'Promenade',
      primaryLine: MRTLine.ccl,
      allCodes: ['CC4', 'DT15'],
      lat: 1.2934,
      lng: 103.8604,
      isInterchange: true,
    ),
    StationInfo(
      code: 'CE1',
      name: 'Bayfront',
      primaryLine: MRTLine.ccl,
      allCodes: ['CE1', 'DT16'],
      lat: 1.2818,
      lng: 103.8591,
      isInterchange: true,
    ),

    // Downtown Line (DTL)
    StationInfo(
      code: 'DT1',
      name: 'Bukit Panjang',
      primaryLine: MRTLine.dtl,
      allCodes: ['DT1', 'BP6'],
      lat: 1.3789,
      lng: 103.7618,
      isInterchange: true,
    ),
    StationInfo(
      code: 'DT12',
      name: 'Little India',
      primaryLine: MRTLine.dtl,
      allCodes: ['DT12', 'NE7'],
      lat: 1.3068,
      lng: 103.8492,
      isInterchange: true,
    ),
    StationInfo(
      code: 'DT32',
      name: 'Tampines Downtown',
      primaryLine: MRTLine.dtl,
      allCodes: ['DT32', 'EW2'],
      lat: 1.3533,
      lng: 103.9452,
      isInterchange: true,
    ),

    // Thomson-East Coast Line (TEL)
    StationInfo(
      code: 'TE1',
      name: 'Woodlands North',
      primaryLine: MRTLine.tel,
      allCodes: ['TE1'],
      lat: 1.4482,
      lng: 103.7857,
    ),
    StationInfo(
      code: 'TE17',
      name: 'Outram Park TEL',
      primaryLine: MRTLine.tel,
      allCodes: ['TE17', 'EW16', 'NE3'],
      lat: 1.2803,
      lng: 103.8395,
      isInterchange: true,
    ),
    StationInfo(
      code: 'TE22',
      name: 'Gardens by the Bay',
      primaryLine: MRTLine.tel,
      allCodes: ['TE22'],
      lat: 1.2783,
      lng: 103.8670,
    ),
  ];

  /// Find station by name (case-insensitive, handles fuzzy matching).
  static StationInfo? findStationByName(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return null;

    // Exact name match
    for (final stn in stations) {
      if (stn.name.toLowerCase() == clean) return stn;
    }

    // Contains match
    for (final stn in stations) {
      if (stn.name.toLowerCase().contains(clean) ||
          clean.contains(stn.name.toLowerCase())) {
        return stn;
      }
    }

    return null;
  }

  /// Find station by code (e.g. "EW2", "DT32", "ew14").
  static StationInfo? findStationByCode(String code) {
    final clean = code.trim().toUpperCase();
    if (clean.isEmpty) return null;

    for (final stn in stations) {
      if (stn.code.toUpperCase() == clean ||
          stn.allCodes.map((c) => c.toUpperCase()).contains(clean)) {
        return stn;
      }
    }
    return null;
  }

  /// Returns all stations belonging to a specific line.
  static List<StationInfo> getStationsForLine(MRTLine line) {
    return stations.where((s) => s.primaryLine == line).toList();
  }

  /// Returns sequence of stations between two stations on the same line.
  static List<StationInfo> getRouteSequence(
    StationInfo origin,
    StationInfo destination,
  ) {
    if (origin.primaryLine != destination.primaryLine) {
      return [origin, destination];
    }
    final lineStations = getStationsForLine(origin.primaryLine);
    final idx1 = lineStations.indexWhere((s) => s.code == origin.code);
    final idx2 = lineStations.indexWhere((s) => s.code == destination.code);

    if (idx1 == -1 || idx2 == -1) return [origin, destination];

    if (idx1 <= idx2) {
      return lineStations.sublist(idx1, idx2 + 1);
    } else {
      return lineStations.sublist(idx2, idx1 + 1).reversed.toList();
    }
  }
}
