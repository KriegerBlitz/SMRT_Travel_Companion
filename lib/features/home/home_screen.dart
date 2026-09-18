import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/map/leaflet_map_view.dart';
import '../../core/models/route_plan.dart';
import '../../core/services/natural_language_route_service.dart';
import '../../core/services/weather_service.dart';

/// Home Screen: Interactive Leaflet Map with Natural Language Route Search & Live Weather
class HomeScreen extends StatefulWidget {
  final LeafletMapController? mapController;
  final ValueChanged<ParsedJourneyResult>? onNavigateToJourney;

  const HomeScreen({
    super.key,
    this.mapController,
    this.onNavigateToJourney,
  });

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

  late final AnimationController _entranceController;
  late final Animation<Offset> _bottomPanelSlideAnimation;
  late final Animation<double> _bottomPanelFadeAnimation;
  late final Animation<Offset> _controlsSlideAnimation;

  @override
  void initState() {
    super.initState();
    _mapController = widget.mapController ?? LeafletMapController();
    _textController = TextEditingController(
      text: 'Bugis to Harborfront on Wheelchair',
    );
    _focusNode = FocusNode();

    // Entrance animation for slick transition from Landing Page
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _bottomPanelSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );

    _bottomPanelFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );

    _controlsSlideAnimation = Tween<Offset>(
      begin: const Offset(0.5, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );

    _entranceController.forward();

    // Fetch initial live weather nowcast
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
      final weather =
          await _weatherService.checkRainNowcast(area: 'Central');
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
    final query = (overrideQuery ?? _textController.text).trim();
    if (query.isEmpty) return;

    _focusNode.unfocus();
    setState(() {
      _isPlanningRoute = true;
    });

    try {
      final result = await _routeService.interpretAndPlanRoute(query);
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

  void _renderRouteOnMap(RoutePlan plan) {
    if (plan.unaffectedCoordinates.isNotEmpty ||
        plan.affectedCoordinates.isNotEmpty) {
      _mapController.renderRoute(
        unaffectedCoords: plan.unaffectedCoordinates,
        affectedCoords: plan.affectedCoordinates,
        alternativeCoords: plan.alternativeRoute?.unaffectedCoordinates ?? const [],
      );

      // Sheltered walkways if wheelchair / rain
      if (plan.shelteredCoordinates.isNotEmpty) {
        _mapController.renderShelteredWalkway(plan.shelteredCoordinates);
      }
    }
  }

  void _zoomIn() {
    _mapController.zoomIn();
  }

  void _zoomOut() {
    _mapController.zoomOut();
  }

  void _recenterMap() {
    _mapController.setView(1.3521, 103.8198, 12.0);
  }

  @override
  Widget build(BuildContext context) {
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

          // 2. Top Floating Brand Header & Status Pill
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    // SMRT Companion Brand Badge
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF00D26A),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'SMRT Travel Companion',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Network Live Indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF00D26A).withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wifi_rounded, color: Color(0xFF00D26A), size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: GoogleFonts.jetBrainsMono(
                              color: const Color(0xFF00D26A),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Floating Touch Controls on Map (Zoom In, Zoom Out, Recenter)
          Positioned(
            right: 16,
            top: 100,
            child: SlideTransition(
              position: _controlsSlideAnimation,
              child: FadeTransition(
                opacity: _bottomPanelFadeAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMapTouchButton(
                      icon: Icons.add_rounded,
                      tooltip: 'Zoom in',
                      onTap: _zoomIn,
                    ),
                    const SizedBox(height: 8),
                    _buildMapTouchButton(
                      icon: Icons.remove_rounded,
                      tooltip: 'Zoom out',
                      onTap: _zoomOut,
                    ),
                    const SizedBox(height: 8),
                    _buildMapTouchButton(
                      icon: Icons.my_location_rounded,
                      tooltip: 'Recenter Singapore',
                      onTap: _recenterMap,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Bottom Search Container with Text Input & Weather Forecast
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

  /// Interactive floating map touch button
  Widget _buildMapTouchButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  /// Modern glassmorphic bottom panel with search field and weather forecast
  Widget _buildBottomSearchSheet(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomPadding),
          decoration: BoxDecoration(
            color: const Color(0xFF080C14).withValues(alpha: 0.90),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.18), width: 1.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.7),
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
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title / Tagline
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFF00D26A),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Plan Door-to-Door Journey',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Natural Language',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Text Entry Field with default "Bugis to Harborfront on Wheelchair"
              _buildSearchInputField(),

              const SizedBox(height: 12),

              // Weather Forecast with Emoji (Directly below text box)
              _buildWeatherForecastBar(),

              // Interpreted Route Preview Card (Displays after submit / planning)
              if (_isPlanningRoute) ...[
                const SizedBox(height: 12),
                _buildPlanningLoader(),
              ] else if (_lastPlannedResult != null) ...[
                const SizedBox(height: 12),
                _buildRoutePreviewCard(_lastPlannedResult!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// High-aesthetic natural language search input field
  Widget _buildSearchInputField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131A26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00D26A).withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D26A).withValues(alpha: 0.08),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(
            Icons.search_rounded,
            color: Color(0xFF00D26A),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (value) => _handlePlanRoute(value),
              decoration: InputDecoration(
                hintText: 'Enter route e.g. Bugis to Harborfront on Wheelchair',
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 13,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (_textController.text.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.cancel_rounded,
                color: Colors.white.withValues(alpha: 0.4),
                size: 18,
              ),
              onPressed: () {
                _textController.clear();
                setState(() {});
              },
            ),
          // Action button (Plan Journey)
          Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _handlePlanRoute(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00D26A), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00D26A).withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Plan',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.black,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Live Singapore Weather Forecast Bar with Emoji directly below search box
  Widget _buildWeatherForecastBar() {
    final weather = _weatherForecast;

    if (_isLoadingWeather && weather == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF00D26A),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Fetching Singapore 2-hour nowcast...',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    final emoji = weather?.emoji ?? '⛅';
    final forecastText = weather?.forecast ?? 'Passing Clouds';
    final isRain = weather?.isRainingOrImminent ?? false;
    final isSimulated = weather?.isSimulated ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isRain
            ? const Color(0xFF1E1B4B).withValues(alpha: 0.7) // Rain indigo tone
            : const Color(0xFF0E1726).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRain
              ? const Color(0xFF6366F1).withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          // Weather Emoji
          Text(
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 10),

          // Forecast Text & Location
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        forecastText,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '· 2h Nowcast',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  isRain
                      ? 'Rain imminent in Central area · Sheltered routing recommended'
                      : 'Central Singapore · Dry conditions for outdoor walkways',
                  style: GoogleFonts.plusJakartaSans(
                    color: isRain
                        ? const Color(0xFFA5B4FC)
                        : Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Live / Simulated Compliance Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: isSimulated
                  ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                  : const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSimulated
                    ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                    : const Color(0xFF10B981).withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              isSimulated ? 'SIMULATED' : 'LIVE NOWCAST',
              style: GoogleFonts.jetBrainsMono(
                color: isSimulated ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// AI routing planner loading indicator
  Widget _buildPlanningLoader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF131A26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00D26A).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF00D26A),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Interpreting query & calculating door-to-door ETA...',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF00D26A),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Route interpretation preview card (Ready to transition to Journey Page)
  Widget _buildRoutePreviewCard(ParsedJourneyResult result) {
    final plan = result.routePlan;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF131A26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Origin ➔ Destination and ETA
          Row(
            children: [
              Expanded(
                child: Text(
                  '${result.origin} ➔ ${result.destination}',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D26A).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF00D26A).withValues(alpha: 0.4)),
                ),
                child: Text(
                  '⏱️ ${result.etaDisplay} ETA',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF00D26A),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Accessibility Badge & Weather Risk
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (result.isWheelchairAccessible)
                _buildTag(
                  icon: Icons.accessible_rounded,
                  label: 'Wheelchair / Barrier-Free',
                  color: const Color(0xFF38BDF8),
                ),
              _buildTag(
                icon: Icons.verified_rounded,
                label: plan.confidence.label,
                color: plan.confidence.color,
              ),
              if (plan.usesShelteredWalkways)
                _buildTag(
                  icon: Icons.umbrella_rounded,
                  label: 'Sheltered Walkways',
                  color: const Color(0xFF2DD4BF),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Multi-Modal Transit Legs Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < plan.legs.length; i++) ...[
                  _buildLegChip(plan.legs[i]),
                  if (i < plan.legs.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white.withValues(alpha: 0.35),
                        size: 14,
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Deferral Notice / Hand-off Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white.withValues(alpha: 0.6),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Journey logic planned. Full journey page will be implemented next!',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegChip(RouteLeg leg) {
    final isWalk = leg.mode == 'WALK';
    final line = leg.lineOrService ?? (isWalk ? 'Walk' : 'Transit');
    final color = _getLineColor(line);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isWalk ? Icons.directions_walk_rounded : Icons.directions_subway_rounded,
            color: color,
            size: 11,
          ),
          const SizedBox(width: 3),
          Text(
            line,
            style: GoogleFonts.jetBrainsMono(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getLineColor(String line) {
    switch (line.toUpperCase()) {
      case 'EWL':
        return const Color(0xFF009640);
      case 'NSL':
        return const Color(0xFFD42E12);
      case 'NEL':
        return const Color(0xFF9900AA);
      case 'CCL':
        return const Color(0xFFFA9E0D);
      case 'DTL':
        return const Color(0xFF005EC4);
      case 'TEL':
        return const Color(0xFF9D5B25);
      case 'WALK':
        return const Color(0xFF94A3B8);
      default:
        return const Color(0xFF00D26A);
    }
  }
}
