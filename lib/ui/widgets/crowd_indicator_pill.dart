import 'package:flutter/material.dart';
import '../../services/lta_models.dart';

class CrowdIndicatorPill extends StatelessWidget {
  final CrowdLevel level;
  final bool isForecastSpike;
  final bool isLargeText;

  const CrowdIndicatorPill({
    super.key,
    required this.level,
    this.isForecastSpike = false,
    this.isLargeText = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    String label;
    IconData icon;

    switch (level) {
      case CrowdLevel.low:
        bg = const Color(0xFF14532D).withValues(alpha: 0.3);
        border = const Color(0xFF22C55E);
        label = 'Low Crowds';
        icon = Icons.check_circle_outline;
        break;
      case CrowdLevel.moderate:
        bg = const Color(0xFF78350F).withValues(alpha: 0.3);
        border = const Color(0xFFF59E0B);
        label = 'Moderate Crowds';
        icon = Icons.info_outline;
        break;
      case CrowdLevel.high:
        bg = const Color(0xFF7F1D1D).withValues(alpha: 0.3);
        border = const Color(0xFFEF4444);
        label = 'Heavy Crowds';
        icon = Icons.warning_amber_rounded;
        break;
    }

    if (isForecastSpike) {
      label = 'Crowd Surge Expected (30m)';
      border = const Color(0xFFEF4444);
      icon = Icons.trending_up;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLargeText ? 12 : 8,
        vertical: isLargeText ? 6 : 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isLargeText ? 18 : 13, color: border),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: isLargeText ? 16 : 12,
            ),
          ),
        ],
      ),
    );
  }
}
