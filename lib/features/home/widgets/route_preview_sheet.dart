import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/route_plan.dart';
import '../../../core/services/natural_language_route_service.dart';

/// Presentation card displaying the interpreted route preview, ETA, accessibility badge, and transit legs
class RoutePreviewSheet extends StatelessWidget {
  final ParsedJourneyResult result;
  final VoidCallback? onDismiss;

  const RoutePreviewSheet({
    super.key,
    required this.result,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
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
                  gradient: const LinearGradient(
                    colors: [
                      Colors.white,
                      Color(0xFFE2E8F0),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.15),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Text(
                  '⏱️ ${result.etaDisplay} ETA',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.black,
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
