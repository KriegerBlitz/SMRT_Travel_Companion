import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/crowd_density.dart';
import '../../../core/models/route_plan.dart';
import '../../../core/services/natural_language_route_service.dart';
import 'confidence_details_sheet.dart';
import 'side_by_side_route_card.dart';

/// Presentation card displaying the door-to-door route plan, ETA confidence band,
/// station crowd density indicators, and side-by-side disruption comparison.
/// Fulfills PS2 requirements 1.1, 1.2, and 1.3.
class RoutePreviewSheet extends StatelessWidget {
  final ParsedJourneyResult result;
  final VoidCallback? onDismiss;
  final ValueChanged<bool>? onToggleRouteDisplay;

  const RoutePreviewSheet({
    super.key,
    required this.result,
    this.onDismiss,
    this.onToggleRouteDisplay,
  });

  @override
  Widget build(BuildContext context) {
    final plan = result.routePlan;
    final isRerouted = plan.isRerouted && plan.alternativeRoute != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF131A26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Origin ➔ Destination and ETA Band
          Row(
            children: [
              Expanded(
                child: Text(
                  '${result.origin} ➔ ${result.destination}',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () => ConfidenceDetailsSheet.show(context, plan),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        plan.confidence.color.withValues(alpha: 0.25),
                        Colors.white.withValues(alpha: 0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: plan.confidence.color.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '⏱️ ETA ${plan.etaBand}',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.info_outline_rounded,
                        color: plan.confidence.color,
                        size: 13,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 2. Tappable Confidence Badge & Accessibility / Weather Badges
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              // Tappable Confidence Tag (never a single fake-precise number)
              InkWell(
                onTap: () => ConfidenceDetailsSheet.show(context, plan),
                borderRadius: BorderRadius.circular(6),
                child: _buildTag(
                  icon: Icons.verified_user_rounded,
                  label: '${plan.confidence.label} (Tap for audit)',
                  color: plan.confidence.color,
                  isInteractive: true,
                ),
              ),
              if (result.isWheelchairAccessible)
                _buildTag(
                  icon: Icons.accessible_rounded,
                  label: 'Wheelchair / Barrier-Free',
                  color: const Color(0xFF38BDF8),
                ),
              if (plan.usesShelteredWalkways)
                _buildTag(
                  icon: Icons.beach_access_rounded,
                  label: 'CoveredLinkWay (Sheltered)',
                  color: const Color(0xFF2DD4BF),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // 3. Side-by-Side Comparison Card (if rerouted due to disruption / lift outage)
          if (isRerouted) ...[
            SideBySideRouteCard(
              recommendedRoute: plan,
              originalRoute: plan.alternativeRoute!,
              onRouteSelected: onToggleRouteDisplay,
            ),
            const SizedBox(height: 10),
          ],

          // 4. Multi-Modal Transit Legs with Station-by-Station Crowd Indicators
          Text(
            'JOURNEY LEGS & STATION CROWD DENSITY',
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < plan.legs.length; i++) ...[
                  _buildLegCard(plan.legs[i], plan.stationCrowds),
                  if (i < plan.legs.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white.withValues(alpha: 0.35),
                        size: 16,
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.white70, size: 13),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Journey logic planned. Full journey page will be implemented next!',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white70,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
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
    bool isInteractive = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
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
          if (isInteractive) ...[
            const SizedBox(width: 3),
            Icon(Icons.touch_app_rounded, color: color, size: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildLegCard(RouteLeg leg, Map<String, CrowdLevel> crowdMap) {
    final isWalk = leg.mode == 'WALK';
    final isShuttle = leg.mode == 'SHUTTLE';
    final line = leg.lineOrService ?? (isWalk ? 'Walk' : (isShuttle ? 'Shuttle' : 'Transit'));
    final color = _getLineColor(line);

    // Look up station crowd if applicable
    CrowdLevel? crowdLvl;
    if (leg.departureStationCode != null && crowdMap.containsKey(leg.departureStationCode)) {
      crowdLvl = crowdMap[leg.departureStationCode];
    } else {
      // Check if departure stop matches a station code e.g. EW2
      for (final entry in crowdMap.entries) {
        if (leg.departureStop.toUpperCase().contains(entry.key)) {
          crowdLvl = entry.value;
          break;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0B111E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: leg.isDisrupted ? const Color(0xFFEF4444) : color.withValues(alpha: 0.35),
          width: leg.isDisrupted ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isWalk
                          ? Icons.directions_walk_rounded
                          : (isShuttle
                              ? Icons.airport_shuttle_rounded
                              : Icons.directions_subway_rounded),
                      color: color,
                      size: 11,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      line,
                      style: GoogleFonts.jetBrainsMono(
                        color: color,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${leg.durationMinutes}m',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Station Name
          Text(
            leg.departureStop,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // One-Glance 3-Level Crowd Density Indicator (Never color-alone!)
          if (!isWalk) ...[
            const SizedBox(height: 4),
            _buildOneGlanceCrowdIndicator(crowdLvl ?? leg.crowdLevel),
          ],
        ],
      ),
    );
  }

  /// One-glance 3-level color & text indicator per station
  /// Never relies on color alone to convey state.
  Widget _buildOneGlanceCrowdIndicator(CrowdLevel level) {
    String label;
    Color color;
    IconData icon;

    switch (level) {
      case CrowdLevel.low:
        label = 'LOW CROWD';
        color = const Color(0xFF10B981);
        icon = Icons.airline_seat_recline_normal_rounded;
        break;
      case CrowdLevel.moderate:
        label = 'MODERATE';
        color = const Color(0xFFF59E0B);
        icon = Icons.groups_rounded;
        break;
      case CrowdLevel.high:
        label = 'HIGH SURGE';
        color = const Color(0xFFEF4444);
        icon = Icons.warning_rounded;
        break;
      case CrowdLevel.na:
        label = 'NORMAL';
        color = const Color(0xFF10B981);
        icon = Icons.check_circle_outline_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 9),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Color _getLineColor(String line) {
    switch (line.toUpperCase()) {
      case 'EWL':
      case 'CGL':
        return const Color(0xFF009645);
      case 'NSL':
        return const Color(0xFFD42E12);
      case 'NEL':
        return const Color(0xFF7F2889);
      case 'CCL':
      case 'CEL':
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
