/// Bus arrival information from LTA DataMall v3/BusArrival.
class BusArrivalService {
  final String serviceNo;
  final String busStopCode;
  final List<NextBus> nextBuses;

  const BusArrivalService({
    required this.serviceNo,
    required this.busStopCode,
    this.nextBuses = const [],
  });

  bool get hasWheelchairAccessibleBus =>
      nextBuses.any((b) => b.isWheelchairAccessible);

  NextBus? get earliestWabBus {
    for (final b in nextBuses) {
      if (b.isWheelchairAccessible) return b;
    }
    return null;
  }

  factory BusArrivalService.fromJson(Map<String, dynamic> json, String stopCode) {
    final rawBuses = [
      json['NextBus'],
      json['NextBus2'],
      json['NextBus3'],
    ].where((b) => b != null && b is Map<String, dynamic>).toList();

    final buses = rawBuses
        .map((b) => NextBus.fromJson(b as Map<String, dynamic>))
        .where((b) => b.estimatedArrival.isNotEmpty)
        .toList();

    return BusArrivalService(
      serviceNo: json['ServiceNo']?.toString() ?? '',
      busStopCode: stopCode,
      nextBuses: buses,
    );
  }
}

/// An arriving bus instance.
class NextBus {
  final String estimatedArrival;
  final String load; // SEA, SDA, LSD
  final String feature; // WAB = Wheelchair Accessible
  final String type; // SD, DD, BD

  const NextBus({
    required this.estimatedArrival,
    required this.load,
    required this.feature,
    required this.type,
  });

  bool get isWheelchairAccessible => feature.toUpperCase() == 'WAB';

  String get loadDescription {
    switch (load.toUpperCase()) {
      case 'SEA':
        return 'Seats Available';
      case 'SDA':
        return 'Standing Available';
      case 'LSD':
        return 'Limited Standing';
      default:
        return 'Occupancy Unknown';
    }
  }

  int? get minutesToArrival {
    if (estimatedArrival.isEmpty) return null;
    try {
      final arrivalTime = DateTime.parse(estimatedArrival);
      final diff = arrivalTime.difference(DateTime.now()).inMinutes;
      return diff < 0 ? 0 : diff;
    } catch (_) {
      return null;
    }
  }

  factory NextBus.fromJson(Map<String, dynamic> json) {
    return NextBus(
      estimatedArrival: json['EstimatedArrival']?.toString() ?? '',
      load: json['Load']?.toString() ?? '',
      feature: json['Feature']?.toString() ?? '',
      type: json['Type']?.toString() ?? '',
    );
  }
}
