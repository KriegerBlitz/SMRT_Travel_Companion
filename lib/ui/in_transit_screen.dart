import 'package:flutter/material.dart';
import '../services/accessibility_helper.dart';
import '../services/simulator_service.dart';
import 'theme.dart';

class InTransitScreen extends StatefulWidget {
  final SimulatorService simulator;
  final VoidCallback? onBack;

  const InTransitScreen({
    super.key,
    required this.simulator,
    this.onBack,
  });

  @override
  State<InTransitScreen> createState() => _InTransitScreenState();
}

class _InTransitScreenState extends State<InTransitScreen>
    with SingleTickerProviderStateMixin {
  bool _isAllStopsExpanded = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // 9 stops on this simulated transit segment
  final List<String> _stops = [
    'Jurong East',
    'Bukit Batok',
    'Bukit Gombak',
    'Novena',
    'Newton',
    'Orchard',
    'Somerset',
    'Dhoby Ghaut',
    'City Hall',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Current stop index from simulator or default to 4 (Novena)
    final currentStopIndex = widget.simulator.currentStop.clamp(1, 9);
    final currentStopName = _stops[currentStopIndex - 1];
    final isApproaching = currentStopIndex == 4 || widget.simulator.isDeadReckoningApproaching;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header with optional Back button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.onBack != null) ...[
                    InkWell(
                      onTap: widget.onBack,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppTheme.textPrimary,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jurong East → City Hall',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Stop $currentStopIndex of 9 · NS line',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Segmented Progress Bar (9 bars)
              Row(
                children: List.generate(9, (index) {
                  final isPassedOrCurrent = index < currentStopIndex;
                  return Expanded(
                    child: Container(
                      height: 5,
                      margin: EdgeInsets.only(right: index == 8 ? 0 : 5),
                      decoration: BoxDecoration(
                        color: isPassedOrCurrent
                            ? AppTheme.purpleLight
                            : AppTheme.cardBorder,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 24),

              // Large Next Stop Display Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                decoration: AppTheme.cardDecoration(),
                child: Column(
                  children: [
                    const Text(
                      'Next stop',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      currentStopName,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '2 min',
                      style: TextStyle(
                        color: Color(0xFF93C5FD), // Light blue-purple
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Based on elapsed time, not GPS',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Approaching Your Stop Alert (Green with Pulse)
              if (isApproaching)
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.greenBannerBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.greenSuccess,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: AppTheme.greenSuccess,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.vibration_rounded,
                            color: Color(0xFF0D2818),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Approaching your stop',
                                style: TextStyle(
                                  color: Color(0xFFE2E8F0),
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Haptic + visual pulse firing now',
                                style: TextStyle(
                                  color: Color(0xFF6EE7B7),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 14),

              // Spoken Audio TTS + Haptic Button
              InkWell(
                onTap: () {
                  AccessibilityHelper.speakText(
                    'Approaching $currentStopName station. Doors opening on the left side.',
                  );
                  AccessibilityHelper.triggerHaptic(HapticPattern.timeToGetOff);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Spoken: "Approaching $currentStopName" + Haptic pulse'),
                      duration: const Duration(milliseconds: 1500),
                      backgroundColor: AppTheme.purplePrimary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.purplePillBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.purpleLight.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.volume_up_rounded, color: AppTheme.purpleLight, size: 20),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Read Aloud Stop Announcement (TTS + Haptic)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Accordion "View all stops"
              Container(
                decoration: AppTheme.cardDecoration(),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isAllStopsExpanded = !_isAllStopsExpanded;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'View all stops',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Icon(
                              _isAllStopsExpanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: AppTheme.textMuted,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isAllStopsExpanded)
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          children: List.generate(_stops.length, (idx) {
                            final stopNum = idx + 1;
                            final isPast = stopNum < currentStopIndex;
                            final isCurrent = stopNum == currentStopIndex;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isCurrent
                                          ? AppTheme.purplePrimary
                                          : isPast
                                              ? AppTheme.purplePillBg
                                              : AppTheme.cardBorder,
                                      shape: BoxShape.circle,
                                    ),
                                    child: isPast
                                        ? const Icon(Icons.check, size: 14, color: AppTheme.purpleLight)
                                        : Text(
                                            '$stopNum',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isCurrent
                                                  ? Colors.white
                                                  : AppTheme.textMuted,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _stops[idx],
                                      style: TextStyle(
                                        color: isCurrent
                                            ? AppTheme.textPrimary
                                            : isPast
                                                ? AppTheme.textSecondary
                                                : AppTheme.textMuted,
                                        fontSize: 14,
                                        fontWeight:
                                            isCurrent ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  if (isCurrent)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppTheme.purplePillBg,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Next stop',
                                        style: TextStyle(
                                          color: AppTheme.purpleLight,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Simulation Controls for dead reckoning testing
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      if (widget.simulator.currentStop > 1) {
                        widget.simulator.setCurrentStop(
                            widget.simulator.currentStop - 1);
                        setState(() {});
                      }
                    },
                    icon: const Icon(Icons.arrow_back, size: 16, color: AppTheme.textMuted),
                    label: const Text(
                      'Prev Stop',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      if (widget.simulator.currentStop < 9) {
                        widget.simulator.setCurrentStop(
                            widget.simulator.currentStop + 1);
                        setState(() {});
                      }
                    },
                    icon: const Icon(Icons.arrow_forward, size: 16, color: AppTheme.purpleLight),
                    label: const Text(
                      'Advance Stop',
                      style: TextStyle(color: AppTheme.purpleLight, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
