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

  /// Master list of all operational Singapore MRT and LRT stations.
  /// Contains accurate GPS coordinates, interchange associations, and primary line tags.
  static const List<StationInfo> stations = [
    // ==========================================
    // 1. EAST-WEST LINE (EWL) + CHANGI AIRPORT BRANCH
    // ==========================================
    StationInfo(
      code: 'EW1',
      name: 'Pasir Ris',
      primaryLine: MRTLine.ewl,
      allCodes: ['EW1', 'CR5'],
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
      code: 'EW22',
      name: 'Dover',
      primaryLine: MRTLine.ewl,
      allCodes: ['EW22'],
      lat: 1.3114,
      lng: 103.7786,
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
    StationInfo(
      code: 'EW25',
      name: 'Chinese Garden',
      primaryLine: MRTLine.ewl,
      allCodes: ['EW25'],
      lat: 1.3424,
      lng: 103.7326,
    ),
    StationInfo(
      code: 'EW26',
      name: 'Lakeside',
      primaryLine: MRTLine.ewl,
      allCodes: ['EW26'],
      lat: 1.3443,
      lng: 103.7209,
    ),
    StationInfo(
      code: 'EW27',
      name: 'Boon Lay',
      primaryLine: MRTLine.ewl,
      allCodes: ['EW27'],
      lat: 1.3386,
      lng: 103.7060,
      isInterchange: true,
    ),
    StationInfo(
      code: 'EW28',
      name: 'Pioneer',
      primaryLine: MRTLine.ewl,
      allCodes: ['EW28'],
      lat: 1.3376,
      lng: 103.6974,
    ),
    StationInfo(
      code: 'EW29',
      name: 'Joo Koon',
      primaryLine: MRTLine.ewl,
      allCodes: ['EW29'],
      lat: 1.3277,
      lng: 103.6784,
    ),
    StationInfo(
      code: 'EW30',
      name: 'Gul Circle',
      primaryLine: MRTLine.ewl,
      allCodes: ['EW30'],
      lat: 1.3195,
      lng: 103.6605,
    ),
    StationInfo(
      code: 'EW31',
      name: 'Tuas Crescent',
      primaryLine: MRTLine.ewl,
      allCodes: ['EW31'],
      lat: 1.3210,
      lng: 103.6491,
    ),
    StationInfo(
      code: 'EW32',
      name: 'Tuas West Road',
      primaryLine: MRTLine.ewl,
      allCodes: ['EW32'],
      lat: 1.3300,
      lng: 103.6396,
    ),
    StationInfo(
      code: 'EW33',
      name: 'Tuas Link',
      primaryLine: MRTLine.ewl,
      allCodes: ['EW33'],
      lat: 1.3409,
      lng: 103.6369,
    ),
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

    // ==========================================
    // 2. NORTH-SOUTH LINE (NSL)
    // ==========================================
    StationInfo(
      code: 'NS2',
      name: 'Bukit Batok',
      primaryLine: MRTLine.nsl,
      allCodes: ['NS2'],
      lat: 1.3490,
      lng: 103.7496,
    ),
    StationInfo(
      code: 'NS3',
      name: 'Bukit Gombak',
      primaryLine: MRTLine.nsl,
      allCodes: ['NS3'],
      lat: 1.3587,
      lng: 103.7519,
    ),
    StationInfo(
      code: 'NS4',
      name: 'Choa Chu Kang',
      primaryLine: MRTLine.nsl,
      allCodes: ['NS4', 'BP1'],
      lat: 1.3854,
      lng: 103.7443,
      isInterchange: true,
    ),
    StationInfo(
      code: 'NS5',
      name: 'Yew Tee',
      primaryLine: MRTLine.nsl,
      allCodes: ['NS5'],
      lat: 1.3973,
      lng: 103.7474,
    ),
    StationInfo(
      code: 'NS7',
      name: 'Kranji',
      primaryLine: MRTLine.nsl,
      allCodes: ['NS7'],
      lat: 1.4251,
      lng: 103.7621,
    ),
    StationInfo(
      code: 'NS8',
      name: 'Marsiling',
      primaryLine: MRTLine.nsl,
      allCodes: ['NS8'],
      lat: 1.4325,
      lng: 103.7741,
    ),
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
      code: 'NS10',
      name: 'Admiralty',
      primaryLine: MRTLine.nsl,
      allCodes: ['NS10'],
      lat: 1.4406,
      lng: 103.8010,
    ),
    StationInfo(
      code: 'NS11',
      name: 'Sembawang',
      primaryLine: MRTLine.nsl,
      allCodes: ['NS11'],
      lat: 1.4491,
      lng: 103.8201,
    ),
    StationInfo(
      code: 'NS12',
      name: 'Canberra',
      primaryLine: MRTLine.nsl,
      allCodes: ['NS12'],
      lat: 1.4431,
      lng: 103.8297,
    ),
    StationInfo(
      code: 'NS13',
      name: 'Yishun',
      primaryLine: MRTLine.nsl,
      allCodes: ['NS13'],
      lat: 1.4294,
      lng: 103.8350,
    ),
    StationInfo(
      code: 'NS14',
      name: 'Khatib',
      primaryLine: MRTLine.nsl,
      allCodes: ['NS14'],
      lat: 1.4174,
      lng: 103.8329,
    ),
    StationInfo(
      code: 'NS15',
      name: 'Yio Chu Kang',
      primaryLine: MRTLine.nsl,
      allCodes: ['NS15'],
      lat: 1.3817,
      lng: 103.8449,
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
      code: 'NS17',
      name: 'Bishan',
      primaryLine: MRTLine.nsl,
      allCodes: ['NS17', 'CC15'],
      lat: 1.3508,
      lng: 103.8481,
      isInterchange: true,
    ),
    StationInfo(
      code: 'NS18',
      name: 'Braddell',
      primaryLine: MRTLine.nsl,
      allCodes: ['NS18'],
      lat: 1.3405,
      lng: 103.8468,
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
      code: 'NS20',
      name: 'Novena',
      primaryLine: MRTLine.nsl,
      allCodes: ['NS20'],
      lat: 1.3204,
      lng: 103.8438,
    ),
    StationInfo(
      code: 'NS21',
      name: 'Newton',
      primaryLine: MRTLine.nsl,
      allCodes: ['NS21', 'DT11'],
      lat: 1.3123,
      lng: 103.8380,
      isInterchange: true,
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
      code: 'NS23',
      name: 'Somerset',
      primaryLine: MRTLine.nsl,
      allCodes: ['NS23'],
      lat: 1.3003,
      lng: 103.8390,
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
    StationInfo(
      code: 'NS28',
      name: 'Marina South Pier',
      primaryLine: MRTLine.nsl,
      allCodes: ['NS28'],
      lat: 1.2661,
      lng: 103.8630,
    ),

    // ==========================================
    // 3. NORTH-EAST LINE (NEL)
    // ==========================================
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
      code: 'NE7',
      name: 'Little India',
      primaryLine: MRTLine.nel,
      allCodes: ['NE7', 'DT12'],
      lat: 1.3068,
      lng: 103.8492,
      isInterchange: true,
    ),
    StationInfo(
      code: 'NE8',
      name: 'Farrer Park',
      primaryLine: MRTLine.nel,
      allCodes: ['NE8'],
      lat: 1.3129,
      lng: 103.8546,
    ),
    StationInfo(
      code: 'NE9',
      name: 'Boon Keng',
      primaryLine: MRTLine.nel,
      allCodes: ['NE9'],
      lat: 1.3194,
      lng: 103.8617,
    ),
    StationInfo(
      code: 'NE10',
      name: 'Potong Pasir',
      primaryLine: MRTLine.nel,
      allCodes: ['NE10'],
      lat: 1.3313,
      lng: 103.8691,
    ),
    StationInfo(
      code: 'NE11',
      name: 'Woodleigh',
      primaryLine: MRTLine.nel,
      allCodes: ['NE11'],
      lat: 1.3392,
      lng: 103.8708,
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
      code: 'NE13',
      name: 'Kovan',
      primaryLine: MRTLine.nel,
      allCodes: ['NE13'],
      lat: 1.3601,
      lng: 103.8851,
    ),
    StationInfo(
      code: 'NE14',
      name: 'Hougang',
      primaryLine: MRTLine.nel,
      allCodes: ['NE14', 'CR8'],
      lat: 1.3713,
      lng: 103.8924,
    ),
    StationInfo(
      code: 'NE15',
      name: 'Buangkok',
      primaryLine: MRTLine.nel,
      allCodes: ['NE15'],
      lat: 1.3829,
      lng: 103.8931,
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
      allCodes: ['NE17', 'PTC', 'CP4'],
      lat: 1.4050,
      lng: 103.9022,
      isInterchange: true,
    ),
    StationInfo(
      code: 'NE18',
      name: 'Punggol Coast',
      primaryLine: MRTLine.nel,
      allCodes: ['NE18'],
      lat: 1.4150,
      lng: 103.9080,
    ),

    // ==========================================
    // 4. CIRCLE LINE (CCL) + CIRCLE EXTENSION
    // ==========================================
    StationInfo(
      code: 'CC2',
      name: 'Bras Basah',
      primaryLine: MRTLine.ccl,
      allCodes: ['CC2'],
      lat: 1.2968,
      lng: 103.8507,
    ),
    StationInfo(
      code: 'CC3',
      name: 'Esplanade',
      primaryLine: MRTLine.ccl,
      allCodes: ['CC3'],
      lat: 1.2935,
      lng: 103.8554,
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
      code: 'CC5',
      name: 'Nicoll Highway',
      primaryLine: MRTLine.ccl,
      allCodes: ['CC5'],
      lat: 1.3002,
      lng: 103.8636,
    ),
    StationInfo(
      code: 'CC6',
      name: 'Stadium',
      primaryLine: MRTLine.ccl,
      allCodes: ['CC6'],
      lat: 1.3028,
      lng: 103.8753,
    ),
    StationInfo(
      code: 'CC7',
      name: 'Mountbatten',
      primaryLine: MRTLine.ccl,
      allCodes: ['CC7'],
      lat: 1.3063,
      lng: 103.8825,
    ),
    StationInfo(
      code: 'CC8',
      name: 'Dakota',
      primaryLine: MRTLine.ccl,
      allCodes: ['CC8'],
      lat: 1.3085,
      lng: 103.8885,
    ),
    StationInfo(
      code: 'CC10',
      name: 'MacPherson',
      primaryLine: MRTLine.ccl,
      allCodes: ['CC10', 'DT26'],
      lat: 1.3262,
      lng: 103.8899,
      isInterchange: true,
    ),
    StationInfo(
      code: 'CC11',
      name: 'Tai Seng',
      primaryLine: MRTLine.ccl,
      allCodes: ['CC11'],
      lat: 1.3359,
      lng: 103.8879,
    ),
    StationInfo(
      code: 'CC12',
      name: 'Bartley',
      primaryLine: MRTLine.ccl,
      allCodes: ['CC12'],
      lat: 1.3426,
      lng: 103.8802,
    ),
    StationInfo(
      code: 'CC14',
      name: 'Lorong Chuan',
      primaryLine: MRTLine.ccl,
      allCodes: ['CC14'],
      lat: 1.3516,
      lng: 103.8641,
    ),
    StationInfo(
      code: 'CC16',
      name: 'Marymount',
      primaryLine: MRTLine.ccl,
      allCodes: ['CC16'],
      lat: 1.3487,
      lng: 103.8394,
    ),
    StationInfo(
      code: 'CC17',
      name: 'Caldecott',
      primaryLine: MRTLine.ccl,
      allCodes: ['CC17', 'TE9'],
      lat: 1.3378,
      lng: 103.8396,
      isInterchange: true,
    ),
    StationInfo(
      code: 'CC19',
      name: 'Botanic Gardens',
      primaryLine: MRTLine.ccl,
      allCodes: ['CC19', 'DT9'],
      lat: 1.3224,
      lng: 103.8153,
      isInterchange: true,
    ),
    StationInfo(
      code: 'CC20',
      name: 'Farrer Road',
      primaryLine: MRTLine.ccl,
      allCodes: ['CC20'],
      lat: 1.3174,
      lng: 103.8074,
    ),
    StationInfo(
      code: 'CC21',
      name: 'Holland Village',
      primaryLine: MRTLine.ccl,
      allCodes: ['CC21'],
      lat: 1.3120,
      lng: 103.7963,
    ),
    StationInfo(
      code: 'CC23',
      name: 'one-north',
      primaryLine: MRTLine.ccl,
      allCodes: ['CC23'],
      lat: 1.2995,
      lng: 103.7874,
    ),
    StationInfo(
      code: 'CC24',
      name: 'Kent Ridge',
      primaryLine: MRTLine.ccl,
      allCodes: ['CC24'],
      lat: 1.2935,
      lng: 103.7846,
    ),
    StationInfo(
      code: 'CC25',
      name: 'Haw Par Villa',
      primaryLine: MRTLine.ccl,
      allCodes: ['CC25'],
      lat: 1.2826,
      lng: 103.7818,
    ),
    StationInfo(
      code: 'CC26',
      name: 'Pasir Panjang',
      primaryLine: MRTLine.ccl,
      allCodes: ['CC26'],
      lat: 1.2762,
      lng: 103.7914,
    ),
    StationInfo(
      code: 'CC27',
      name: 'Labrador Park',
      primaryLine: MRTLine.ccl,
      allCodes: ['CC27'],
      lat: 1.2722,
      lng: 103.8030,
    ),
    StationInfo(
      code: 'CC28',
      name: 'Telok Blangah',
      primaryLine: MRTLine.ccl,
      allCodes: ['CC28'],
      lat: 1.2707,
      lng: 103.8098,
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

    // ==========================================
    // 5. DOWNTOWN LINE (DTL)
    // ==========================================
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
      code: 'DT2',
      name: 'Cashew',
      primaryLine: MRTLine.dtl,
      allCodes: ['DT2'],
      lat: 1.3698,
      lng: 103.7644,
    ),
    StationInfo(
      code: 'DT3',
      name: 'Hillview',
      primaryLine: MRTLine.dtl,
      allCodes: ['DT3'],
      lat: 1.3623,
      lng: 103.7674,
    ),
    StationInfo(
      code: 'DT5',
      name: 'Beauty World',
      primaryLine: MRTLine.dtl,
      allCodes: ['DT5'],
      lat: 1.3414,
      lng: 103.7758,
    ),
    StationInfo(
      code: 'DT6',
      name: 'King Albert Park',
      primaryLine: MRTLine.dtl,
      allCodes: ['DT6'],
      lat: 1.3357,
      lng: 103.7838,
    ),
    StationInfo(
      code: 'DT7',
      name: 'Sixth Avenue',
      primaryLine: MRTLine.dtl,
      allCodes: ['DT7'],
      lat: 1.3308,
      lng: 103.7969,
    ),
    StationInfo(
      code: 'DT8',
      name: 'Tan Kah Kee',
      primaryLine: MRTLine.dtl,
      allCodes: ['DT8'],
      lat: 1.3259,
      lng: 103.8077,
    ),
    StationInfo(
      code: 'DT10',
      name: 'Stevens',
      primaryLine: MRTLine.dtl,
      allCodes: ['DT10', 'TE11'],
      lat: 1.3201,
      lng: 103.8260,
      isInterchange: true,
    ),
    StationInfo(
      code: 'DT13',
      name: 'Rochor',
      primaryLine: MRTLine.dtl,
      allCodes: ['DT13'],
      lat: 1.3039,
      lng: 103.8527,
    ),
    StationInfo(
      code: 'DT17',
      name: 'Downtown',
      primaryLine: MRTLine.dtl,
      allCodes: ['DT17'],
      lat: 1.2794,
      lng: 103.8528,
    ),
    StationInfo(
      code: 'DT18',
      name: 'Telok Ayer',
      primaryLine: MRTLine.dtl,
      allCodes: ['DT18'],
      lat: 1.2822,
      lng: 103.8486,
    ),
    StationInfo(
      code: 'DT20',
      name: 'Fort Canning',
      primaryLine: MRTLine.dtl,
      allCodes: ['DT20'],
      lat: 1.2925,
      lng: 103.8443,
    ),
    StationInfo(
      code: 'DT21',
      name: 'Bencoolen',
      primaryLine: MRTLine.dtl,
      allCodes: ['DT21'],
      lat: 1.2989,
      lng: 103.8502,
    ),
    StationInfo(
      code: 'DT22',
      name: 'Jalan Besar',
      primaryLine: MRTLine.dtl,
      allCodes: ['DT22'],
      lat: 1.3052,
      lng: 103.8553,
    ),
    StationInfo(
      code: 'DT23',
      name: 'Bendemeer',
      primaryLine: MRTLine.dtl,
      allCodes: ['DT23'],
      lat: 1.3137,
      lng: 103.8630,
    ),
    StationInfo(
      code: 'DT24',
      name: 'Geylang Bahru',
      primaryLine: MRTLine.dtl,
      allCodes: ['DT24'],
      lat: 1.3215,
      lng: 103.8716,
    ),
    StationInfo(
      code: 'DT25',
      name: 'Mattar',
      primaryLine: MRTLine.dtl,
      allCodes: ['DT25'],
      lat: 1.3269,
      lng: 103.8832,
    ),
    StationInfo(
      code: 'DT27',
      name: 'Ubi',
      primaryLine: MRTLine.dtl,
      allCodes: ['DT27'],
      lat: 1.3299,
      lng: 103.8992,
    ),
    StationInfo(
      code: 'DT28',
      name: 'Kaki Bukit',
      primaryLine: MRTLine.dtl,
      allCodes: ['DT28'],
      lat: 1.3349,
      lng: 103.9085,
    ),
    StationInfo(
      code: 'DT29',
      name: 'Bedok North',
      primaryLine: MRTLine.dtl,
      allCodes: ['DT29'],
      lat: 1.3347,
      lng: 103.9180,
    ),
    StationInfo(
      code: 'DT30',
      name: 'Bedok Reservoir',
      primaryLine: MRTLine.dtl,
      allCodes: ['DT30'],
      lat: 1.3366,
      lng: 103.9329,
    ),
    StationInfo(
      code: 'DT31',
      name: 'Tampines West',
      primaryLine: MRTLine.dtl,
      allCodes: ['DT31'],
      lat: 1.3455,
      lng: 103.9385,
    ),
    StationInfo(
      code: 'DT33',
      name: 'Tampines East',
      primaryLine: MRTLine.dtl,
      allCodes: ['DT33'],
      lat: 1.3562,
      lng: 103.9546,
    ),
    StationInfo(
      code: 'DT34',
      name: 'Upper Changi',
      primaryLine: MRTLine.dtl,
      allCodes: ['DT34'],
      lat: 1.3417,
      lng: 103.9614,
    ),

    // ==========================================
    // 6. THOMSON-EAST COAST LINE (TEL)
    // ==========================================
    StationInfo(
      code: 'TE1',
      name: 'Woodlands North',
      primaryLine: MRTLine.tel,
      allCodes: ['TE1'],
      lat: 1.4482,
      lng: 103.7857,
    ),
    StationInfo(
      code: 'TE3',
      name: 'Woodlands South',
      primaryLine: MRTLine.tel,
      allCodes: ['TE3'],
      lat: 1.4274,
      lng: 103.7933,
    ),
    StationInfo(
      code: 'TE4',
      name: 'Springleaf',
      primaryLine: MRTLine.tel,
      allCodes: ['TE4'],
      lat: 1.3976,
      lng: 103.8180,
    ),
    StationInfo(
      code: 'TE5',
      name: 'Lentor',
      primaryLine: MRTLine.tel,
      allCodes: ['TE5'],
      lat: 1.3854,
      lng: 103.8360,
    ),
    StationInfo(
      code: 'TE6',
      name: 'Mayflower',
      primaryLine: MRTLine.tel,
      allCodes: ['TE6'],
      lat: 1.3715,
      lng: 103.8366,
    ),
    StationInfo(
      code: 'TE7',
      name: 'Bright Hill',
      primaryLine: MRTLine.tel,
      allCodes: ['TE7', 'CR13'],
      lat: 1.3633,
      lng: 103.8333,
    ),
    StationInfo(
      code: 'TE8',
      name: 'Upper Thomson',
      primaryLine: MRTLine.tel,
      allCodes: ['TE8'],
      lat: 1.3544,
      lng: 103.8329,
    ),
    StationInfo(
      code: 'TE12',
      name: 'Napier',
      primaryLine: MRTLine.tel,
      allCodes: ['TE12'],
      lat: 1.3068,
      lng: 103.8186,
    ),
    StationInfo(
      code: 'TE13',
      name: 'Orchard Boulevard',
      primaryLine: MRTLine.tel,
      allCodes: ['TE13'],
      lat: 1.3023,
      lng: 103.8239,
    ),
    StationInfo(
      code: 'TE15',
      name: 'Great World',
      primaryLine: MRTLine.tel,
      allCodes: ['TE15'],
      lat: 1.2936,
      lng: 103.8319,
    ),
    StationInfo(
      code: 'TE16',
      name: 'Havelock',
      primaryLine: MRTLine.tel,
      allCodes: ['TE16'],
      lat: 1.2882,
      lng: 103.8334,
    ),
    StationInfo(
      code: 'TE18',
      name: 'Maxwell',
      primaryLine: MRTLine.tel,
      allCodes: ['TE18'],
      lat: 1.2805,
      lng: 103.8439,
    ),
    StationInfo(
      code: 'TE19',
      name: 'Shenton Way',
      primaryLine: MRTLine.tel,
      allCodes: ['TE19'],
      lat: 1.2777,
      lng: 103.8504,
    ),
    StationInfo(
      code: 'TE22',
      name: 'Gardens by the Bay',
      primaryLine: MRTLine.tel,
      allCodes: ['TE22'],
      lat: 1.2783,
      lng: 103.8670,
    ),
    StationInfo(
      code: 'TE23',
      name: 'Tanjong Rhu',
      primaryLine: MRTLine.tel,
      allCodes: ['TE23'],
      lat: 1.2982,
      lng: 103.8732,
    ),
    StationInfo(
      code: 'TE24',
      name: 'Katong Park',
      primaryLine: MRTLine.tel,
      allCodes: ['TE24'],
      lat: 1.2986,
      lng: 103.8860,
    ),
    StationInfo(
      code: 'TE25',
      name: 'Tanjong Katong',
      primaryLine: MRTLine.tel,
      allCodes: ['TE25'],
      lat: 1.3013,
      lng: 103.8979,
    ),
    StationInfo(
      code: 'TE26',
      name: 'Marine Parade',
      primaryLine: MRTLine.tel,
      allCodes: ['TE26'],
      lat: 1.3033,
      lng: 103.9056,
    ),
    StationInfo(
      code: 'TE27',
      name: 'Marine Terrace',
      primaryLine: MRTLine.tel,
      allCodes: ['TE27'],
      lat: 1.3060,
      lng: 103.9161,
    ),
    StationInfo(
      code: 'TE28',
      name: 'Siglap',
      primaryLine: MRTLine.tel,
      allCodes: ['TE28'],
      lat: 1.3106,
      lng: 103.9304,
    ),
    StationInfo(
      code: 'TE29',
      name: 'Bayshore',
      primaryLine: MRTLine.tel,
      allCodes: ['TE29'],
      lat: 1.3129,
      lng: 103.9405,
    ),

    // ==========================================
    // 7. BUKIT PANJANG LRT (BPLRT)
    // ==========================================
    StationInfo(
      code: 'BP2',
      name: 'South View',
      primaryLine: MRTLine.bplrt,
      allCodes: ['BP2'],
      lat: 1.3803,
      lng: 103.7453,
    ),
    StationInfo(
      code: 'BP3',
      name: 'Keat Hong',
      primaryLine: MRTLine.bplrt,
      allCodes: ['BP3'],
      lat: 1.3786,
      lng: 103.7491,
    ),
    StationInfo(
      code: 'BP4',
      name: 'Teck Whye',
      primaryLine: MRTLine.bplrt,
      allCodes: ['BP4'],
      lat: 1.3767,
      lng: 103.7537,
    ),
    StationInfo(
      code: 'BP5',
      name: 'Phoenix',
      primaryLine: MRTLine.bplrt,
      allCodes: ['BP5'],
      lat: 1.3786,
      lng: 103.7580,
    ),
    StationInfo(
      code: 'BP7',
      name: 'Petir',
      primaryLine: MRTLine.bplrt,
      allCodes: ['BP7'],
      lat: 1.3778,
      lng: 103.7667,
    ),
    StationInfo(
      code: 'BP8',
      name: 'Pending',
      primaryLine: MRTLine.bplrt,
      allCodes: ['BP8'],
      lat: 1.3761,
      lng: 103.7713,
    ),
    StationInfo(
      code: 'BP9',
      name: 'Bangkit',
      primaryLine: MRTLine.bplrt,
      allCodes: ['BP9'],
      lat: 1.3800,
      lng: 103.7727,
    ),
    StationInfo(
      code: 'BP10',
      name: 'Fajar',
      primaryLine: MRTLine.bplrt,
      allCodes: ['BP10'],
      lat: 1.3845,
      lng: 103.7709,
    ),
    StationInfo(
      code: 'BP11',
      name: 'Segar',
      primaryLine: MRTLine.bplrt,
      allCodes: ['BP11'],
      lat: 1.3878,
      lng: 103.7696,
    ),
    StationInfo(
      code: 'BP12',
      name: 'Jelapang',
      primaryLine: MRTLine.bplrt,
      allCodes: ['BP12'],
      lat: 1.3867,
      lng: 103.7645,
    ),
    StationInfo(
      code: 'BP13',
      name: 'Senja',
      primaryLine: MRTLine.bplrt,
      allCodes: ['BP13'],
      lat: 1.3828,
      lng: 103.7596,
    ),

    // ==========================================
    // 8. SENGKANG LRT (SLRT)
    // ==========================================
    StationInfo(
      code: 'SE1',
      name: 'Compassvale',
      primaryLine: MRTLine.slrt,
      allCodes: ['SE1'],
      lat: 1.3945,
      lng: 103.9006,
    ),
    StationInfo(
      code: 'SE2',
      name: 'Rumbia',
      primaryLine: MRTLine.slrt,
      allCodes: ['SE2'],
      lat: 1.3915,
      lng: 103.9060,
    ),
    StationInfo(
      code: 'SE3',
      name: 'Bakau',
      primaryLine: MRTLine.slrt,
      allCodes: ['SE3'],
      lat: 1.3880,
      lng: 103.9054,
    ),
    StationInfo(
      code: 'SE4',
      name: 'Kangkar',
      primaryLine: MRTLine.slrt,
      allCodes: ['SE4'],
      lat: 1.3840,
      lng: 103.9022,
    ),
    StationInfo(
      code: 'SE5',
      name: 'Ranggung',
      primaryLine: MRTLine.slrt,
      allCodes: ['SE5'],
      lat: 1.3842,
      lng: 103.8973,
    ),
    StationInfo(
      code: 'SW1',
      name: 'Cheng Lim',
      primaryLine: MRTLine.slrt,
      allCodes: ['SW1'],
      lat: 1.3963,
      lng: 103.8938,
    ),
    StationInfo(
      code: 'SW2',
      name: 'Farmway',
      primaryLine: MRTLine.slrt,
      allCodes: ['SW2'],
      lat: 1.3972,
      lng: 103.8893,
    ),
    StationInfo(
      code: 'SW3',
      name: 'Kupang',
      primaryLine: MRTLine.slrt,
      allCodes: ['SW3'],
      lat: 1.3982,
      lng: 103.8812,
    ),
    StationInfo(
      code: 'SW4',
      name: 'Thanggam',
      primaryLine: MRTLine.slrt,
      allCodes: ['SW4'],
      lat: 1.3974,
      lng: 103.8757,
    ),
    StationInfo(
      code: 'SW5',
      name: 'Fernvale',
      primaryLine: MRTLine.slrt,
      allCodes: ['SW5'],
      lat: 1.3919,
      lng: 103.8741,
    ),
    StationInfo(
      code: 'SW6',
      name: 'Layar',
      primaryLine: MRTLine.slrt,
      allCodes: ['SW6'],
      lat: 1.3921,
      lng: 103.8800,
    ),
    StationInfo(
      code: 'SW7',
      name: 'Tongkang',
      primaryLine: MRTLine.slrt,
      allCodes: ['SW7'],
      lat: 1.3894,
      lng: 103.8858,
    ),
    StationInfo(
      code: 'SW8',
      name: 'Renjong',
      primaryLine: MRTLine.slrt,
      allCodes: ['SW8'],
      lat: 1.3868,
      lng: 103.8906,
    ),

    // ==========================================
    // 9. PUNGGOL LRT (PLRT)
    // ==========================================
    StationInfo(
      code: 'PE1',
      name: 'Cove',
      primaryLine: MRTLine.plrt,
      allCodes: ['PE1'],
      lat: 1.3993,
      lng: 103.9060,
    ),
    StationInfo(
      code: 'PE2',
      name: 'Meridian',
      primaryLine: MRTLine.plrt,
      allCodes: ['PE2'],
      lat: 1.3969,
      lng: 103.9089,
    ),
    StationInfo(
      code: 'PE3',
      name: 'Coral Edge',
      primaryLine: MRTLine.plrt,
      allCodes: ['PE3'],
      lat: 1.3940,
      lng: 103.9127,
    ),
    StationInfo(
      code: 'PE4',
      name: 'Riviera',
      primaryLine: MRTLine.plrt,
      allCodes: ['PE4'],
      lat: 1.3945,
      lng: 103.9162,
    ),
    StationInfo(
      code: 'PE5',
      name: 'Kadaloor',
      primaryLine: MRTLine.plrt,
      allCodes: ['PE5'],
      lat: 1.3996,
      lng: 103.9165,
    ),
    StationInfo(
      code: 'PE6',
      name: 'Oasis',
      primaryLine: MRTLine.plrt,
      allCodes: ['PE6'],
      lat: 1.4023,
      lng: 103.9128,
    ),
    StationInfo(
      code: 'PE7',
      name: 'Damai',
      primaryLine: MRTLine.plrt,
      allCodes: ['PE7'],
      lat: 1.4053,
      lng: 103.9086,
    ),
    StationInfo(
      code: 'PW1',
      name: 'Sam Kee',
      primaryLine: MRTLine.plrt,
      allCodes: ['PW1'],
      lat: 1.4098,
      lng: 103.9048,
    ),
    StationInfo(
      code: 'PW2',
      name: 'Teck Lee',
      primaryLine: MRTLine.plrt,
      allCodes: ['PW2'],
      lat: 1.4128,
      lng: 103.9067,
    ),
    StationInfo(
      code: 'PW3',
      name: 'Punggol Point',
      primaryLine: MRTLine.plrt,
      allCodes: ['PW3'],
      lat: 1.4169,
      lng: 103.9066,
    ),
    StationInfo(
      code: 'PW4',
      name: 'Samudera',
      primaryLine: MRTLine.plrt,
      allCodes: ['PW4'],
      lat: 1.4159,
      lng: 103.9021,
    ),
    StationInfo(
      code: 'PW5',
      name: 'Nibong',
      primaryLine: MRTLine.plrt,
      allCodes: ['PW5'],
      lat: 1.4119,
      lng: 103.9003,
    ),
    StationInfo(
      code: 'PW6',
      name: 'Sumang',
      primaryLine: MRTLine.plrt,
      allCodes: ['PW6'],
      lat: 1.4085,
      lng: 103.8986,
    ),
    StationInfo(
      code: 'PW7',
      name: 'Soo Teck',
      primaryLine: MRTLine.plrt,
      allCodes: ['PW7'],
      lat: 1.4052,
      lng: 103.8972,
    ),
  ];

  /// Canonical sequential station code order for each MRT and LRT line.
  static const Map<MRTLine, List<String>> _lineStationOrders = {
    MRTLine.ewl: [
      'EW1', 'EW2', 'EW3', 'EW4', 'EW5', 'EW6', 'EW7', 'EW8', 'EW9', 'EW10',
      'EW11', 'EW12', 'EW13', 'EW14', 'EW15', 'EW16', 'EW17', 'EW18', 'EW19', 'EW20',
      'EW21', 'EW22', 'EW23', 'EW24', 'EW25', 'EW26', 'EW27', 'EW28', 'EW29', 'EW30',
      'EW31', 'EW32', 'EW33', 'CG1', 'CG2',
    ],
    MRTLine.nsl: [
      'NS1', 'NS2', 'NS3', 'NS4', 'NS5', 'NS7', 'NS8', 'NS9', 'NS10',
      'NS11', 'NS12', 'NS13', 'NS14', 'NS15', 'NS16', 'NS17', 'NS18', 'NS19', 'NS20',
      'NS21', 'NS22', 'NS23', 'NS24', 'NS25', 'NS26', 'NS27', 'NS28',
    ],
    MRTLine.nel: [
      'NE1', 'NE3', 'NE4', 'NE5', 'NE6', 'NE7', 'NE8', 'NE9', 'NE10',
      'NE11', 'NE12', 'NE13', 'NE14', 'NE15', 'NE16', 'NE17', 'NE18',
    ],
    MRTLine.ccl: [
      'CC1', 'CC2', 'CC3', 'CC4', 'CC5', 'CC6', 'CC7', 'CC8', 'CC9', 'CC10',
      'CC11', 'CC12', 'CC13', 'CC14', 'CC15', 'CC16', 'CC17', 'CC19', 'CC20',
      'CC21', 'CC22', 'CC23', 'CC24', 'CC25', 'CC26', 'CC27', 'CC28', 'CC29',
      'CE1', 'CE2',
    ],
    MRTLine.dtl: [
      'DT1', 'DT2', 'DT3', 'DT5', 'DT6', 'DT7', 'DT8', 'DT9', 'DT10',
      'DT11', 'DT12', 'DT13', 'DT14', 'DT15', 'DT16', 'DT17', 'DT18', 'DT19', 'DT20',
      'DT21', 'DT22', 'DT23', 'DT24', 'DT25', 'DT26', 'DT27', 'DT28', 'DT29', 'DT30',
      'DT31', 'DT32', 'DT33', 'DT34', 'DT35',
    ],
    MRTLine.tel: [
      'TE1', 'TE2', 'TE3', 'TE4', 'TE5', 'TE6', 'TE7', 'TE8', 'TE9',
      'TE11', 'TE12', 'TE13', 'TE14', 'TE15', 'TE16', 'TE17', 'TE18', 'TE19', 'TE20',
      'TE22', 'TE23', 'TE24', 'TE25', 'TE26', 'TE27', 'TE28', 'TE29',
    ],
    MRTLine.bplrt: [
      'BP1', 'BP2', 'BP3', 'BP4', 'BP5', 'BP6', 'BP7', 'BP8', 'BP9', 'BP10',
      'BP11', 'BP12', 'BP13',
    ],
    MRTLine.slrt: [
      'STC', 'SE1', 'SE2', 'SE3', 'SE4', 'SE5', 'SW1', 'SW2', 'SW3', 'SW4',
      'SW5', 'SW6', 'SW7', 'SW8',
    ],
    MRTLine.plrt: [
      'PTC', 'PE1', 'PE2', 'PE3', 'PE4', 'PE5', 'PE6', 'PE7', 'PW1', 'PW2',
      'PW3', 'PW4', 'PW5', 'PW6', 'PW7',
    ],
  };

  /// Find station by name (case-insensitive, exact first, then fuzzy / prefix).
  static StationInfo? findStationByName(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return null;

    // 1. Exact name match
    for (final stn in stations) {
      if (stn.name.toLowerCase() == clean) return stn;
    }

    // 2. Exact code match
    final byCode = findStationByCode(clean);
    if (byCode != null) return byCode;

    // 3. Prefix match
    for (final stn in stations) {
      final stnLower = stn.name.toLowerCase();
      if (stnLower.startsWith(clean) || clean.startsWith(stnLower)) {
        return stn;
      }
    }

    // 4. Substring contains match
    for (final stn in stations) {
      final stnLower = stn.name.toLowerCase();
      if (stnLower.contains(clean) || clean.contains(stnLower)) {
        return stn;
      }
    }

    return null;
  }

  /// Find station by code (e.g. "EW2", "DT32", "ew14", "BP1", "TE17").
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

  /// Returns all stations belonging to a specific line, strictly in route sequence.
  static List<StationInfo> getStationsForLine(MRTLine line) {
    final codes = _lineStationOrders[line] ?? [];
    final List<StationInfo> result = [];
    for (final code in codes) {
      final stn = findStationByCode(code);
      if (stn != null && !result.contains(stn)) {
        result.add(stn);
      }
    }
    return result;
  }

  /// Checks if a station serves a specific MRTLine.
  static bool stationServesLine(StationInfo station, MRTLine line) {
    if (station.primaryLine == line) return true;
    final codes = _lineStationOrders[line] ?? [];
    return station.allCodes.any((c) => codes.contains(c.toUpperCase()));
  }

  /// Returns sequence of stations between two stations on the same line.
  static List<StationInfo> getRouteSequence(
    StationInfo origin,
    StationInfo destination,
  ) {
    // Identify common line
    MRTLine? commonLine;
    if (origin.primaryLine == destination.primaryLine) {
      commonLine = origin.primaryLine;
    } else {
      for (final line in MRTLine.values) {
        if (stationServesLine(origin, line) && stationServesLine(destination, line)) {
          commonLine = line;
          break;
        }
      }
    }

    if (commonLine == null) {
      return [origin, destination];
    }

    final lineStations = getStationsForLine(commonLine);
    final idx1 = lineStations.indexWhere((s) => s.name == origin.name || s.code == origin.code);
    final idx2 = lineStations.indexWhere((s) => s.name == destination.name || s.code == destination.code);

    if (idx1 == -1 || idx2 == -1) return [origin, destination];

    if (idx1 <= idx2) {
      return lineStations.sublist(idx1, idx2 + 1);
    } else {
      return lineStations.sublist(idx2, idx1 + 1).reversed.toList();
    }
  }
}
