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
/// - Typography at the bottom, left justified:
///   - "Where" (editorial serif) and "to" (white flowing cursive) side by side.
///   - "NEXT?" as wide as the cutout, bold "NEXT", non-bold "?".
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

class _LandingScreenState extends State<LandingScreen> {
  bool _hasTransitioned = false;

  @override
  void initState() {
    super.initState();
    // Intercept any hardware key press on PC to trigger the transition
    HardwareKeyboard.instance.addHandler(_handleAnyKeyPress);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleAnyKeyPress);
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

            // 2. Frosted Glass Vignette & Tint Overlay for Maximum Text Contrast
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.30),
                        Colors.black.withValues(alpha: 0.50),
                        Colors.black.withValues(alpha: 0.85),
                      ],
                      stops: const [0.0, 0.40, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // 3. Foreground Content & Typography (Bottom & Left Justified)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
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
                              color: Color(0xFF00D26A), // SMRT green beacon
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

                    // Push content down to the bottom
                    const Spacer(),

                    // "Where" and "to" side by side above NEXT?
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            'Where',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 52,
                              fontWeight: FontWeight.w700,
                              fontStyle: FontStyle.italic,
                              color: Colors.white,
                              letterSpacing: -1.2,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            'to',
                            style: GoogleFonts.greatVibes(
                              fontSize: 54,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 2),

                    // "NEXT?" as wide as the cutout, bold NEXT, unbolded ?
                    SizedBox(
                      width: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.fitWidth,
                        alignment: Alignment.centerLeft,
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'NEXT',
                                style: GoogleFonts.outfit(
                                  fontSize: 120,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -2.0,
                                ),
                              ),
                              TextSpan(
                                text: '?',
                                style: GoogleFonts.outfit(
                                  fontSize: 120,
                                  fontWeight: FontWeight.w300, // Light / non-bold
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
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
