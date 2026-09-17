import 'package:flutter/material.dart';
import '../../services/onemap_service.dart';

class ConfidenceETABadge extends StatelessWidget {
  final DoorToDoorRoute route;
  final bool isLargeText;

  const ConfidenceETABadge({
    super.key,
    required this.route,
    this.isLargeText = false,
  });

  Color _getColor(ETAConfidence confidence) {
    switch (confidence) {
      case ETAConfidence.green:
        return const Color(0xFF22C55E);
      case ETAConfidence.amber:
        return const Color(0xFFF59E0B);
      case ETAConfidence.red:
        return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(route.confidence);

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.info_outline, color: color),
                const SizedBox(width: 8),
                Text(
                  'ETA Confidence Breakdown',
                  style: TextStyle(fontSize: isLargeText ? 20 : 16),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      route.confidence.label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: isLargeText ? 18 : 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  route.confidenceReason,
                  style: TextStyle(
                    fontSize: isLargeText ? 17 : 14,
                    height: 1.4,
                  ),
                ),
                if (route.delayMinutes > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade900.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.shade700),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer, color: Colors.redAccent, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Estimated delay cost: +${route.delayMinutes} mins',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                            fontSize: isLargeText ? 16 : 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Why a confidence band?\nReal-time LTA signals (train headway variance, platform crowd surge, and mitigation shuttles) dynamic range ETA instead of a single fake-precise number.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white60,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.6),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${route.totalMinutes} min',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isLargeText ? 20 : 15,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.touch_app, size: isLargeText ? 18 : 13, color: color),
          ],
        ),
      ),
    );
  }
}
