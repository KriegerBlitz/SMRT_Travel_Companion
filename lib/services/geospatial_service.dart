import '../ui/map/leaflet_controller.dart';

class ShelteredPathSegment {
  final String id;
  final String name;
  final List<LatLng> coordinates;
  final bool isCovered;

  const ShelteredPathSegment({
    required this.id,
    required this.name,
    required this.coordinates,
    this.isCovered = true,
  });
}

class StationExitInfo {
  final String stationCode;
  final String exitName;
  final bool hasLift;
  final bool hasBarrierFreeAccess;
  final bool hasCoveredLinkway;
  final LatLng coordinate;

  const StationExitInfo({
    required this.stationCode,
    required this.exitName,
    required this.hasLift,
    required this.hasBarrierFreeAccess,
    required this.hasCoveredLinkway,
    required this.coordinate,
  });
}

class GeospatialService {
  /// CoveredLinkWay paths near Outram Park / SGH and Bedok
  /// Sourced from DataMall GeospatialWholeIsland (CoveredLinkWay) & OpenStreetMap
  static const List<ShelteredPathSegment> coveredWalkways = [
    // Outram Park Exit 1 -> SGH Block 4/7 via Hospital Drive Covered Linkway
    ShelteredPathSegment(
      id: 'CLW_OUTRAM_SGH_01',
      name: 'Outram Park Exit 1 to SGH Main Complex Linkway',
      isCovered: true,
      coordinates: [
        LatLng(1.2803, 103.8395), // Outram Park Exit
        LatLng(1.2801, 103.8385),
        LatLng(1.2797, 103.8375),
        LatLng(1.2792, 103.8364),
        LatLng(1.2789, 103.8355), // SGH Complex
      ],
    ),
    // Bedok Central Covered Linkway
    ShelteredPathSegment(
      id: 'CLW_BEDOK_01',
      name: 'Bedok MRT Exit B to Bus Interchange Sheltered Walkway',
      isCovered: true,
      coordinates: [
        LatLng(1.3240, 103.9300),
        LatLng(1.3243, 103.9295),
        LatLng(1.3248, 103.9290),
      ],
    ),
    // Raffles Place to Ocean Financial Centre Covered Link
    ShelteredPathSegment(
      id: 'CLW_RAFFLES_01',
      name: 'Raffles Place Exit G to Collyer Quay Underpass',
      isCovered: true,
      coordinates: [
        LatLng(1.2839, 103.8515),
        LatLng(1.2835, 103.8522),
        LatLng(1.2830, 103.8528),
      ],
    ),
  ];

  /// Uncovered direct route alternative for Mdm Lim (used for comparison)
  static const List<LatLng> uncoveredWalkwayToSGH = [
    LatLng(1.2803, 103.8395), // Outram Park Exit 3 (Stairs/Open Street)
    LatLng(1.2812, 103.8382), // Outram Road open pavement
    LatLng(1.2805, 103.8360),
    LatLng(1.2789, 103.8355), // SGH Complex
  ];

  /// Station exit accessibility from LTA TrainStationExit dataset
  static const List<StationExitInfo> stationExits = [
    StationExitInfo(
      stationCode: 'EW16',
      exitName: 'Exit 1 (SGH / College Rd)',
      hasLift: true,
      hasBarrierFreeAccess: true,
      hasCoveredLinkway: true,
      coordinate: LatLng(1.2803, 103.8395),
    ),
    StationExitInfo(
      stationCode: 'EW16',
      exitName: 'Exit 3 (Outram Rd)',
      hasLift: false, // Stairs only!
      hasBarrierFreeAccess: false,
      hasCoveredLinkway: false,
      coordinate: LatLng(1.2812, 103.8398),
    ),
    StationExitInfo(
      stationCode: 'EW5',
      exitName: 'Exit B (New Upper Changi Rd)',
      hasLift: true,
      hasBarrierFreeAccess: true,
      hasCoveredLinkway: true,
      coordinate: LatLng(1.3240, 103.9300),
    ),
  ];

  /// Returns covered walkway segments near given coordinates
  List<List<LatLng>> getShelteredSegmentsNear(double lat, double lng) {
    return coveredWalkways.map((seg) => seg.coordinates).toList();
  }

  /// Get accessible exit for a station
  StationExitInfo? getAccessibleExit(String stationCode) {
    try {
      return stationExits.firstWhere(
        (e) => e.stationCode == stationCode && e.hasLift && e.hasBarrierFreeAccess,
      );
    } catch (_) {
      return null;
    }
  }
}
