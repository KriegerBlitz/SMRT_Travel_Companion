import 'package:flutter/material.dart';

/// Crowd density level per DataMall PCDRealTime and PCDForecast feeds.
enum CrowdLevel {
  low,
  moderate,
  high,
  na;

  static CrowdLevel parse(String? raw) {
    if (raw == null) return CrowdLevel.na;
    final val = raw.trim().toLowerCase();
    switch (val) {
      case 'l':
      case 'low':
        return CrowdLevel.low;
      case 'm':
      case 'moderate':
        return CrowdLevel.moderate;
      case 'h':
      case 'high':
        return CrowdLevel.high;
      default:
        return CrowdLevel.na;
    }
  }

  String get displayName {
    switch (this) {
      case CrowdLevel.low:
        return 'Low Crowding';
      case CrowdLevel.moderate:
        return 'Moderate Crowding';
      case CrowdLevel.high:
        return 'High Crowding';
      case CrowdLevel.na:
        return 'Crowd Data Unavailable';
    }
  }

  Color get color {
    switch (this) {
      case CrowdLevel.low:
        return const Color(0xFF10B981); // Emerald Green
      case CrowdLevel.moderate:
        return const Color(0xFFF59E0B); // Amber
      case CrowdLevel.high:
        return const Color(0xFFEF4444); // Red
      case CrowdLevel.na:
        return const Color(0xFF9CA3AF); // Gray
    }
  }

  String get rawCode {
    switch (this) {
      case CrowdLevel.low:
        return 'l';
      case CrowdLevel.moderate:
        return 'm';
      case CrowdLevel.high:
        return 'h';
      case CrowdLevel.na:
        return 'NA';
    }
  }
}

/// Real-time or forecasted station crowd record.
class StationCrowd {
  final String stationCode;
  final String startTime;
  final String endTime;
  final CrowdLevel crowdLevel;
  final bool isForecast;

  const StationCrowd({
    required this.stationCode,
    required this.startTime,
    required this.endTime,
    required this.crowdLevel,
    this.isForecast = false,
  });

  factory StationCrowd.fromJson(Map<String, dynamic> json, {bool isForecast = false}) {
    return StationCrowd(
      stationCode: json['Station']?.toString() ?? '',
      startTime: json['StartTime']?.toString() ?? '',
      endTime: json['EndTime']?.toString() ?? '',
      crowdLevel: CrowdLevel.parse(json['CrowdLevel']?.toString()),
      isForecast: isForecast,
    );
  }

  @override
  String toString() => '$stationCode: ${crowdLevel.displayName} ($startTime-$endTime)';
}
