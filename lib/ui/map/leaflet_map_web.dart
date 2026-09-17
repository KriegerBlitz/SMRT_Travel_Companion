import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'leaflet_controller.dart';

@JS('leafletBridge.initMap')
external void _initMapJS(String elementId, double lat, double lng, int zoom);

@JS('leafletBridge.clearAll')
external void _clearAllJS();

@JS('leafletBridge.drawRoute')
external void _drawRouteJS(
    JSAny coords, String? color, int? weight, String? dashArray, double? opacity);

@JS('leafletBridge.drawAffectedSegment')
external void _drawAffectedSegmentJS(JSAny coords, String? warningText);

@JS('leafletBridge.drawAlternativeRoute')
external void _drawAlternativeRouteJS(JSAny coords, String? color, String? label);

@JS('leafletBridge.drawShelteredWalkways')
external void _drawShelteredWalkwaysJS(JSAny segments);

@JS('leafletBridge.setStationMarkers')
external void _setStationMarkersJS(JSAny stations);

@JS('leafletBridge.fitBounds')
external void _fitBoundsJS(JSAny coords);

@JS('JSON.parse')
external JSAny _jsonParse(String json);

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
  static int _viewIdCounter = 0;
  late final String _elementId;
  bool _isMapInitialized = false;

  @override
  void initState() {
    super.initState();
    _viewIdCounter++;
    _elementId = 'leaflet_map_view_$_viewIdCounter';

    // Register web platform view for the Leaflet DOM element
    ui_web.platformViewRegistry.registerViewFactory(
      _elementId,
      (int viewId) {
        final div = web.document.createElement('div') as web.HTMLDivElement;
        div.id = _elementId;
        div.style.width = '100%';
        div.style.height = '100%';
        div.style.backgroundColor = '#1e293b';
        return div;
      },
    );

    // Initialize Leaflet map after the DOM element is attached
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          initMap();
          widget.onMapReady?.call(this);
        }
      });
    });
  }

  @override
  void initMap({double lat = 1.3521, double lng = 103.8198, int zoom = 12}) {
    if (_isMapInitialized) return;
    try {
      _initMapJS(_elementId, lat, lng, zoom);
      _isMapInitialized = true;
    } catch (e) {
      debugPrint('Error in initMap: $e');
    }
  }

  @override
  void clearAll() {
    try {
      _clearAllJS();
    } catch (e) {
      debugPrint('Error in clearAll: $e');
    }
  }

  @override
  void drawRoute(
    List<LatLng> coords, {
    String color = '#009645',
    int weight = 6,
    String? dashArray,
    double opacity = 0.85,
  }) {
    try {
      final rawList = coords.map((c) => [c.lat, c.lng]).toList();
      final jsonStr = jsonEncode(rawList);
      _drawRouteJS(_jsonParse(jsonStr), color, weight, dashArray, opacity);
    } catch (e) {
      debugPrint('Error in drawRoute: $e');
    }
  }

  @override
  void drawAffectedSegment(List<LatLng> coords, String warningText) {
    try {
      final rawList = coords.map((c) => [c.lat, c.lng]).toList();
      final jsonStr = jsonEncode(rawList);
      _drawAffectedSegmentJS(_jsonParse(jsonStr), warningText);
    } catch (e) {
      debugPrint('Error in drawAffectedSegment: $e');
    }
  }

  @override
  void drawAlternativeRoute(
    List<LatLng> coords, {
    String color = '#0284C7',
    String? label,
  }) {
    try {
      final rawList = coords.map((c) => [c.lat, c.lng]).toList();
      final jsonStr = jsonEncode(rawList);
      _drawAlternativeRouteJS(_jsonParse(jsonStr), color, label);
    } catch (e) {
      debugPrint('Error in drawAlternativeRoute: $e');
    }
  }

  @override
  void drawShelteredWalkways(List<List<LatLng>> segments) {
    try {
      final rawSegments = segments
          .map((seg) => seg.map((c) => [c.lat, c.lng]).toList())
          .toList();
      final jsonStr = jsonEncode(rawSegments);
      _drawShelteredWalkwaysJS(_jsonParse(jsonStr));
    } catch (e) {
      debugPrint('Error in drawShelteredWalkways: $e');
    }
  }

  @override
  void setStationMarkers(List<MapStationMarker> stations) {
    try {
      final rawList = stations.map((s) => s.toJson()).toList();
      final jsonStr = jsonEncode(rawList);
      _setStationMarkersJS(_jsonParse(jsonStr));
    } catch (e) {
      debugPrint('Error in setStationMarkers: $e');
    }
  }

  @override
  void fitBounds(List<LatLng> coords) {
    if (coords.isEmpty) return;
    try {
      final rawList = coords.map((c) => [c.lat, c.lng]).toList();
      final jsonStr = jsonEncode(rawList);
      _fitBoundsJS(_jsonParse(jsonStr));
    } catch (e) {
      debugPrint('Error in fitBounds: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        children: [
          HtmlElementView(viewType: _elementId),
          // Hard licence requirement: Persistent attribution badge
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '© OpenStreetMap contributors',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
