import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/crowd_density.dart';
import '../../../core/models/route_plan.dart';

/// Interactive modal sheet explaining the ETA confidence band and contributing factors.
/// Fulfills PS2 requirement:
/// "Confidence band on ETA — color-coded (green/amber/red), tap to see the reason
/// ("crowd rising + 1 active alert") — never a single fake-precise number"
class ConfidenceDetailsSheet extends StatelessWidget {
  final RoutePlan plan;

  const ConfidenceDetailsSheet({
    super.key,
    required this.plan,
  });

  static void show(BuildContext context, RoutePlan plan) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ConfidenceDetailsSheet(plan: plan),
    );
  }

  @override
  Widget build(BuildContext context) {
    final conf = plan.confidence;
    final isRerouted = plan.isRerouted;
    final hasHighCrowd = plan.stationCrowds.values.any((c) => c == CrowdLevel.high);
    final hasRain = plan.hasRainRisk;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        20 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Grab handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title & Confidence Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: conf.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: conf.color.withValues(alpha: 0.35)),
                ),
                child: Icon(
                  conf == ConfidenceLevel.green
                      ? Icons.verified_rounded
                      : (conf == ConfidenceLevel.amber
                          ? Icons.warning_amber_rounded
                          : Icons.error_outline_rounded),
                  color: conf.color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ETA Confidence Analysis',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${conf.label} · Window: ${plan.etaBand}',
                      style: GoogleFonts.plusJakartaSans(
                        color: conf.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Plain-English Reason Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRIMARY REASON',
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  plan.confidenceReason,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4-Point Factor Audit Breakdown
          Text(
            'NETWORK & ACCESSIBILITY AUDIT',
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),

          _buildFactorTile(
            icon: Icons.train_rounded,
            title: 'Train Service Status (LTA DataMall)',
            detail: isRerouted
                ? 'Active disruption on line. Official mitigation active.'
                : 'All line segments operating at normal frequency.',
            statusTag: isRerouted ? 'ALERT ACTIVE' : 'NORMAL SERVICE',
            tagColor: isRerouted ? const Color(0xFFEF4444) : const Color(0xFF10B981),
          ),
          const SizedBox(height: 6),

          _buildFactorTile(
            icon: Icons.people_alt_rounded,
            title: 'Station Crowding (PCD Forecast)',
            detail: hasHighCrowd
                ? 'High crowd surge predicted at key stations along route.'
                : 'Stable platform density (low to moderate load).',
            statusTag: hasHighCrowd ? 'SURGE PREDICTED' : 'STABLE CROWD',
            tagColor: hasHighCrowd ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
          ),
          const SizedBox(height: 6),

          _buildFactorTile(
            icon: Icons.elevator_rounded,
            title: 'Station Lifts (FacilitiesMaintenance)',
            detail: isRerouted && plan.id.contains('bus-alternative')
                ? 'Broken lift at destination. Wheelchair bus reroute active.'
                : 'All station lifts and step-free concourse ramps operational.',
            statusTag: isRerouted && plan.id.contains('bus-alternative')
                ? 'LIFT OUTAGE'
                : '100% OPERATIONAL',
            tagColor: isRerouted && plan.id.contains('bus-alternative')
                ? const Color(0xFFEF4444)
                : const Color(0xFF10B981),
          ),
          const SizedBox(height: 6),

          _buildFactorTile(
            icon: Icons.beach_access_rounded,
            title: '2-Hour Weather & Shelters',
            detail: hasRain
                ? 'Rain detected in 2h nowcast. CoveredLinkWay paths prioritized.'
                : 'Fair skies. Normal pedestrian linkways open.',
            statusTag: hasRain ? 'RAIN / SHELTERED' : 'FAIR WEATHER',
            tagColor: hasRain ? const Color(0xFF38BDF8) : const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  Widget _buildFactorTile({
    required IconData icon,
    required String title,
    required String detail,
    required String statusTag,
    required Color tagColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: tagColor, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: tagColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: tagColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        statusTag,
                        style: GoogleFonts.jetBrainsMono(
                          color: tagColor,
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 10.5,
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
