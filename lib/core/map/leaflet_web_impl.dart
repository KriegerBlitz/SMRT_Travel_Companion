import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

@JS('MRTLeafletBridge')
external MRTLeafletBridgeJS? get mrtLeafletBridge;

@JS()
@staticInterop
class MRTLeafletBridgeJS {}

extension MRTLeafletBridgeJSExtension on MRTLeafletBridgeJS {
  external bool initMap(String containerId, double lat, double lng, double zoom);
  external void setView(String containerId, double lat, double lng, double? zoom);
  external void zoomIn(String containerId);
  external void zoomOut(String containerId);
  external void clearLayers(String containerId);
  external void renderRoute(
    String containerId,
    JSAny? unaffectedCoords,
    JSAny? affectedCoords,
    JSAny? alternativeCoords,
  );
  external void renderStations(String containerId, JSAny? stations);
  external void renderShelteredWalkway(String containerId, JSAny? coords);
  external void invalidateSize(String containerId);
  external void setBlurred(String containerId, bool blurred);
  external set onStationSelect(JSFunction? fn);
}

class LeafletPlatformMap extends StatefulWidget {
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
  State<LeafletPlatformMap> createState() => _LeafletPlatformMapState();
}

class _LeafletPlatformMapState extends State<LeafletPlatformMap> {
  static int _nextId = 0;
  late final String _containerId;
  late final String _viewType;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    final id = _nextId++;
    _containerId = 'leaflet-map-$id';
    _viewType = 'leaflet-map-view-$id';

    // Register HtmlElementView factory in web
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId, {Object? params}) {
      final element = web.document.createElement('div') as web.HTMLDivElement;
      element.id = _containerId;
      element.style.width = '100%';
      element.style.height = '100%';
      element.style.margin = '0';
      element.style.padding = '0';
      element.style.position = 'relative';
      element.style.zIndex = '0';
      return element;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initMapWithRetry();
    });
  }

  void _initMapWithRetry([int attempt = 0]) {
    if (!mounted || _initialized) return;

    final bridge = mrtLeafletBridge;
    if (bridge != null) {
      final ok = bridge.initMap(
        _containerId,
        widget.initialLat,
        widget.initialLng,
        widget.initialZoom,
      );
      if (ok) {
        _initialized = true;
        widget.onMapCreated?.call(_containerId);
        return;
      }
    }

    if (attempt < 10) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _initMapWithRetry(attempt + 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}

void bridgeSetView(String id, double lat, double lng, double? zoom) {
  mrtLeafletBridge?.setView(id, lat, lng, zoom);
}

void bridgeZoomIn(String id) {
  mrtLeafletBridge?.zoomIn(id);
}

void bridgeZoomOut(String id) {
  mrtLeafletBridge?.zoomOut(id);
}

void bridgeClearLayers(String id) {
  mrtLeafletBridge?.clearLayers(id);
}

void bridgeInvalidateSize(String id) {
  mrtLeafletBridge?.invalidateSize(id);
}

void bridgeSetBlurred(String id, bool blurred) {
  mrtLeafletBridge?.setBlurred(id, blurred);
}

void runJsSnippet(String code) {
  final scriptEl = web.document.createElement('script') as web.HTMLScriptElement;
  scriptEl.text = code;
  web.document.body?.appendChild(scriptEl);
  scriptEl.remove();
}

void registerStationSelectionCallback(void Function(String name, String role) callback) {
  final bridge = mrtLeafletBridge;
  if (bridge != null) {
    bridge.onStationSelect = ((JSString name, JSString role) {
      callback(name.toDart, role.toDart);
    }).toJS;
  }
}


