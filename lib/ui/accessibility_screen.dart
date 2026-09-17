import 'package:flutter/material.dart';
import '../services/accessibility_helper.dart';
import 'theme.dart';

class AccessibilityScreen extends StatefulWidget {
  final bool isHighContrast;
  final ValueChanged<bool> onToggleHighContrast;

  const AccessibilityScreen({
    super.key,
    required this.isHighContrast,
    required this.onToggleHighContrast,
  });

  @override
  State<AccessibilityScreen> createState() => _AccessibilityScreenState();
}

class _AccessibilityScreenState extends State<AccessibilityScreen> {
  bool _isPlayingSpeech = false;
  String? _activeHapticFeedback;

  final String _announcementText =
      'Lift B at Dhoby Ghaut is under maintenance. Forecast crowd rising ahead.';

  void _handleSpeak() {
    setState(() => _isPlayingSpeech = true);
    AccessibilityHelper.speakText(_announcementText);
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _isPlayingSpeech = false);
    });
  }

  void _handleTestHaptic(HapticPattern pattern, String name) {
    setState(() => _activeHapticFeedback = name);
    AccessibilityHelper.triggerHaptic(pattern);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Vibration triggered: $name'),
        duration: const Duration(milliseconds: 1500),
        backgroundColor: AppTheme.purplePrimary,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _activeHapticFeedback = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Title
              const Text(
                'Accessibility',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 20),

              // Card 1: READ ALOUD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: AppTheme.cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'READ ALOUD',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: _handleSpeak,
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: AppTheme.purplePrimary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isPlayingSpeech
                                  ? Icons.volume_up_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            '"$_announcementText"',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Card 2: HAPTIC PATTERNS
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: AppTheme.cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HAPTIC PATTERNS',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pattern 1: Get off
                    _buildHapticRow(
                      icon: Icons.signal_cellular_alt_rounded,
                      title: 'Get off',
                      onTest: () => _handleTestHaptic(
                        HapticPattern.timeToGetOff,
                        'Get off',
                      ),
                      isActive: _activeHapticFeedback == 'Get off',
                    ),

                    const SizedBox(height: 14),

                    // Pattern 2: Change line
                    _buildHapticRow(
                      icon: Icons.pause_rounded,
                      title: 'Change line',
                      onTest: () => _handleTestHaptic(
                        HapticPattern.needToChangeLines,
                        'Change line',
                      ),
                      isActive: _activeHapticFeedback == 'Change line',
                    ),

                    const SizedBox(height: 14),

                    // Pattern 3: Service pause
                    _buildHapticRow(
                      icon: Icons.equalizer_rounded,
                      title: 'Service pause',
                      onTest: () => _handleTestHaptic(
                        HapticPattern.serviceDisrupted,
                        'Service pause',
                      ),
                      isActive: _activeHapticFeedback == 'Service pause',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Card 3: Route familiarity
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: AppTheme.cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Route familiarity',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.purplePillBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.purpleLight.withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Text(
                            'Familiar · 12 visits',
                            style: TextStyle(
                              color: Color(0xFFC4B5FD),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Alerts are shown less often on routes you take often, to avoid fatigue',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Card 4: High-contrast & large text toggle
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: AppTheme.cardDecoration(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'High-contrast & large text',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Switch.adaptive(
                      value: widget.isHighContrast,
                      onChanged: widget.onToggleHighContrast,
                      activeThumbColor: AppTheme.purplePrimary,
                      activeTrackColor: AppTheme.purpleLight.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHapticRow({
    required IconData icon,
    required String title,
    required VoidCallback onTest,
    required bool isActive,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.purpleLight, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        InkWell(
          onTap: onTest,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Text(
              isActive ? 'Vibrating...' : 'Test',
              style: TextStyle(
                color: isActive ? AppTheme.greenSuccess : AppTheme.purpleLight,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
