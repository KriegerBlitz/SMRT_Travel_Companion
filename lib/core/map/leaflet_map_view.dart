import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'leaflet_stub_impl.dart'
    if (dart.library.js_interop) 'leaflet_web_impl.dart' as platform;

/// Controller to interact with the embedded Leaflet map instance.
class LeafletMapController {
  String? _containerId;

  bool get isReady => _containerId != null;

  void attachContainer(String id) {
    _containerId = id;
  }

  /// Sets map center coordinate and zoom
  void setView(double lat, double lng, [double zoom = 13.0]) {
    final id = _containerId;
    if (id == null || !kIsWeb) return;
    try {
      platform.bridgeSetView(id, lat, lng, zoom);
    } catch (_) {}
  }

  /// Zooms in by 1 level
  void zoomIn() {
    final id = _containerId;
    if (id == null || !kIsWeb) return;
    try {
      platform.bridgeZoomIn(id);
    } catch (_) {}
  }

  /// Zooms out by 1 level
  void zoomOut() {
    final id = _containerId;
    if (id == null || !kIsWeb) return;
    try {
      platform.bridgeZoomOut(id);
    } catch (_) {}
  }

  /// Clears dynamic markers, routes, and overlays
  void clearLayers() {
    final id = _containerId;
    if (id == null || !kIsWeb) return;
    try {
      platform.bridgeClearLayers(id);
    } catch (_) {}
  }

  /// Renders a route on Leaflet, distinguishing unaffected, affected, and alternative paths
  void renderRoute({
    required List<List<double>> unaffectedCoords,
    List<List<double>> affectedCoords = const [],
    List<List<double>> alternativeCoords = const [],
  }) {
    final id = _containerId;
    if (id == null || !kIsWeb) return;
    try {
      // Convert to JS objects or pass through bridge
      final unaffectedJson = jsonEncode(unaffectedCoords);
      final affectedJson = jsonEncode(affectedCoords);
      final altJson = jsonEncode(alternativeCoords);

      // Call bridge
      _evalRouteBridge(id, unaffectedJson, affectedJson, altJson);
    } catch (_) {}
  }

  /// Renders station markers with crowd dots (Low/Moderate/High)
  void renderStations(List<Map<String, dynamic>> stations) {
    final id = _containerId;
    if (id == null || !kIsWeb) return;
    try {
      final jsonStr = jsonEncode(stations);
      _evalStationsBridge(id, jsonStr);
    } catch (_) {}
  }

  /// Renders sheltered walkway segments (CoveredLinkWay)
  void renderShelteredWalkway(List<List<double>> coords) {
    final id = _containerId;
    if (id == null || !kIsWeb) return;
    try {
      final jsonStr = jsonEncode(coords);
      _evalShelteredBridge(id, jsonStr);
    } catch (_) {}
  }

  /// Renders station crowd indicators (Green/Amber/Red rings)
  void renderStationCrowds(Map<String, dynamic> crowds) {
    final id = _containerId;
    if (id == null || !kIsWeb) return;
    try {
      final mapped = crowds.map((k, v) => MapEntry(k, v is Enum ? v.name : v.toString()));
      final jsonStr = jsonEncode(mapped);
      platform.runJsSnippet('if (window.MRTLeafletBridge && window.MRTLeafletBridge.renderStationCrowds) window.MRTLeafletBridge.renderStationCrowds("$id", $jsonStr);');
    } catch (_) {}
  }

  void invalidateSize() {
    final id = _containerId;
    if (id == null || !kIsWeb) return;
    try {
      platform.bridgeInvalidateSize(id);
    } catch (_) {}
  }

  /// Toggles map blur (useful for landing screen background)
  void setBlurred(bool blurred) {
    final id = _containerId;
    if (id == null || !kIsWeb) return;
    try {
      platform.bridgeSetBlurred(id, blurred);
    } catch (_) {}
  }

  /// Listens to station selection actions from the Leaflet map popups
  void setStationSelectionListener(void Function(String name, String role) callback) {
    if (!kIsWeb) return;
    try {
      platform.registerStationSelectionCallback(callback);
    } catch (_) {}
  }
}

// JS interop bridge helpers
void _evalRouteBridge(String id, String uJson, String aJson, String altJson) {
  if (kIsWeb) {
    _callGlobalBridge('renderRouteJson', [id, uJson, aJson, altJson]);
  }
}

void _evalStationsBridge(String id, String stnsJson) {
  if (kIsWeb) {
    _callGlobalBridge('renderStationsJson', [id, stnsJson]);
  }
}

void _evalShelteredBridge(String id, String coordsJson) {
  if (kIsWeb) {
    _callGlobalBridge('renderShelteredJson', [id, coordsJson]);
  }
}

void _callGlobalBridge(String method, List<dynamic> args) {
  // Safe helper calling into window.MRTLeafletBridge
  try {
    if (kIsWeb) {
      // BUG FIX: Previously, JSON strings were interpolated raw into a JS
      // single-quoted string literal (e.g. JSON.parse('${args[1]}')).
      // A station name or label containing a single quote (e.g. "Tampines Av 1'")
      // would break the JS syntax and the route/station render would silently fail.
      // Fix: escape single quotes in all JSON args before interpolation.
      String escJs(dynamic s) => s.toString().replaceAll("'", r"\'");

      final script = '''
        (function() {
          if (!window.MRTLeafletBridge) return;
          if ('$method' === 'renderRouteJson') {
            window.MRTLeafletBridge.renderRoute(
              '${escJs(args[0])}',
              JSON.parse('${escJs(args[1])}'),
              JSON.parse('${escJs(args[2])}'),
              JSON.parse('${escJs(args[3])}')
            );
          } else if ('$method' === 'renderStationsJson') {
            window.MRTLeafletBridge.renderStations(
              '${escJs(args[0])}',
              JSON.parse('${escJs(args[1])}')
            );
          } else if ('$method' === 'renderShelteredJson') {
            window.MRTLeafletBridge.renderShelteredWalkway(
              '${escJs(args[0])}',
              JSON.parse('${escJs(args[1])}')
            );
          }
        })();
      ''';
      // In web, dynamic script evaluation
      _runInlineJs(script);
    }
  } catch (_) {}
}

void _runInlineJs(String code) {
  // Uses web.document to safely inject bridge invocation
  if (kIsWeb) {
    _webInjectScript(code);
  }
}

void _webInjectScript(String code) {
  // Implemented safely in web environment
  try {
    platform.runJsSnippet(code);
  } catch (_) {}
}

/// A Leaflet OpenStreetMap View embedded via HtmlElementView in Flutter Web.
///
/// Ensures strict compliance with OpenStreetMap attribution guidelines
/// ('© OpenStreetMap contributors').
class LeafletMapView extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final double initialZoom;
  final bool isBlurred;
  final LeafletMapController? controller;
  final VoidCallback? onMapReady;

  const LeafletMapView({
    super.key,
    this.initialLat = 1.3521,
    this.initialLng = 103.8198,
    this.initialZoom = 12.0,
    this.isBlurred = false,
    this.controller,
    this.onMapReady,
  });

  @override
  State<LeafletMapView> createState() => _LeafletMapViewState();
}

class _LeafletMapViewState extends State<LeafletMapView> {
  late final LeafletMapController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? LeafletMapController();
  }

  @override
  void didUpdateWidget(covariant LeafletMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isBlurred != widget.isBlurred) {
      _controller.setBlurred(widget.isBlurred);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: platform.LeafletPlatformMap(
            initialLat: widget.initialLat,
            initialLng: widget.initialLng,
            initialZoom: widget.initialZoom,
            onMapCreated: (containerId) {
              _controller.attachContainer(containerId);
              if (widget.isBlurred) {
                _controller.setBlurred(true);
              }
              widget.onMapReady?.call();
            },
          ),
        ),
        // Permanent OSM attribution badge overlay (Hard requirement of PS2 brief)
        Positioned(
          bottom: 4,
          right: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                ),
              ],
            ),
            child: const Text(
              '© OpenStreetMap contributors',
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFF374151),
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
