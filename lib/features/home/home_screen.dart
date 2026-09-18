import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/debug/debug_overlay_panel.dart';
import '../../core/map/leaflet_map_view.dart';
import '../../core/models/route_plan.dart';
import '../../core/models/user_profile.dart';
import '../../core/services/natural_language_route_service.dart';
import '../../core/services/weather_service.dart';
import 'widgets/commuter_account_sheet.dart';
import 'widgets/home_brand_header.dart';
import 'widgets/map_touch_controls.dart';
import 'widgets/route_preview_sheet.dart';
import 'widgets/route_search_bar.dart';
import 'widgets/weather_forecast_bar.dart';

/// Home Screen: Orchestrates live Leaflet map with natural language routing,
/// real-time weather forecast, and debug simulation harness.
class HomeScreen extends StatefulWidget {
  final LeafletMapController? mapController;
  final ValueChanged<ParsedJourneyResult>? onNavigateToJourney;

  const HomeScreen({super.key, this.mapController, this.onNavigateToJourney});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final LeafletMapController _mapController;
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  final NaturalLanguageRouteService _routeService =
      NaturalLanguageRouteService();
  final WeatherService _weatherService = WeatherService();

  WeatherForecastResult? _weatherForecast;
  bool _isLoadingWeather = true;

  ParsedJourneyResult? _lastPlannedResult;
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
      final result = await _routeService.interpretAndPlanRoute(
        query,
        customPreferences: _currentProfile.preferences,
      );
      if (mounted) {
        setState(() {
          _lastPlannedResult = result;
          _isPlanningRoute = false;
        });

        // Render planned route on Leaflet Map
        _renderRouteOnMap(result.routePlan);

        // Notify parent if journey listener attached (for future Journey Page navigation)
        widget.onNavigateToJourney?.call(result);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isPlanningRoute = false);
      }
    }
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
        (_lastPlannedResult != null ? 420.0 : 210.0) + bottomPadding;

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
          ] else if (_lastPlannedResult != null) ...[
            const SizedBox(height: 12),
            RoutePreviewSheet(
              result: _lastPlannedResult!,
              onDismiss: () {
                setState(() {
                  _lastPlannedResult = null;
                  _mapController.clearLayers();
                });
              },
              onToggleRouteDisplay: (showAlternative) {
                _renderRouteOnMap(
                  _lastPlannedResult!.routePlan,
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
