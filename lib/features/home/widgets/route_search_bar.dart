import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Minimalist, sleek search input formatted as: [placeholder [->]]
/// with greyed-out placeholder, white gradient accent, and arrow as the only button/icon.
class RouteSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onPlanPressed;
  final String placeholder;

  const RouteSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    required this.onPlanPressed,
    this.placeholder = 'Bugis to Harborfront on Wheelchair',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F141F).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          // Greyed-out placeholder & sleek white text input
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              cursorColor: Colors.white,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: onSubmitted,
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // [->] Arrow: The ONLY button or icon, styled with white-to-light-grey gradient
          Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPlanPressed,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Color(0xFFE2E8F0), // Subtle white-to-platinum gradient
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.18),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.black,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
