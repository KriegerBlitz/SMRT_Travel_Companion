import 'package:flutter/material.dart';
import '../services/simulator_service.dart';
import '../services/lta_models.dart';
import 'theme.dart';

import 'map/leaflet_map_view.dart';
import '../core/canonical_line_codes.dart';
import '../services/onemap_service.dart';

class RouteMapScreen extends StatefulWidget {
  final SimulatorService simulator;
  final VoidCallback? onBack;

  const RouteMapScreen({
    super.key,
    required this.simulator,
    this.onBack,
  });

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> {
  bool _useInteractiveLeaflet = false;

  void _setupLeafletMap(LeafletController controller) {
    final route = OneMapService.buildRachelRoute(
      isDisrupted: widget.simulator.forceDisruption,
      crowdSpike: widget.simulator.forceCrowdForecastSpike,
    );

    // Draw main route polyline
    controller.drawRoute(
      route.allCoordinates,
      color: '#7C3AED',
      weight: 5,
    );

    if (widget.simulator.forceDisruption) {
      controller.drawAlternativeRoute(
        route.legs.length > 1 ? route.legs[1].pathCoordinates : route.allCoordinates,
        color: '#F59E0B',
        label: 'Alternative Shuttle Bus',
      );
    }

    // Set markers for all canonical stations
    final markers = CanonicalLineCodes.stations.map((stn) {
      String crowdStr = 'low';
      if (widget.simulator.forcedCrowdLevel == CrowdLevel.high) {
        crowdStr = 'high';
      } else if (widget.simulator.forcedCrowdLevel == CrowdLevel.moderate) {
        crowdStr = 'moderate';
      }
      return MapStationMarker(
        code: stn.code,
        name: stn.name,
        lineName: stn.primaryLine.displayName,
        lineColor: '#${stn.primaryLine.color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
        lat: stn.lat,
        lng: stn.lng,
        crowd: crowdStr,
      );
    }).toList();

    controller.setStationMarkers(markers);
    controller.fitBounds(route.allCoordinates);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Back Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (widget.onBack != null)
                          InkWell(
                            onTap: widget.onBack,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.cardBg,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.cardBorder),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: AppTheme.textPrimary,
                                size: 16,
                              ),
                            ),
                          ),
                        if (widget.onBack != null) const SizedBox(width: 14),
                        const Flexible(
                          child: Text(
                            'Route map',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Map Mode Toggle
                  InkWell(
                    onTap: () {
                      setState(() {
                        _useInteractiveLeaflet = !_useInteractiveLeaflet;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _useInteractiveLeaflet ? AppTheme.purplePillBg : AppTheme.cardBgSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _useInteractiveLeaflet ? AppTheme.purplePrimary : AppTheme.cardBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _useInteractiveLeaflet ? Icons.layers_rounded : Icons.map_outlined,
                            size: 14,
                            color: _useInteractiveLeaflet ? AppTheme.purpleLight : AppTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _useInteractiveLeaflet ? 'Interactive Map' : 'Schematic View',
                            style: TextStyle(
                              color: _useInteractiveLeaflet ? Colors.white : AppTheme.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Map Container: either LeafletMapWidget or Schematic Canvas
              Container(
                width: double.infinity,
                height: 360,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EFEA), // OpenStreetMap light canvas tone
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                clipBehavior: Clip.antiAlias,
                child: _useInteractiveLeaflet
                    ? LeafletMapWidget(
                        height: 360,
                        onMapReady: _setupLeafletMap,
                      )
                    : Stack(
                        children: [
                          // Grid & Route Painter
                          CustomPaint(
                            size: const Size(double.infinity, 360),
                            painter: _RouteMapPainter(),
                          ),

                          // OpenStreetMap attribution
                          Positioned(
                            bottom: 8,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '© OpenStreetMap contributors',
                                style: TextStyle(
                                  color: Color(0xFF475569),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 18),

              // Route Duration Rows
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecoration(),
                child: Column(
                  children: [
                    // Original route row
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.purplePrimary.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Original route',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Text(
                          '22 min',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Alternative shuttle bus row
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.amberWarning,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Alternative · shuttle bus',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Text(
                          '37 min',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const Divider(color: AppTheme.cardBorder, height: 28),

                    // Crowd Legend Row
                    Row(
                      children: [
                        _buildCrowdDot(const Color(0xFF10B981), 'Low'),
                        const SizedBox(width: 16),
                        _buildCrowdDot(const Color(0xFFF59E0B), 'Moderate'),
                        const SizedBox(width: 16),
                        _buildCrowdDot(const Color(0xFFEF4444), 'High crowd'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Rain Forecast Advisory Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecoration(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(
                      Icons.grain_rounded, // Rain / precipitation icon
                      color: AppTheme.textSecondary,
                      size: 22,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Rain forecast · sheltered walkway offered for the last leg',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCrowdDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _RouteMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Draw map grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFDFDDD5)
      ..strokeWidth = 1.0;

    const gridSize = 45.0;
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Map building blocks / parcels for realism
    final blockPaint = Paint()
      ..color = const Color(0xFFE5E0D5)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(80, 70, 50, 40),
        const Radius.circular(4),
      ),
      blockPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(210, 160, 60, 45),
        const Radius.circular(4),
      ),
      blockPaint,
    );

    // Coordinate Anchors
    final startPt = Offset(50, size.height - 70);
    final endPt = Offset(size.width - 55, 60);

    // 1. Solid Purple Direct Line
    final purplePaint = Paint()
      ..color = const Color(0xFF5B21B6)
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final directPath = Path();
    directPath.moveTo(startPt.dx, startPt.dy);
    // Slight realistic bezier curve
    directPath.cubicTo(
      110,
      size.height - 130,
      size.width - 150,
      130,
      endPt.dx,
      endPt.dy,
    );
    canvas.drawPath(directPath, purplePaint);

    // 2. Dashed Amber Shuttle Line
    final amberDashPaint = Paint()
      ..color = const Color(0xFFD97706)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final altPath = Path();
    altPath.moveTo(startPt.dx, startPt.dy);
    final p1 = Offset(75, size.height - 130);
    final p2 = Offset(165, size.height - 180);
    final p3 = Offset(265, 120);
    final p4 = Offset(endPt.dx - 20, 100);

    altPath.lineTo(p1.dx, p1.dy);
    altPath.lineTo(p2.dx, p2.dy);
    altPath.lineTo(p3.dx, p3.dy);
    altPath.lineTo(p4.dx, p4.dy);
    altPath.lineTo(endPt.dx, endPt.dy);

    _drawDashedPath(canvas, altPath, amberDashPaint, 8.0, 5.0);

    // 3. Intermediate Station / Crowd Dots on Shuttle Route
    _drawStationNode(canvas, p1, const Color(0xFF10B981)); // Green low crowd
    _drawStationNode(canvas, p2, const Color(0xFFF59E0B)); // Amber moderate crowd
    _drawStationNode(canvas, p3, const Color(0xFFEF4444)); // Red high crowd

    // 4. Origin Dot (Green)
    final greenDot = Paint()..color = const Color(0xFF15803D);
    canvas.drawCircle(startPt, 8, greenDot);
    canvas.drawCircle(
        startPt, 11, Paint()..color = const Color(0xFF15803D).withValues(alpha: 0.3));

    // 5. Destination Dot (Red)
    final redDot = Paint()..color = const Color(0xFFDC2626);
    canvas.drawCircle(endPt, 9, redDot);
    canvas.drawCircle(
        endPt, 13, Paint()..color = const Color(0xFFDC2626).withValues(alpha: 0.3));
  }

  void _drawStationNode(Canvas canvas, Offset offset, Color color) {
    canvas.drawCircle(offset, 6.5, Paint()..color = color);
    canvas.drawCircle(
      offset,
      6.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint,
    double dashWidth,
    double dashSpace,
  ) {
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double len = (distance + dashWidth < metric.length)
            ? dashWidth
            : metric.length - distance;
        final extractPath = metric.extractPath(distance, distance + len);
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
