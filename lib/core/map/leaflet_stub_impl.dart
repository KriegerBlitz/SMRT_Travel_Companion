import 'package:flutter/material.dart';

class LeafletPlatformMap extends StatelessWidget {
  final double initialLat;
  final double initialLng;
  final double initialZoom;
  final Function(String containerId)? onMapCreated;

  const LeafletPlatformMap({
    super.key,
    this.initialLat = 1.3521,
    this.initialLng = 103.8198,
    this.initialZoom = 12.0,
    this.onMapCreated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blueGrey.shade100,
      child: Center(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined, size: 36, color: Colors.blueGrey),
              const SizedBox(height: 6),
              Text(
                'OpenStreetMap (Leaflet Web View)',
                style: TextStyle(
                  color: Colors.blueGrey.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '© OpenStreetMap contributors',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void bridgeSetView(String id, double lat, double lng, double? zoom) {}
void bridgeZoomIn(String id) {}
void bridgeZoomOut(String id) {}
void bridgeClearLayers(String id) {}
void bridgeInvalidateSize(String id) {}
void bridgeSetBlurred(String id, bool blurred) {}
void runJsSnippet(String code) {}
void registerStationSelectionCallback(void Function(String name, String role) callback) {}
