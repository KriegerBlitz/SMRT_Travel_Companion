import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Natural language search input bar accepting queries like "Bugis to Harborfront on Wheelchair"
class RouteSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onPlanPressed;
  final VoidCallback onClear;

  const RouteSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    required this.onPlanPressed,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131A26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00D26A).withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D26A).withValues(alpha: 0.08),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(
            Icons.search_rounded,
            color: Color(0xFF00D26A),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: onSubmitted,
              decoration: InputDecoration(
                hintText: 'Enter route e.g. Bugis to Harborfront on Wheelchair',
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 13,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.cancel_rounded,
                color: Colors.white.withValues(alpha: 0.4),
                size: 18,
              ),
              onPressed: onClear,
            ),
          // Action button (Plan Journey)
          Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPlanPressed,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00D26A), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00D26A).withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Plan',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.black,
                        size: 14,
                      ),
                    ],
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
