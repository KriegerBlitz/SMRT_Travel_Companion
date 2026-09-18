import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Minimalist, sleek search input formatted as: [placeholder [->]]
/// with greyed-out placeholder, white gradient accent, and arrow as the only button/icon.
/// Provides guaranteed focus and input handling on Flutter Web and mobile,
/// plus interactive quick transit suggestion pills.
class RouteSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onPlanPressed;
  final String placeholder;
  final ValueChanged<String>? onSuggestionSelected;

  const RouteSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    required this.onPlanPressed,
    this.placeholder = 'Bugis to Harborfront on Wheelchair',
    this.onSuggestionSelected,
  });

  static const List<Map<String, String>> suggestions = [
    {
      'label': 'Bugis to HarbourFront',
      'query': 'Bugis to HarbourFront on Wheelchair',
      'tag': 'Mitigation',
    },
    {
      'label': 'Jurong East to Raffles Place',
      'query': 'Jurong East to Raffles Place',
      'tag': 'Direct',
    },
    {
      'label': 'Tampines to City Hall',
      'query': 'Tampines to City Hall with Sheltered Walkways',
      'tag': 'Sheltered',
    },
    {
      'label': 'Marina Bay to Bishan',
      'query': 'Marina Bay to Bishan',
      'tag': 'Crowd',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Text Entry Bar
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (!focusNode.hasFocus) {
              focusNode.requestFocus();
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F141F),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                // Text input
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: true,
                    readOnly: false,
                    autofocus: false,
                    enableInteractiveSelection: true,
                    mouseCursor: SystemMouseCursors.text,
                    cursorColor: Colors.white,
                    cursorWidth: 2.0,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textInputAction: TextInputAction.search,
                    keyboardType: TextInputType.text,
                    onSubmitted: onSubmitted,
                    decoration: InputDecoration(
                      hintText: placeholder,
                      hintStyle: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withValues(alpha: 0.38),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),

                // Dynamic Clear Button (Visible only when text is entered)
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) {
                    if (value.text.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return IconButton(
                      icon: const Icon(
                        Icons.clear_rounded,
                        color: Colors.white60,
                        size: 18,
                      ),
                      tooltip: 'Clear search',
                      onPressed: () {
                        controller.clear();
                        focusNode.requestFocus();
                      },
                    );
                  },
                ),

                const SizedBox(width: 4),

                // [->] Arrow: Submit Button with white gradient accent
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
                              Color(0xFFE2E8F0),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.20),
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
          ),
        ),

        const SizedBox(height: 8),

        // 2. Quick Transit Suggestion Chips (Desktop mouse drag & mobile swipe enabled)
        ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
            },
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: suggestions.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: InkWell(
                    onTap: () {
                      controller.text = s['query']!;
                      focusNode.unfocus();
                      if (onSuggestionSelected != null) {
                        onSuggestionSelected!(s['query']!);
                      } else {
                        onSubmitted(s['query']!);
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            s['label']!,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withValues(alpha: 0.88),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              s['tag']!,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white70,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
