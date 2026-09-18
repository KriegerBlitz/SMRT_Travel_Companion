import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modular Landing Hero Graphic.
///
/// Now uses the actual [assets/data/NEXT.svg] Canva export.
/// The SVG paths are black (#000000); a [ColorFilter] inverts them to white
/// for the dark landing screen background.
///
/// [DefaultLandingTypography] is retained as a programmatic fallback in case
/// the asset is unavailable, but is no longer the primary render path.
class LandingHeroGraphic extends StatelessWidget {
  /// Optional path to a future custom Canva asset (defaults to 'assets/data/NEXT.svg')
  final String? customAssetPath;

  const LandingHeroGraphic({super.key, this.customAssetPath});

  static const String _defaultSvgPath = 'assets/NEXT.svg';

  @override
  Widget build(BuildContext context) {
    final assetPath = customAssetPath ?? _defaultSvgPath;

    return SizedBox(
      width: double.infinity,
      child: Transform.scale(
        scale: 0.98,
        alignment: Alignment.bottomCenter,
        child: SvgPicture.asset(
          assetPath,
          // SVG fill is black — invert to white for the dark background
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          fit: BoxFit.fitWidth,
          alignment: Alignment.bottomCenter,
          placeholderBuilder: (_) => const DefaultLandingTypography(),
        ),
      ),
    );
  }
}

/// The partitioned typography design:
/// - "Where" (editorial serif) & "to" (white cursive script) side by side
/// - Towering "NEXT?" in ultra-tall Bebas Neue font, bold, full-width left-justified
class DefaultLandingTypography extends StatelessWidget {
  const DefaultLandingTypography({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "Where" and "to" side by side
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'Where',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 54,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                    letterSpacing: -1.2,
                    height: 0.95,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  'to',
                  style: GoogleFonts.greatVibes(
                    fontSize: 56,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    height: 0.95,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Tightly stacked "NEXT?" in ultra-tall Bebas Neue font, bold, full width
        Transform.translate(
          offset: const Offset(0, -6),
          child: SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.fitWidth,
              alignment: Alignment.centerLeft,
              child: Text(
                'NEXT?',
                style: GoogleFonts.bebasNeue(
                  fontSize: 160,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                  height: 0.85,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
