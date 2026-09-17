/// Geographical coordinate representation.
class LatLng {
  final double lat;
  final double lng;

  const LatLng(this.lat, this.lng);

  List<double> toList() => [lat, lng];

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};
}

/// Representation of a station marker on the Leaflet map.
class MapStationMarker {
  final String code;
  final String name;
  final String lineName;
  final String lineColor; // Hex string e.g. '#009645'
  final double lat;
  final double lng;
  final String crowd; // 'low' | 'moderate' | 'high'
  final String? facilityAlert; // e.g. 'Lift 2 Out of Service'

  const MapStationMarker({
    required this.code,
    required this.name,
    required this.lineName,
    required this.lineColor,
    required this.lat,
    required this.lng,
    this.crowd = 'low',
    this.facilityAlert,
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'lineName': lineName,
        'lineColor': lineColor,
        'lat': lat,
        'lng': lng,
        'crowd': crowd,
        'facilityAlert': facilityAlert,
      };
}

/// Interface for controlling the Leaflet Map instance across Web and Mock implementations.
abstract class LeafletController {
  void initMap({double lat = 1.3521, double lng = 103.8198, int zoom = 12});
  void clearAll();
  void drawRoute(
    List<LatLng> coords, {
    String color = '#009645',
    int weight = 6,
    String? dashArray,
    double opacity = 0.85,
  });
  void drawAffectedSegment(List<LatLng> coords, String warningText);
  void drawAlternativeRoute(
    List<LatLng> coords, {
    String color = '#0284C7',
    String? label,
  });
  void drawShelteredWalkways(List<List<LatLng>> segments);
  void setStationMarkers(List<MapStationMarker> stations);
  void fitBounds(List<LatLng> coords);
}
