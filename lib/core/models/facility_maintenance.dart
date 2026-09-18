/// Lift outage and facility maintenance record from DataMall v2/FacilitiesMaintenance.
class LiftMaintenance {
  final String station;
  final String unitId;
  final String location;
  final String exit;
  final String status;
  final String? description;
  final String? estimatedResumptionDate;

  const LiftMaintenance({
    required this.station,
    required this.unitId,
    required this.location,
    required this.exit,
    required this.status,
    this.description,
    this.estimatedResumptionDate,
  });

  /// Lift is down or undergoing maintenance
  bool get isOutOfService {
    final s = status.toLowerCase();
    return s.contains('out of service') ||
        s.contains('down') ||
        s.contains('maintenance') ||
        s.contains('repair') ||
        s.contains('inoperative') ||
        s.contains('overhaul') ||
        !s.contains('operational');
  }

  factory LiftMaintenance.fromJson(Map<String, dynamic> json) {
    return LiftMaintenance(
      station: json['Station']?.toString() ?? '',
      unitId: json['UnitID']?.toString() ?? '',
      location: json['Location']?.toString() ?? '',
      exit: json['Exit']?.toString() ?? '',
      status: json['Status']?.toString() ?? 'Operational',
      description: json['Description']?.toString(),
      estimatedResumptionDate: json['EstResumptionDate']?.toString(),
    );
  }
}
