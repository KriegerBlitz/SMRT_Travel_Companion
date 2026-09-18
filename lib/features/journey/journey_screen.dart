import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/journey_diagram_data.dart';
import '../../core/models/route_plan.dart';
import '../../core/services/live_journey_service.dart';
import '../../core/services/natural_language_route_service.dart';
import '../../core/transit/journey_diagram_builder.dart';
import '../home/widgets/route_search_bar.dart';
import 'widgets/transit_journey_diagram.dart';

/// Full Journey & Navigation Screen.
///
/// Features:
/// - Top bar with Back button and natural language [RouteSearchBar] (supports station codes like EW28, NS24).
/// - Multi-modal travel options selector (Fastest Rail, Direct Bus, Step-Free Sheltered).
/// - Prominent ETA summary card with duration and confidence indicator.
/// - "Begin Journey" CTA launching live transit navigation.
/// - Live Navigation HUD with remaining ETA, next stop indicator, and step progression.
/// - Schematic transit diagram with station dots, big dots for important stations,
///   authentic MRT line colors, and active pulsing beacon.
class JourneyScreen extends StatefulWidget {
  final String initialQuery;
  final NaturalLanguageRouteService? routeService;
  final JourneyDiagramBuilder? diagramBuilder;
  final LiveJourneyService? liveJourneyService;

  const JourneyScreen({
    super.key,
    this.initialQuery = 'Bugis to Harborfront on Wheelchair',
    this.routeService,
    this.diagramBuilder,
    this.liveJourneyService,
  });

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  late final NaturalLanguageRouteService _routeService;
  late final JourneyDiagramBuilder _diagramBuilder;
  late final LiveJourneyService _liveJourneyService;
  StreamSubscription<LiveJourneyState>? _liveSub;

  bool _isLoading = true;
  String? _errorMessage;
  JourneyDiagramData? _diagramData;
  List<RoutePlan> _travelOptions = [];
  int _selectedOptionIndex = 0;
  LiveJourneyState? _liveState;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _searchFocusNode = FocusNode();
    _routeService = widget.routeService ?? NaturalLanguageRouteService();
    _diagramBuilder = widget.diagramBuilder ?? const JourneyDiagramBuilder();
    _liveJourneyService = widget.liveJourneyService ?? LiveJourneyService();

    _liveSub = _liveJourneyService.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _liveState = state;
        });
      }
    });

    _planJourney(widget.initialQuery);
  }

  @override
  void dispose() {
    _liveSub?.cancel();
    _liveJourneyService.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _planJourney(String query) async {
    final cleanQuery = query.trim().isEmpty ? 'Bugis to Harborfront on Wheelchair' : query.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _liveState = null;
    });

    try {
      final result = await _routeService.interpretAndPlanRoute(cleanQuery);
      final options = result.allOptions.isNotEmpty ? result.allOptions : [result.routePlan];
      final primary = options.first;
      final diagram = _diagramBuilder.buildDiagram(primary);

      if (mounted) {
        setState(() {
          _travelOptions = options;
          _selectedOptionIndex = 0;
          _diagramData = diagram;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not plan route. Please try another station code or location.';
          _isLoading = false;
        });
      }
    }
  }

  void _selectTravelOption(int index) {
    if (index < 0 || index >= _travelOptions.length) return;
    final selectedPlan = _travelOptions[index];
    setState(() {
      _selectedOptionIndex = index;
      _diagramData = _diagramBuilder.buildDiagram(selectedPlan);
      if (_liveState != null && _liveState!.isNavigating) {
        _liveState = _liveJourneyService.startJourney(selectedPlan);
      }
    });
  }

  void _beginJourney() {
    if (_travelOptions.isEmpty) return;
    final selected = _travelOptions[_selectedOptionIndex];
    final state = _liveJourneyService.startJourney(selected);
    setState(() {
      _liveState = state;
    });
  }

  void _advanceStop() {
    if (_liveState == null || !_liveState!.isNavigating) return;
    final state = _liveJourneyService.advanceStep();
    setState(() {
      _liveState = state;
    });
  }

  void _endJourney() {
    _liveJourneyService.stopJourney();
    setState(() {
      _liveState = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07090E), // Ambient dark background
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Back Button + Natural Language Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Row(
                children: [
                  // Back button to return to Map
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F141F),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Search bar
                  Expanded(
                    child: RouteSearchBar(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      placeholder: 'Search route, e.g. EW28 to NS24...',
                      onSubmitted: (val) => _planJourney(val),
                      onPlanPressed: () => _planJourney(_searchController.text),
                    ),
                  ),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2.5,
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Live Navigation HUD if navigating
                              if (_liveState != null && _liveState!.isNavigating) ...[
                                _buildLiveNavigationHud(_liveState!),
                                const SizedBox(height: 16),
                              ] else if (_liveState != null && _liveState!.isArrived) ...[
                                _buildArrivalBanner(_liveState!),
                                const SizedBox(height: 16),
                              ] else ...[
                                // ETA & Journey Summary Card
                                if (_diagramData != null) _buildEtaSummaryCard(_diagramData!),
                                const SizedBox(height: 16),

                                // Travel Methods & Bus Alternatives Selector
                                if (_travelOptions.length > 1) ...[
                                  _buildTravelOptionsSection(),
                                  const SizedBox(height: 16),
                                ],

                                // Begin Journey Action Button
                                _buildBeginJourneyButton(),
                                const SizedBox(height: 16),
                              ],

                              // Disruption / Mitigation Notice if rerouted
                              if (_diagramData?.isRerouted == true)
                                _buildDisruptionNotice(_diagramData!),

                              // Transit Diagram Header
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                                child: Row(
                                  children: [
                                    Text(
                                      _liveState?.isNavigating == true
                                          ? 'LIVE ROUTE PROGRESS'
                                          : 'ROUTE TIMELINE',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white.withValues(alpha: 0.5),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${_diagramData?.totalStationCount ?? 0} Stations',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white.withValues(alpha: 0.5),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Metro Schematic Diagram
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F141F),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.10),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                child: TransitJourneyDiagram(
                                  diagramData: _diagramData!,
                                  activeStationName: _liveState?.isNavigating == true
                                      ? _liveState?.currentStopName
                                      : null,
                                ),
                              ),

                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTravelOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(
            'TRAVEL METHODS & ALTERNATIVES',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        SizedBox(
          height: 98,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _travelOptions.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final opt = _travelOptions[index];
              final isSelected = index == _selectedOptionIndex;
              final badgeColor = opt.badge == 'DIRECT BUS'
                  ? const Color(0xFF8B5CF6)
                  : (opt.badge == 'STEP-FREE' ? const Color(0xFF00D26A) : const Color(0xFF00E5FF));

              return InkWell(
                onTap: () => _selectTravelOption(index),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 210,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF162033)
                        : const Color(0xFF0F141F),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF00E5FF)
                          : Colors.white.withValues(alpha: 0.12),
                      width: isSelected ? 1.8 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (opt.badge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                opt.badge!,
                                style: GoogleFonts.plusJakartaSans(
                                  color: badgeColor,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          const Spacer(),
                          Icon(
                            opt.hasBus ? Icons.directions_bus_rounded : Icons.directions_subway_rounded,
                            color: isSelected ? const Color(0xFF00E5FF) : Colors.white60,
                            size: 16,
                          ),
                        ],
                      ),
                      Text(
                        opt.title,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Text(
                            '${opt.totalDurationMinutes} min',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '· ${opt.modeSummary}',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBeginJourneyButton() {
    final selected = _travelOptions.isNotEmpty ? _travelOptions[_selectedOptionIndex] : null;
    final duration = selected?.totalDurationMinutes ?? 0;

    return ElevatedButton(
      onPressed: _beginJourney,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00E5FF),
        foregroundColor: const Color(0xFF07090E),
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 6,
        shadowColor: const Color(0xFF00E5FF).withValues(alpha: 0.4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.navigation_rounded, size: 20),
          const SizedBox(width: 8),
          Text(
            'Begin Journey ($duration min) →',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveNavigationHud(LiveJourneyState state) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0A2540),
            const Color(0xFF0F141F),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Live Indicator + ETA
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF00E5FF), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF00E5FF),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'LIVE NAVIGATION',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF00E5FF),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '${state.remainingEtaMinutes} min left',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Next Stop Spotlight
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.arrow_circle_right_rounded,
                  color: Color(0xFF00E5FF),
                  size: 26,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NEXT STOP (IN ${state.minutesToNextStop} MIN)',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        state.nextStopName ?? state.currentStopName,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Instruction Text
          Text(
            state.navigationInstruction,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 14),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: state.progressFraction,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
            ),
          ),

          const SizedBox(height: 14),

          // Action Controls: Advance Stop & End Trip
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _advanceStop,
                  icon: const Icon(Icons.skip_next_rounded, size: 18),
                  label: const Text('Advance Stop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: const Color(0xFF07090E),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: _endJourney,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('End Trip'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArrivalBanner(LiveJourneyState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981), width: 1.2),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Arrived at Destination!',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  state.navigationInstruction,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _endJourney,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildEtaSummaryCard(JourneyDiagramData data) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF141B2B),
            const Color(0xFF0F141F),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Estimated Travel Time & Confidence Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${data.totalDurationMinutes}',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'mins ETA',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),

              // Confidence Badge (Color-coded)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: data.etaConfidenceColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: data.etaConfidenceColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: data.etaConfidenceColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      data.etaConfidenceLabel,
                      style: GoogleFonts.plusJakartaSans(
                        color: data.etaConfidenceColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Row 2: Route Origin -> Destination
          Row(
            children: [
              Text(
                data.origin,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 16,
                ),
              ),
              Expanded(
                child: Text(
                  data.destination,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Row 3: Confidence Reason / Accessibility Note
          Text(
            data.confidenceReason,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisruptionNotice(JourneyDiagramData data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFEF4444),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Service Disruption Reroute Active',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.rerouteReason ?? 'Route automatically adjusted using official Free MRT Shuttle.',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
