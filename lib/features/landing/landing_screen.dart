import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/map/leaflet_map_view.dart';

/// Landing Page: The very first screen the commuter sees.
///
/// Features:
/// - Locked to vertical mobile aspect ratio with ambient sidebars on desktop.
/// - Live Singapore Leaflet map in the background with dynamic blur.
/// - Large modern editorial typography: "Where to next?" with distinct
///   fonts, sizes, and weights for each word.
/// - Transitions to the Home Screen on tap or ANY keystroke.
class LandingScreen extends StatefulWidget {
  final VoidCallback onTransitionToHome;

  const LandingScreen({
    super.key,
    required this.onTransitionToHome,
  });

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  bool _hasTransitioned = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Intercept any hardware key press to trigger the transition
    HardwareKeyboard.instance.addHandler(_handleAnyKeyPress);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleAnyKeyPress);
    _pulseController.dispose();
    super.dispose();
  }

  bool _handleAnyKeyPress(KeyEvent event) {
    if (event is KeyDownEvent && !_hasTransitioned) {
      _triggerTransition();
      return false; // let other handlers (e.g. Konami code) still receive it
    }
    return false;
  }

  void _triggerTransition() {
    if (_hasTransitioned) return;
    setState(() => _hasTransitioned = true);
    widget.onTransitionToHome();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _triggerTransition,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Live Singapore Leaflet Map (Blurred in Background)
            const Positioned.fill(
              child: LeafletMapView(
                initialLat: 1.3521,
                initialLng: 103.8198,
                initialZoom: 12.0,
                isBlurred: true,
              ),
            ),

            // 2. Additional Frosted Glass Vignette & Tint Overlay for Pristine Readability
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.black.withValues(alpha: 0.50),
                        Colors.black.withValues(alpha: 0.82),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // 3. Foreground Content & Typography
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Brand Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.20),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF00D26A), // SMRT green pulse
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'SMRT · COMPANION',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 3),

                    // "Where to next?" Editorial Typography
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Word 1: "Where" (Sophisticated Editorial Serif)
                        Text(
                          'Where',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 72,
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                            color: Colors.white,
                            letterSpacing: -1.5,
                            height: 0.95,
                          ),
                        ),

                        // Word 2: "to" (Luminous Electric Accent Script)
                        Padding(
                          padding: const EdgeInsets.only(left: 12.0, top: 4.0, bottom: 4.0),
                          child: Text(
                            'to',
                            style: GoogleFonts.caveat(
                              fontSize: 54,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF38BDF8), // Electric cyan accent
                              height: 0.9,
                            ),
                          ),
                        ),

                        // Word 3: "next?" (Monumental Ultra-Bold Modern Sans)
                        Text(
                          'next?',
                          style: GoogleFonts.outfit(
                            fontSize: 86,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFF8FAFC),
                            letterSpacing: -3.5,
                            height: 0.88,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.45),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Spacer(flex: 4),

                    // Bottom Pulsing Call to Action Indicator
                    Center(
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _pulseAnimation.value,
                            child: child,
                          );
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Tap anywhere or press any key',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 26,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
