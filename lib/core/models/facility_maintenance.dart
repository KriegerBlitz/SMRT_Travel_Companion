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

  /// Lift is down or undergoing maintenance.
  ///
  /// FIX [Bug 1]: The previous implementation used `!s.contains('operational')`
  /// as a catch-all final clause, which falsely flagged empty strings, 'Unknown',
  /// or any unrecognised status as out-of-service. This could misfired on live
  /// API data where the field is absent or uses an unexpected value.
  ///
  /// Fixed with an explicit keyword allowlist: only known outage phrases return
  /// true. Anything else (empty, 'Unknown', or genuinely operational) returns
  /// false — treating ambiguous statuses as in-service by default.
  bool get isOutOfService {
    final s = status.toLowerCase().trim();
    // Empty or unrecognised status → assume operational (safe default)
    if (s.isEmpty) return false;
    // Explicit out-of-service keyword allowlist
    return s.contains('out of service') ||
        s.contains('down') ||
        s.contains('maintenance') ||
        s.contains('repair') ||
        s.contains('inoperative') ||
        s.contains('overhaul');
    // NOTE: Removed `!s.contains('operational')` — that clause was the bug.
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
