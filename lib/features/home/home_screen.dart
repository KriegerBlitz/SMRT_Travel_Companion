import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/debug/debug_overlay_panel.dart';
import '../../core/map/leaflet_map_view.dart';
import '../../core/models/crowd_density.dart';
import '../../core/models/disruption_alert.dart';
import '../../core/models/route_plan.dart';
import '../../core/models/user_profile.dart';
import '../../core/services/lta_service.dart';
import '../../core/services/onemap_service.dart';
import '../../core/services/weather_service.dart';
import '../../core/transit/canonical_line_table.dart';
import 'widgets/commuter_account_sheet.dart';
import 'widgets/home_brand_header.dart';
import 'widgets/map_touch_controls.dart';
import 'widgets/route_preview_sheet.dart';
import 'widgets/route_search_bar.dart';
import 'widgets/weather_forecast_bar.dart';

/// Home Screen: Orchestrates live Leaflet map with direct OneMap door-to-door
/// routing, LTA DataMall disruption alerts & crowd density, and real-time weather forecast.
class HomeScreen extends StatefulWidget {
  final LeafletMapController? mapController;
  final ValueChanged<RoutePlan>? onRoutePlanned;

  const HomeScreen({super.key, this.mapController, this.onRoutePlanned});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final LeafletMapController _mapController;
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  final OneMapService _oneMapService = OneMapService();
  final LtaDataMallService _ltaService = LtaDataMallService();
  final WeatherService _weatherService = WeatherService();

  WeatherForecastResult? _weatherForecast;
  bool _isLoadingWeather = true;

  RoutePlan? _lastPlannedRoute;
  bool _isWheelchairRoute = false;
  bool _isPlanningRoute = false;
  UserProfile _currentProfile = UserProfile.general;

  late final AnimationController _entranceController;
  late final Animation<Offset> _bottomPanelSlideAnimation;
  late final Animation<double> _bottomPanelFadeAnimation;
  late final Animation<Offset> _controlsSlideAnimation;

  @override
  void initState() {
    super.initState();
    _mapController = widget.mapController ?? LeafletMapController();
    _mapController.setStationSelectionListener((name, role) {
      if (!mounted) return;
      setState(() {
        final currentText = _textController.text.trim();
        if (role == 'origin') {
          if (currentText.contains(' to ')) {
            final parts = currentText.split(' to ');
            _textController.text = '$name to ${parts[1]}';
          } else {
            _textController.text =
                '$name to ${_currentProfile.defaultDestination}';
          }
        } else {
          if (currentText.contains(' to ')) {
            final parts = currentText.split(' to ');
            _textController.text = '${parts[0]} to $name';
          } else {
            _textController.text = '${_currentProfile.defaultOrigin} to $name';
          }
        }
      });
      _handlePlanRoute();
    });
    _textController = TextEditingController();
    _focusNode = FocusNode();

    // Entrance animation for slick transition from Landing Page
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _bottomPanelSlideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.4), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );

    _bottomPanelFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    _controlsSlideAnimation =
        Tween<Offset>(begin: const Offset(0.5, 0.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );

    _entranceController.forward();
    _loadWeatherNowcast();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadWeatherNowcast() async {
    setState(() => _isLoadingWeather = true);
    try {
      final weather = await _weatherService.checkRainNowcast(area: 'Central');
      if (mounted) {
        setState(() {
          _weatherForecast = weather;
          _isLoadingWeather = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingWeather = false);
      }
    }
  }

  Future<void> _handlePlanRoute([String? overrideQuery]) async {
    var query = (overrideQuery ?? _textController.text).trim();
    if (query.isEmpty) {
      query = _currentProfile.id == 'general'
          ? 'Bugis to Harborfront on Wheelchair'
          : '${_currentProfile.defaultOrigin} to ${_currentProfile.defaultDestination}';
      _textController.text = query;
    }

    _focusNode.unfocus();
    setState(() {
      _isPlanningRoute = true;
    });

    try {
      final lower = query.toLowerCase().trim();

      // 1. Detect accessibility & weather constraints from query & user profile
      final isWheelchair = lower.contains('wheelchair') ||
          lower.contains('barrier-free') ||
          lower.contains('no stair') ||
          lower.contains('accessibility') ||
          lower.contains('lift') ||
          lower.contains('mdm lim') ||
          lower.contains('senior') ||
          _currentProfile.preferences.requiresWheelchair;

      final preferSheltered = lower.contains('shelter') ||
          lower.contains('rain') ||
          lower.contains('covered') ||
          isWheelchair ||
          _currentProfile.preferences.preferSheltered;

      // 2. Extract origin and destination
      String origin = 'Bugis';
      String destination = 'HarbourFront';

      if (lower.contains(' to ')) {
        final parts = lower.split(' to ');
        var rawOrigin = parts[0].replaceAll('from', '').trim();
        var rawDest = parts[1];

        rawDest = rawDest
            .replaceAll('on wheelchair', '')
            .replaceAll('with wheelchair', '')
            .replaceAll('wheelchair', '')
            .replaceAll('please', '')
            .replaceAll('by mrt', '')
            .replaceAll('fastest route', '')
            .replaceAll('route', '')
            .trim();

        origin = _cleanLocationName(rawOrigin, defaultVal: 'Bugis');
        destination = _cleanLocationName(rawDest, defaultVal: 'HarbourFront');
      } else {
        origin = _cleanLocationName(query, defaultVal: _currentProfile.defaultOrigin);
        destination = _currentProfile.defaultDestination;
      }

      // 3. Resolve Station Coordinates via CanonicalLineTable
      final originStation = CanonicalLineTable.findStationByCodeOrName(origin);
      final destStation = CanonicalLineTable.findStationByCodeOrName(destination);

      final startLat = originStation?.lat ?? 1.3005;
      final startLon = originStation?.lon ?? 103.8558;
      final endLat = destStation?.lat ?? 1.2654;
      final endLon = destStation?.lon ?? 103.8222;

      // 4. Door-to-door transit route from OneMap
      final baseRoute = await _oneMapService.planRoute(
        originName: origin,
        startLat: startLat,
        startLon: startLon,
        destinationName: destination,
        endLat: endLat,
        endLon: endLon,
        preferSheltered: preferSheltered,
      );

      // 5. Query LTA DataMall TrainServiceAlerts for disruptions
      final alert = await _ltaService.getTrainServiceAlerts();

      AffectedSegment? matchedSegment;
      if (alert.isDisrupted) {
        for (final leg in baseRoute.legs) {
          if (leg.mode == 'SUBWAY') {
            for (final seg in alert.affectedSegments) {
              if (seg.line == leg.lineOrService ||
                  (leg.departureStationCode != null &&
                      seg.isStationAffected(leg.departureStationCode!)) ||
                  (leg.arrivalStationCode != null &&
                      seg.isStationAffected(leg.arrivalStationCode!))) {
                matchedSegment = seg;
                break;
              }
            }
          }
          if (matchedSegment != null) break;
        }
        if (matchedSegment == null && alert.affectedSegments.isNotEmpty) {
          final usedLines = baseRoute.transitLinesUsed;
          for (final seg in alert.affectedSegments) {
            if (usedLines.contains(seg.line)) {
              matchedSegment = seg;
              break;
            }
          }
        }
      }

      RoutePlan plannedRoute = baseRoute;

      // Automated route revision when disruption detected — uses real LTA mitigation data
      if (matchedSegment != null) {
        final hasShuttle = matchedSegment.hasMrtShuttle;
        final hasBus = matchedSegment.hasFreeBus;
        final mitigationReason = hasShuttle
            ? '${matchedSegment.line} disruption: Take free MRT shuttle from $origin (+15 min)'
            : (hasBus
                ? '${matchedSegment.line} disruption: Board free bridging bus island-wide (+20 min)'
                : 'Train service suspended on ${matchedSegment.line}: Alternative bus advised');

        final markedOriginalLegs = baseRoute.legs.map((leg) {
          if (leg.mode == 'SUBWAY') {
            return RouteLeg(
              mode: leg.mode,
              lineOrService: leg.lineOrService,
              departureStop: leg.departureStop,
              arrivalStop: leg.arrivalStop,
              durationSeconds: leg.durationSeconds + 1200,
              distanceMeters: leg.distanceMeters,
              coordinates: leg.coordinates,
              isDisrupted: true, // Marked for distinct red dashed display
              instruction: 'SERVICE DISRUPTED: Heavy delays & bridging in effect',
            );
          }
          return leg;
        }).toList();

        final delayedOriginalRoute = RoutePlan(
          id: 'original-delayed-${DateTime.now().millisecondsSinceEpoch}',
          origin: baseRoute.origin,
          destination: baseRoute.destination,
          totalDurationMinutes: baseRoute.totalDurationMinutes + 25,
          totalWalkDistanceMeters: baseRoute.totalWalkDistanceMeters,
          legs: markedOriginalLegs,
          isRerouted: false,
          confidence: ConfidenceLevel.red,
          confidenceReason:
              'Active disruption on line segment. Delays exceeding 25 mins.',
          isSimulated: alert.isSimulated,
        );

        final shuttleCoords = [
          [startLat, startLon],
          [(startLat + endLat) / 2 + 0.008, (startLon + endLon) / 2 - 0.008],
          [endLat, endLon],
        ];

        final mitigationLegs = <RouteLeg>[
          RouteLeg(
            mode: 'WALK',
            departureStop: origin,
            arrivalStop: '$origin Shuttle Bay',
            durationSeconds: 240,
            distanceMeters: 220.0,
            instruction: 'Walk to Free Shuttle Boarding Point',
            coordinates: [[startLat, startLon]],
          ),
          RouteLeg(
            mode: 'SHUTTLE',
            lineOrService: hasShuttle ? 'Free MRT Shuttle' : 'Free Bridging Bus',
            departureStop: '$origin Shuttle Point',
            arrivalStop: '$destination Shuttle Dropoff',
            durationSeconds: (baseRoute.totalDurationMinutes + 12) * 60,
            distanceMeters:
                baseRoute.legs.fold<double>(0, (sum, l) => sum + l.distanceMeters),
            coordinates: shuttleCoords,
            instruction: hasShuttle
                ? 'Board Free MRT Shuttle towards $destination.'
                : 'Board Free Bridging Bus towards $destination.',
          ),
          RouteLeg(
            mode: 'WALK',
            departureStop: '$destination Shuttle Dropoff',
            arrivalStop: destination,
            durationSeconds: 180,
            distanceMeters: 150.0,
            instruction: 'Walk to destination',
            coordinates: [[endLat, endLon]],
          ),
        ];

        plannedRoute = RoutePlan(
          id: 'revised-mitigation-route-${DateTime.now().millisecondsSinceEpoch}',
          origin: baseRoute.origin,
          destination: baseRoute.destination,
          totalDurationMinutes: baseRoute.totalDurationMinutes + 15,
          totalWalkDistanceMeters: 370.0,
          legs: mitigationLegs,
          isRerouted: true,
          rerouteReason: mitigationReason,
          confidence: ConfidenceLevel.amber,
          confidenceReason:
              'Shuttle running at high frequency. +15 min travel time.',
          alternativeRoute: delayedOriginalRoute,
          isSimulated: alert.isSimulated,
        );
      }

      // 6. Query LTA Facilities Maintenance for lift outages (wheelchair barrier-free requirement)
      if (isWheelchair && !plannedRoute.isRerouted) {
        final liftOutages = await _ltaService.getFacilitiesMaintenance();
        if (liftOutages.isNotEmpty) {
          final outage = liftOutages.first;
          final liftReason =
              'Lift outage at ${outage.station} Exit ${outage.exit}. Direct Wheelchair Bus recommended (avoid stairs).';

          final busAlternativeLegs = <RouteLeg>[
            RouteLeg(
              mode: 'WALK',
              departureStop: origin,
              arrivalStop: 'Opp $origin Station Bus Stop',
              durationSeconds: 360,
              distanceMeters: 220.0,
              isSheltered: true,
              instruction: 'Walk via ramp to Bus Stop Opp $origin Station',
              coordinates: [[startLat, startLon]],
            ),
            RouteLeg(
              mode: 'BUS',
              lineOrService: 'Bus 197',
              departureStop: 'Opp $origin Station',
              arrivalStop: 'Opp $destination',
              durationSeconds: (baseRoute.totalDurationMinutes + 10) * 60,
              distanceMeters: 14200.0,
              coordinates: [
                [startLat, startLon],
                [(startLat + endLat) / 2, (startLon + endLon) / 2],
                [endLat, endLon],
              ],
              instruction:
                  'Board Bus 197 (Wheelchair Accessible). Alight right at entrance.',
            ),
            RouteLeg(
              mode: 'WALK',
              departureStop: 'Opp $destination',
              arrivalStop: destination,
              durationSeconds: 180,
              distanceMeters: 100.0,
              isSheltered: true,
              instruction:
                  'Ramp access directly into building — zero stairs, avoids broken lift',
              coordinates: [[endLat, endLon]],
            ),
          ];

          plannedRoute = RoutePlan(
            id: 'accessible-bus-alternative-${DateTime.now().millisecondsSinceEpoch}',
            origin: baseRoute.origin,
            destination: baseRoute.destination,
            totalDurationMinutes: baseRoute.totalDurationMinutes + 10,
            totalWalkDistanceMeters: 320.0,
            legs: busAlternativeLegs,
            isRerouted: true,
            rerouteReason: liftReason,
            confidence: ConfidenceLevel.green,
            confidenceReason:
                'Direct wheelchair bus (Seats Available, WAB). Zero stairs or lifts required.',
            hasRainRisk: _weatherForecast?.isRainingOrImminent ?? false,
            usesShelteredWalkways: true,
            alternativeRoute: baseRoute,
            isSimulated: true,
          );
        }
      }

      // 7. Query LTA Station Crowd Density
      final stationCrowds = <String, CrowdLevel>{};
      bool hasCrowdSpike = false;

      final linesToCheck = plannedRoute.transitLinesUsed.isNotEmpty
          ? plannedRoute.transitLinesUsed
          : ['EWL', 'NSL', 'DTL', 'NEL'];

      for (final line in linesToCheck) {
        final crowdList = await _ltaService.getStationCrowdRealTime(line);
        for (final sc in crowdList) {
          stationCrowds[sc.stationCode] = sc.crowdLevel;
          if (sc.crowdLevel == CrowdLevel.high) {
            hasCrowdSpike = true;
          }
        }
      }

      // 8. Confidence Band on ETA: Never a single fake-precise number
      ConfidenceLevel confidence = plannedRoute.confidence;
      String confidenceReason = plannedRoute.confidenceReason;

      if (matchedSegment != null) {
        confidence = ConfidenceLevel.amber;
        confidenceReason = hasCrowdSpike
            ? 'Crowd rising at transfer hub + 1 active alert'
            : 'Active disruption on line; shuttle bridging in effect';
      } else if (hasCrowdSpike) {
        confidence = ConfidenceLevel.amber;
        confidenceReason =
            'Platform crowd rising at interchange station (+5–8 min delay risk)';
      } else if (!plannedRoute.isRerouted) {
        confidence = ConfidenceLevel.green;
        confidenceReason = 'Normal operations, stable crowd levels across route';
      }

      final finalPlan = plannedRoute.copyWith(
        stationCrowds: stationCrowds,
        confidence: confidence,
        confidenceReason: confidenceReason,
        hasRainRisk: _weatherForecast?.isRainingOrImminent ?? false,
        usesShelteredWalkways:
            preferSheltered || plannedRoute.usesShelteredWalkways,
      );

      if (mounted) {
        setState(() {
          _lastPlannedRoute = finalPlan;
          _isWheelchairRoute = isWheelchair;
          _isPlanningRoute = false;
        });

        // Render planned route on Leaflet Map
        _renderRouteOnMap(finalPlan);

        widget.onRoutePlanned?.call(finalPlan);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isPlanningRoute = false);
      }
    }
  }

  String _cleanLocationName(String input, {required String defaultVal}) {
    if (input.isEmpty) return defaultVal;
    final clean = input.toLowerCase();
    if (clean.contains('harbor') || clean.contains('harbour')) return 'HarbourFront';
    if (clean.contains('bugis')) return 'Bugis';
    if (clean.contains('tampines')) return 'Tampines';
    if (clean.contains('raffles')) return 'Raffles Place';
    if (clean.contains('bedok')) return 'Bedok';
    if (clean.contains('outram')) return 'Outram Park';
    if (clean.contains('sgh') || clean.contains('hospital')) {
      return 'Singapore General Hospital';
    }
    return input[0].toUpperCase() + input.substring(1);
  }

  void _renderRouteOnMap(RoutePlan plan, {bool showAlternative = false}) {
    if (showAlternative && plan.alternativeRoute != null) {
      _mapController.renderRoute(
        unaffectedCoords: plan.alternativeRoute!.unaffectedCoordinates,
        affectedCoords: plan.alternativeRoute!.affectedCoordinates,
        alternativeCoords: plan.unaffectedCoordinates,
      );

      final altSheltered = plan.alternativeRoute!.shelteredCoordinates;
      if (altSheltered.isNotEmpty) {
        _mapController.renderShelteredWalkway(altSheltered);
      }
    } else if (plan.unaffectedCoordinates.isNotEmpty ||
        plan.affectedCoordinates.isNotEmpty) {
      _mapController.renderRoute(
        unaffectedCoords: plan.unaffectedCoordinates,
        affectedCoords: plan.affectedCoordinates,
        alternativeCoords:
            plan.alternativeRoute?.unaffectedCoordinates ?? const [],
      );

      // Sheltered walkways if wheelchair / rain
      if (plan.shelteredCoordinates.isNotEmpty) {
        _mapController.renderShelteredWalkway(plan.shelteredCoordinates);
      }
    }

    // Render station crowd indicators on Leaflet map
    if (plan.stationCrowds.isNotEmpty) {
      _mapController.renderStationCrowds(plan.stationCrowds);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final controlsBottom =
        (_lastPlannedRoute != null ? 420.0 : 210.0) + bottomPadding;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Live Singapore Leaflet Map (Interactive & Unblurred)
          Positioned.fill(
            child: LeafletMapView(
              initialLat: 1.3521,
              initialLng: 103.8198,
              initialZoom: 12.5,
              isBlurred: false,
              controller: _mapController,
            ),
          ),

          // 2. Top Floating Brand Header
          const HomeBrandHeader(),

          // 2b. Sleek Top-Right Commuter Account & Preferences Button
          Positioned(
            top: 14,
            right: 16,
            child: SafeArea(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    CommuterAccountSheet.show(
                      context,
                      currentProfile: _currentProfile,
                      onProfileChanged: (profile) {
                        setState(() {
                          _currentProfile = profile;
                        });
                        _handlePlanRoute(
                          '${profile.defaultOrigin} to ${profile.defaultDestination}',
                        );
                      },
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.90),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentProfile.badge,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _currentProfile.id == 'general'
                              ? 'Profile'
                              : _currentProfile.name,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.tune_rounded,
                          size: 13,
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 3. Debug Overlay Panel (Only visible when unlocked via Konami Code)
          const DebugOverlayPanel(),

          // 4. Floating Touch Controls on Map (Zoom In, Zoom Out, Recenter)
          // Positioned near the bottom container, smoothly adapting when routes expand
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            right: 16,
            bottom: controlsBottom,
            child: SlideTransition(
              position: _controlsSlideAnimation,
              child: FadeTransition(
                opacity: _bottomPanelFadeAnimation,
                child: MapTouchControls(
                  onZoomIn: _mapController.zoomIn,
                  onZoomOut: _mapController.zoomOut,
                  onRecenter: () =>
                      _mapController.setView(1.3521, 103.8198, 12.0),
                ),
              ),
            ),
          ),

          // 5. Bottom Search Container with Text Input & Weather Forecast
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SlideTransition(
              position: _bottomPanelSlideAnimation,
              child: FadeTransition(
                opacity: _bottomPanelFadeAnimation,
                child: _buildBottomSearchSheet(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSearchSheet(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomPadding),
      decoration: BoxDecoration(
        color: const Color(0xF80B0F19),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1.2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.75),
            blurRadius: 30,
            spreadRadius: 5,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Subtle grab handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Text Entry Field: [placeholder [->]] with white gradient arrow button
          RouteSearchBar(
            controller: _textController,
            focusNode: _focusNode,
            placeholder: 'Bugis to Harborfront on Wheelchair',
            onSubmitted: (val) => _handlePlanRoute(val),
            onPlanPressed: () => _handlePlanRoute(),
            onSuggestionSelected: (query) => _handlePlanRoute(query),
          ),

          const SizedBox(height: 10),

          // Weather Forecast with Emoji (Directly below text box)
          WeatherForecastBar(
            weather: _weatherForecast,
            isLoading: _isLoadingWeather,
          ),

          // Interpreted Route Preview Card (Displays after submit / planning)
          if (_isPlanningRoute) ...[
            const SizedBox(height: 12),
            _buildPlanningLoader(),
          ] else if (_lastPlannedRoute != null) ...[
            const SizedBox(height: 12),
            RoutePreviewSheet(
              plan: _lastPlannedRoute!,
              isWheelchairAccessible: _isWheelchairRoute,
              onDismiss: () {
                setState(() {
                  _lastPlannedRoute = null;
                  _mapController.clearLayers();
                });
              },
              onToggleRouteDisplay: (showAlternative) {
                _renderRouteOnMap(
                  _lastPlannedRoute!,
                  showAlternative: showAlternative,
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanningLoader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF131A26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Interpreting query & calculating door-to-door ETA...',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
