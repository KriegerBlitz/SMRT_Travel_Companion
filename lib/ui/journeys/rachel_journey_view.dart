import 'package:flutter/material.dart';
import '../../services/lta_models.dart';
import '../../services/onemap_service.dart';
import '../widgets/confidence_eta_badge.dart';
import '../widgets/crowd_indicator_pill.dart';

class RachelJourneyView extends StatelessWidget {
  final DoorToDoorRoute currentRoute;
  final DoorToDoorRoute? alternativeRoute;
  final TrainServiceAlert alert;
  final StationCrowdInfo crowdInfo;
  final VoidCallback onSelectAlternative;
  final bool showAlternative;

  const RachelJourneyView({
    super.key,
    required this.currentRoute,
    this.alternativeRoute,
    required this.alert,
    required this.crowdInfo,
    required this.onSelectAlternative,
    this.showAlternative = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasDisruption = alert.isDisrupted;
    final hasCrowdWarning = crowdInfo.isForecastSpike;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Persona Header Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blueGrey.shade700),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFF009645),
                    radius: 18,
                    child: Text(
                      'R',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rachel · Daily Commuter',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Tampines (EW2) ➔ Raffles Place (EW14) · Depart 07:40',
                          style: TextStyle(
                            color: Colors.blueGrey.shade200,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ConfidenceETABadge(route: currentRoute),
                ],
              ),

              // Proactive Disruption Banner (Rule 3.1: Silent on normal days, 1 proactive line on disruption)
              if (hasDisruption) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning_rounded, color: Colors.redAccent, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'PROACTIVE DISRUPTION ADVISORY',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Delay likely today, +15 min: Take the Free MRT Shuttle from Tampines, leave 10 min earlier.',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      if (alert.freeMrtShuttle) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade900,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'LTA FREE MRT SHUTTLE ACTIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Text(
                              'Available at Tampines Bus Int Bay 8',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ] else if (hasCrowdWarning) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade900.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amberAccent),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.amberAccent, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'PCD Forecast: High crowd density predicted at Tampines platform between 07:45-08:15. Consider leaving earlier.',
                          style: TextStyle(color: Colors.amberAccent, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Color(0xFF22C55E), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'App is silent: On schedule. Normal headway on East-West Line.',
                      style: TextStyle(color: Color(0xFF86EFAC), fontSize: 12),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Route comparison side-by-side card (Mandatory Capability 1.3)
        if (alternativeRoute != null) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onSelectAlternative,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: !showAlternative
                        ? const Color(0xFF009645).withValues(alpha: 0.2)
                        : Colors.transparent,
                    side: BorderSide(
                      color: !showAlternative ? const Color(0xFF009645) : Colors.blueGrey,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Original Route',
                        style: TextStyle(
                          color: !showAlternative ? Colors.white : Colors.white60,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${currentRoute.totalMinutes} min · EWL',
                        style: TextStyle(
                          color: !showAlternative ? const Color(0xFF86EFAC) : Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onSelectAlternative,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: showAlternative
                        ? const Color(0xFF0284C7).withValues(alpha: 0.2)
                        : Colors.transparent,
                    side: BorderSide(
                      color: showAlternative ? const Color(0xFF0284C7) : Colors.blueGrey,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Mitigation Shuttle',
                        style: TextStyle(
                          color: showAlternative ? Colors.white : Colors.white60,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${alternativeRoute!.totalMinutes} min · Free Bus',
                        style: TextStyle(
                          color: showAlternative ? Colors.cyanAccent : Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // Turn-by-turn Door-to-Door Route Legs
        Card(
          color: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      showAlternative
                          ? (alternativeRoute?.title ?? 'Alternative Route')
                          : currentRoute.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    CrowdIndicatorPill(
                      level: crowdInfo.realTime,
                      isForecastSpike: crowdInfo.isForecastSpike,
                    ),
                  ],
                ),
                const Divider(color: Colors.blueGrey, height: 20),
                ...((showAlternative && alternativeRoute != null)
                        ? alternativeRoute!.legs
                        : currentRoute.legs)
                    .map((leg) => _buildLegRow(leg)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegRow(RouteLeg leg) {
    IconData icon;
    Color color;
    switch (leg.mode) {
      case 'WALK':
        icon = Icons.directions_walk;
        color = Colors.blueAccent;
        break;
      case 'MRT':
        icon = Icons.train;
        color = const Color(0xFF009645);
        break;
      case 'SHUTTLE':
      case 'BUS':
        icon = Icons.directions_bus;
        color = Colors.cyanAccent;
        break;
      default:
        icon = Icons.navigation;
        color = Colors.white70;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leg.instruction,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                Text(
                  '${leg.durationMinutes} min · ${(leg.distanceMeters / 1000).toStringAsFixed(1)} km',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
