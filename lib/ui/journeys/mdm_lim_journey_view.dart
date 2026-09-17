import 'package:flutter/material.dart';
import '../../services/accessibility_helper.dart';
import '../../services/lta_models.dart';
import '../../services/onemap_service.dart';
import '../../services/weather_service.dart';
import '../widgets/confidence_eta_badge.dart';

class MdmLimJourneyView extends StatefulWidget {
  final DoorToDoorRoute currentRoute;
  final FacilityMaintenance? liftMaintenance;
  final WeatherNowcast weatherNowcast;
  final List<BusArrivalInfo> wabBusArrivals;
  final bool isLargeText;
  final ValueChanged<bool> onToggleLargeText;
  final int deadReckoningSeconds;
  final VoidCallback onAdvanceTimer;
  final VoidCallback onResetTimer;

  const MdmLimJourneyView({
    super.key,
    required this.currentRoute,
    this.liftMaintenance,
    required this.weatherNowcast,
    required this.wabBusArrivals,
    required this.isLargeText,
    required this.onToggleLargeText,
    required this.deadReckoningSeconds,
    required this.onAdvanceTimer,
    required this.onResetTimer,
  });

  @override
  State<MdmLimJourneyView> createState() => _MdmLimJourneyViewState();
}

class _MdmLimJourneyViewState extends State<MdmLimJourneyView> {
  @override
  Widget build(BuildContext context) {
    final isLarge = widget.isLargeText;
    final isLiftDown = widget.liftMaintenance?.isOutOfService ?? false;
    final isRain = widget.weatherNowcast.isRaining;

    // Remaining underground journey time
    final totalSecs = widget.currentRoute.totalMinutes * 60;
    final remainingSecs = (totalSecs - widget.deadReckoningSeconds).clamp(0, totalSecs);
    final remainingMins = (remainingSecs / 60).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Persona Header Card
        Container(
          padding: EdgeInsets.all(isLarge ? 18 : 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.shade700, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.purple.shade600,
                    radius: isLarge ? 22 : 18,
                    child: const Icon(Icons.accessible_forward, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mdm Lim · Accessibility Commuter',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isLarge ? 19 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Bedok (EW5) ➔ SGH via Outram Park · Fortnightly Visit',
                          style: TextStyle(
                            color: Colors.purple.shade200,
                            fontSize: isLarge ? 14 : 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ConfidenceETABadge(
                    route: widget.currentRoute,
                    isLargeText: isLarge,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Accessibility Action Row: TTS Readout + Large Text Toggle (Wrap for mobile portrait flexibility)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      final speech = isLiftDown
                          ? 'Notice for your hospital appointment: Outram Park Lift 2 is under maintenance. We recommend Wheelchair-Accessible Bus 147 from Bedok with seats available.'
                          : (isRain
                              ? 'Weather advisory: Passing showers are forecast near Outram Park. Your route is switched to the covered linkway from Exit 1.'
                              : 'Your step-free route to SGH is clear. All station lifts and covered linkways are fully operational.');
                      AccessibilityHelper.speakText(speech);
                    },
                    icon: Icon(Icons.volume_up, size: isLarge ? 22 : 18),
                    label: Text(
                      'Listen to Audio Advisory (TTS)',
                      style: TextStyle(
                        fontSize: isLarge ? 14 : 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade700,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isLarge ? 12 : 10,
                        vertical: isLarge ? 8 : 6,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => widget.onToggleLargeText(!isLarge),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isLarge ? Colors.amber.shade900 : Colors.blueGrey.shade800,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isLarge ? Colors.amberAccent : Colors.blueGrey,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isLarge ? Icons.text_fields : Icons.format_size,
                            size: 16,
                            color: isLarge ? Colors.amberAccent : Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isLarge ? 'Large Text: ON' : 'Large Text',
                            style: TextStyle(
                              color: isLarge ? Colors.amberAccent : Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Weather-aware Advisory Card (Rule 3.2: Feeds covered-vs-uncovered route choice)
        if (isRain) ...[
          Container(
            padding: EdgeInsets.all(isLarge ? 14 : 10),
            decoration: BoxDecoration(
              color: Colors.blue.shade900.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blueAccent, width: 1.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.umbrella, color: Colors.blueAccent, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WEATHER-AWARE COVERED LINKWAY ACTIVE',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: isLarge ? 15 : 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Passing showers forecast in Outram/Bukit Merah. Route automatically avoids open roads and routes through CoveredLinkWay from Outram Park Exit 1.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isLarge ? 15 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Lift Outage + WAB Bus Recommendation (Rule 3.2)
        if (isLiftDown) ...[
          Container(
            padding: EdgeInsets.all(isLarge ? 16 : 12),
            decoration: BoxDecoration(
              color: Colors.red.shade900.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.redAccent, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'LIFT OUTAGE DETECTED ON ROUTE',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w900,
                        fontSize: isLarge ? 16 : 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${widget.liftMaintenance?.locationDescription ?? 'Lift 2'} at Outram Park is out of service.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isLarge ? 16 : 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Recommended Wheelchair-Accessible Bus (WAB) Alternative:',
                  style: TextStyle(
                    color: Colors.amberAccent,
                    fontSize: isLarge ? 14 : 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                // WAB Bus Arrival Card from v3/BusArrival
                ...widget.wabBusArrivals.map((bus) => Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF005EC4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'BUS ${bus.serviceNo}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.accessible, color: Colors.greenAccent, size: 16),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'WAB (${bus.type})',
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: bus.loadColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: bus.loadColor),
                            ),
                            child: Text(
                              bus.loadDescription,
                              style: TextStyle(
                                color: bus.loadColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${bus.estimatedMinutes}m',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Dead-Reckoning Timer & Haptic Testing Panel (Rule 3.2)
        Card(
          color: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: EdgeInsets.all(isLarge ? 16 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: Colors.cyanAccent, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Underground Dead-Reckoning Timer',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: isLarge ? 16 : 13,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$remainingMins min remaining',
                      style: TextStyle(
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: isLarge ? 17 : 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Underground MRT tunnels block GPS. Timer uses OneMap segment durations to track progress.',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (widget.deadReckoningSeconds / totalSecs).clamp(0.0, 1.0),
                    backgroundColor: Colors.blueGrey.shade800,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: widget.onAdvanceTimer,
                      icon: const Icon(Icons.fast_forward, size: 14),
                      label: const Text('+3 min (Next Station)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.cyanAccent,
                        side: const BorderSide(color: Colors.cyanAccent),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: widget.onResetTimer,
                      child: const Text('Reset', style: TextStyle(color: Colors.white60, fontSize: 11)),
                    ),
                  ],
                ),
                const Divider(color: Colors.blueGrey, height: 20),
                // 3 Distinct Haptic Vibration Triggers (Rule 3.2)
                Text(
                  'Tactile Haptic Feedback (3 Distinct Vibration Patterns):',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isLarge ? 14 : 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildHapticButton(HapticPattern.timeToGetOff, Colors.greenAccent),
                    _buildHapticButton(HapticPattern.needToChangeLines, Colors.amberAccent),
                    _buildHapticButton(HapticPattern.serviceDisrupted, Colors.redAccent),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Step-Free Door-to-Door Route Directions
        Card(
          color: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: EdgeInsets.all(isLarge ? 16 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.currentRoute.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isLarge ? 18 : 15,
                  ),
                ),
                const Divider(color: Colors.blueGrey, height: 20),
                ...widget.currentRoute.legs.map((leg) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            leg.isSheltered ? Icons.umbrella : Icons.accessible,
                            color: leg.isSheltered ? Colors.blueAccent : Colors.purpleAccent,
                            size: isLarge ? 22 : 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  leg.instruction,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isLarge ? 16 : 13,
                                  ),
                                ),
                                if (leg.isSheltered)
                                  const Text(
                                    'CoveredLinkWay (Sheltered Walkway)',
                                    style: TextStyle(color: Colors.blueAccent, fontSize: 11),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHapticButton(HapticPattern pattern, Color color) {
    return ElevatedButton.icon(
      onPressed: () => AccessibilityHelper.triggerHaptic(pattern),
      icon: Icon(Icons.vibration, size: 14, color: color),
      label: Text(
        pattern.label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.15),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        side: BorderSide(color: color.withValues(alpha: 0.5)),
      ),
    );
  }
}
