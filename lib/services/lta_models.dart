import 'package:flutter/material.dart';

/// Crowd density level for MRT platforms (from PCDRealTime and PCDForecast).
enum CrowdLevel {
  low('Low', Color(0xFF22C55E), 'Green'),
  moderate('Moderate', Color(0xFFF59E0B), 'Amber'),
  high('High', Color(0xFFEF4444), 'Red');

  final String label;
  final Color color;
  final String colorName;

  const CrowdLevel(this.label, this.color, this.colorName);

  static CrowdLevel fromString(String? val) {
    if (val == null) return CrowdLevel.low;
    final clean = val.trim().toLowerCase();
    if (clean.contains('high') || clean.contains('red') || clean == 'h') {
      return CrowdLevel.high;
    }
    if (clean.contains('mod') || clean.contains('amber') || clean == 'm') {
      return CrowdLevel.moderate;
    }
    return CrowdLevel.low;
  }
}

/// Train Service Alert model from LTA DataMall TrainServiceAlerts endpoint.
class TrainServiceAlert {
  final int status; // 1 = Normal, 2 = Disrupted
  final String line; // e.g. "EWL"
  final String direction; // e.g. "To Pasir Ris"
  final List<String> affectedStations; // e.g. ["EW1", "EW2", "EW3"]
  final bool freePublicBus;
  final bool freeMrtShuttle;
  final String message; // Free text advisory message
  final DateTime timestamp;

  const TrainServiceAlert({
    required this.status,
    required this.line,
    required this.direction,
    required this.affectedStations,
    required this.freePublicBus,
    required this.freeMrtShuttle,
    required this.message,
    required this.timestamp,
  });

  bool get isDisrupted => status == 2;

  factory TrainServiceAlert.normal() {
    return TrainServiceAlert(
      status: 1,
      line: 'ALL',
      direction: 'Both',
      affectedStations: const [],
      freePublicBus: false,
      freeMrtShuttle: false,
      message: 'All train services are operating normally.',
      timestamp: DateTime.now(),
    );
  }

  factory TrainServiceAlert.fromJson(Map<String, dynamic> json) {
    final status = json['Status'] is int ? json['Status'] as int : 1;
    final line = json['Line']?.toString() ?? 'ALL';
    final direction = json['Direction']?.toString() ?? 'Both';
    final stationsRaw = json['Stations']?.toString() ?? '';
    final stationsList = stationsRaw.isNotEmpty
        ? stationsRaw.split(',').map((s) => s.trim()).toList()
        : <String>[];
    final freePublicBus = json['FreePublicBus'] == true ||
        json['FreePublicBus']?.toString().toLowerCase() == 'true';
    final freeMrtShuttle = json['FreeMRTShuttle'] == true ||
        json['FreeMRTShuttle']?.toString().toLowerCase() == 'true';
    final message = json['Message']?.toString() ?? '';

    return TrainServiceAlert(
      status: status,
      line: line,
      direction: direction,
      affectedStations: stationsList,
      freePublicBus: freePublicBus,
      freeMrtShuttle: freeMrtShuttle,
      message: message,
      timestamp: DateTime.now(),
    );
  }
}

/// Platform Crowd Density metadata (PCDRealTime + PCDForecast).
class StationCrowdInfo {
  final String stationCode;
  final CrowdLevel realTime;
  final CrowdLevel forecast30Min; // 30-min-ahead forecast

  const StationCrowdInfo({
    required this.stationCode,
    required this.realTime,
    required this.forecast30Min,
  });

  bool get isForecastSpike =>
      realTime != CrowdLevel.high && forecast30Min == CrowdLevel.high;
}

/// Lift or escalator facility maintenance status (v2/FacilitiesMaintenance).
class FacilityMaintenance {
  final String stationCode;
  final String stationName;
  final String facilityType; // e.g. "Lift", "Escalator"
  final String locationDescription; // e.g. "Lift 2 (Exit B to Concourse)"
  final bool isOutOfService;
  final String? expectedResolution;

  const FacilityMaintenance({
    required this.stationCode,
    required this.stationName,
    required this.facilityType,
    required this.locationDescription,
    required this.isOutOfService,
    this.expectedResolution,
  });

  factory FacilityMaintenance.fromJson(Map<String, dynamic> json) {
    return FacilityMaintenance(
      stationCode: json['StationCode']?.toString() ?? '',
      stationName: json['StationName']?.toString() ?? '',
      facilityType: json['FacilityType']?.toString() ?? 'Lift',
      locationDescription: json['Description']?.toString() ?? '',
      isOutOfService: json['Status']?.toString().toLowerCase() == 'maintenance' ||
          json['Status']?.toString().toLowerCase() == 'out_of_service',
      expectedResolution: json['ExpectedResolution']?.toString(),
    );
  }
}

/// Wheelchair Accessible Bus (WAB) arrival info from v3/BusArrival.
class BusArrivalInfo {
  final String serviceNo;
  final String busStopCode;
  final String load; // SEA (Seats Available), SDA (Standing Available), LSD (Limited Standing)
  final bool isWab; // Feature == 'WAB'
  final String type; // SD (Single Deck), DD (Double Deck), BD (Bendy)
  final int estimatedMinutes;

  const BusArrivalInfo({
    required this.serviceNo,
    required this.busStopCode,
    required this.load,
    required this.isWab,
    required this.type,
    required this.estimatedMinutes,
  });

  String get loadDescription {
    switch (load.toUpperCase()) {
      case 'SEA':
        return 'Seats Available';
      case 'SDA':
        return 'Standing Available';
      case 'LSD':
        return 'Limited Standing';
      default:
        return 'Seats Available';
    }
  }

  Color get loadColor {
    switch (load.toUpperCase()) {
      case 'SEA':
        return const Color(0xFF22C55E); // Green
      case 'SDA':
        return const Color(0xFFF59E0B); // Amber
      case 'LSD':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF22C55E);
    }
  }
}
