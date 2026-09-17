import 'package:flutter/material.dart';
import 'leaflet_controller.dart';

class LeafletMapWidget extends StatefulWidget {
  final void Function(LeafletController controller)? onMapReady;
  final double height;

  const LeafletMapWidget({
    super.key,
    this.onMapReady,
    this.height = 350,
  });

  @override
  State<LeafletMapWidget> createState() => _LeafletMapWidgetState();
}

class _LeafletMapWidgetState extends State<LeafletMapWidget>
    implements LeafletController {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onMapReady?.call(this);
    });
  }

  @override
  void initMap({double lat = 1.3521, double lng = 103.8198, int zoom = 12}) {}

  @override
  void clearAll() {}

  @override
  void drawRoute(
    List<LatLng> coords, {
    String color = '#009645',
    int weight = 6,
    String? dashArray,
    double opacity = 0.85,
  }) {}

  @override
  void drawAffectedSegment(List<LatLng> coords, String warningText) {}

  @override
  void drawAlternativeRoute(
    List<LatLng> coords, {
    String color = '#0284C7',
    String? label,
  }) {}

  @override
  void drawShelteredWalkways(List<List<LatLng>> segments) {}

  @override
  void setStationMarkers(List<MapStationMarker> stations) {}

  @override
  void fitBounds(List<LatLng> coords) {}

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      color: Colors.grey.shade900,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, color: Colors.white70, size: 48),
            SizedBox(height: 8),
            Text(
              'Leaflet Map (Web Only)',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 4),
            Text(
              '© OpenStreetMap contributors',
              style: TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
