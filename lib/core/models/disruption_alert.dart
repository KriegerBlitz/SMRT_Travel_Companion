import '../transit/canonical_line_table.dart';

/// Structured disruption alert from LTA DataMall TrainServiceAlerts.
class TrainServiceAlert {
  /// 1 = Normal service or minor delays; 2 = Disrupted service or major delays
  final int status;
  final List<AffectedSegment> affectedSegments;
  final List<AlertMessage> messages;
  final bool isSimulated;

  const TrainServiceAlert({
    required this.status,
    this.affectedSegments = const [],
    this.messages = const [],
    this.isSimulated = false,
  });

  bool get isDisrupted => status == 2 || affectedSegments.isNotEmpty;

  factory TrainServiceAlert.fromJson(Map<String, dynamic> json, {bool isSimulated = false}) {
    final valueObj = json['value'] as Map<String, dynamic>? ?? json;
    final status = valueObj['Status'] as int? ?? 1;

    final rawSegments = valueObj['AffectedSegments'] as List<dynamic>? ?? [];
    final segments = rawSegments
        .map((s) => AffectedSegment.fromJson(s as Map<String, dynamic>))
        .toList();

    final rawMessages = valueObj['Message'] as List<dynamic>? ?? [];
    final messages = rawMessages
        .map((m) => AlertMessage.fromJson(m as Map<String, dynamic>))
        .toList();

    return TrainServiceAlert(
      status: status,
      affectedSegments: segments,
      messages: messages,
      isSimulated: isSimulated,
    );
  }

  /// Checks whether a specific station code is currently affected by any disruption
  bool isStationAffected(String stationCode) {
    return affectedSegments.any((seg) => seg.isStationAffected(stationCode));
  }
}

/// Represents a specific disrupted segment along a rail line.
class AffectedSegment {
  final String line;
  final String direction;
  final List<String> stations;
  final String freePublicBus;
  final String freeMrtShuttle;
  final String mrtShuttleDirection;

  const AffectedSegment({
    required this.line,
    required this.direction,
    required this.stations,
    required this.freePublicBus,
    required this.freeMrtShuttle,
    required this.mrtShuttleDirection,
  });

  bool get hasFreeBus =>
      freePublicBus.isNotEmpty && freePublicBus.toLowerCase() != 'null';

  bool get hasMrtShuttle =>
      freeMrtShuttle.isNotEmpty && freeMrtShuttle.toLowerCase() != 'null';

  bool isStationAffected(String stationCode) {
    final target = stationCode.trim().toUpperCase();
    return stations.any((s) => s.toUpperCase() == target);
  }

  factory AffectedSegment.fromJson(Map<String, dynamic> json) {
    final rawStations = json['Stations']?.toString() ?? '';
    return AffectedSegment(
      line: json['Line']?.toString() ?? '',
      direction: json['Direction']?.toString() ?? 'Both',
      stations: CanonicalLineTable.parseAffectedStations(rawStations),
      freePublicBus: json['FreePublicBus']?.toString() ?? '',
      freeMrtShuttle: json['FreeMRTShuttle']?.toString() ?? '',
      mrtShuttleDirection: json['MRTShuttleDirection']?.toString() ?? 'Both',
    );
  }
}

/// Advisory message attached to train service alerts.
class AlertMessage {
  final String content;
  final String createdDate;

  const AlertMessage({
    required this.content,
    required this.createdDate,
  });

  factory AlertMessage.fromJson(Map<String, dynamic> json) {
    return AlertMessage(
      content: json['Content']?.toString() ?? '',
      createdDate: json['CreatedDate']?.toString() ?? '',
    );
  }
}
