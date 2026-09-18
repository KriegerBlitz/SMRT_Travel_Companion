import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/journey_diagram_data.dart';
import '../../core/services/natural_language_route_service.dart';
import '../../core/transit/journey_diagram_builder.dart';
import '../home/widgets/route_search_bar.dart';
import 'widgets/transit_journey_diagram.dart';

/// Full Journey & Navigation Screen.
///
/// Features:
/// - Top bar with Back button and natural language [RouteSearchBar].
/// - Prominent ETA summary card with duration and confidence indicator.
/// - Schematic transit diagram with station dots, big dots for important stations,
///   and authentic MRT line colors.
class JourneyScreen extends StatefulWidget {
  final String initialQuery;
  final NaturalLanguageRouteService? routeService;
  final JourneyDiagramBuilder? diagramBuilder;

  const JourneyScreen({
    super.key,
    this.initialQuery = 'Bugis to Harborfront on Wheelchair',
    this.routeService,
    this.diagramBuilder,
  });

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  late final NaturalLanguageRouteService _routeService;
  late final JourneyDiagramBuilder _diagramBuilder;

  bool _isLoading = true;
  String? _errorMessage;
  JourneyDiagramData? _diagramData;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _searchFocusNode = FocusNode();
    _routeService = widget.routeService ?? NaturalLanguageRouteService();
    _diagramBuilder = widget.diagramBuilder ?? const JourneyDiagramBuilder();

    _planJourney(widget.initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _planJourney(String query) async {
    final cleanQuery = query.trim().isEmpty ? 'Bugis to Harborfront on Wheelchair' : query.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _routeService.interpretAndPlanRoute(cleanQuery);
      final diagram = _diagramBuilder.buildDiagram(result.routePlan);

      if (mounted) {
        setState(() {
          _diagramData = diagram;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not plan route. Please try another station or location.';
          _isLoading = false;
        });
      }
    }
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
                      placeholder: 'Search route or station...',
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
                              // ETA & Journey Summary Card
                              if (_diagramData != null) _buildEtaSummaryCard(_diagramData!),

                              const SizedBox(height: 16),

                              // Disruption / Mitigation Notice if rerouted
                              if (_diagramData?.isRerouted == true)
                                _buildDisruptionNotice(_diagramData!),

                              // Transit Diagram Header
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                                child: Row(
                                  children: [
                                    Text(
                                      'ROUTE TIMELINE',
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
