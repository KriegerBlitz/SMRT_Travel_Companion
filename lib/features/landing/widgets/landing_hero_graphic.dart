import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modular Landing Hero Graphic.
///
/// Designed for zero-friction replacement:
/// - Defaults to the current editorial "Where to NEXT?" typography.
/// - If a custom Canva image or vector asset is provided later, simply pass [customAssetPath].
class LandingHeroGraphic extends StatelessWidget {
  /// Optional path to a future custom Canva asset (e.g. 'assets/images/where_to_next.png')
  final String? customAssetPath;

  const LandingHeroGraphic({
    super.key,
    this.customAssetPath,
  });

  @override
  Widget build(BuildContext context) {
    if (customAssetPath != null) {
      return SizedBox(
        width: double.infinity,
        child: Image.asset(
          customAssetPath!,
          fit: BoxFit.contain,
          alignment: Alignment.bottomLeft,
        ),
      );
    }

    return const DefaultLandingTypography();
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
