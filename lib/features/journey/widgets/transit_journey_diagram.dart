import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/journey_diagram_data.dart';

/// Renders a schematic metro diagram of the journey:
/// - Continuous vertical lines colored with official MRT line colors.
/// - Stations rendered as dots:
///   - Important stations (Origin, Interchange/Transfer, Destination) have BIGGER dots
///     with prominent labels and station code badges.
///   - Intermediate stations have smaller dots matching the line color.
/// - Multi-modal connections (Walking / Free MRT Shuttle) styled with distinct indicators.
class TransitJourneyDiagram extends StatelessWidget {
  final JourneyDiagramData diagramData;

  const TransitJourneyDiagram({
    super.key,
    required this.diagramData,
  });

  @override
  Widget build(BuildContext context) {
    if (diagramData.segments.isEmpty) {
      return const Center(
        child: Text(
          'No route steps available',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: diagramData.segments.length,
      itemBuilder: (context, index) {
        final segment = diagramData.segments[index];
        final isFirstSegment = index == 0;
        final isLastSegment = index == diagramData.segments.length - 1;

        return _buildSegmentWidget(
          context: context,
          segment: segment,
          isFirstSegment: isFirstSegment,
          isLastSegment: isLastSegment,
        );
      },
    );
  }

  Widget _buildSegmentWidget({
    required BuildContext context,
    required DiagramSegment segment,
    required bool isFirstSegment,
    required bool isLastSegment,
  }) {
    if (segment.isWalk) {
      return _buildWalkSegmentRow(segment);
    }

    if (segment.isShuttle) {
      return _buildShuttleSegmentRow(segment);
    }

    // Default: Subway train segment
    return _buildSubwaySegmentGroup(segment);
  }

  Widget _buildSubwaySegmentGroup(DiagramSegment segment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Line Header Tag (e.g. [DTL] Downtown Line · 8 mins)
        Padding(
          padding: const EdgeInsets.only(left: 38.0, top: 12.0, bottom: 8.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: segment.color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: segment.color.withValues(alpha: 0.40),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: segment.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  segment.title,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${segment.durationMinutes} min',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Ordered list of station nodes with vertical connecting line
        ...List.generate(segment.stations.length, (i) {
          final node = segment.stations[i];
          final isFirstInSegment = i == 0;
          final isLastInSegment = i == segment.stations.length - 1;

          return _buildStationRow(
            node: node,
            lineColor: segment.color,
            isFirstInSegment: isFirstInSegment,
            isLastInSegment: isLastInSegment,
          );
        }),
      ],
    );
  }

  Widget _buildStationRow({
    required DiagramStationNode node,
    required Color lineColor,
    required bool isFirstInSegment,
    required bool isLastInSegment,
  }) {
    final isImportant = node.isImportant;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: Vertical track line and station dot
          SizedBox(
            width: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Continuous connecting track line
                Positioned(
                  top: isFirstInSegment ? 16 : 0,
                  bottom: isLastInSegment ? 16 : 0,
                  child: Container(
                    width: isImportant ? 4.5 : 3.5,
                    color: lineColor,
                  ),
                ),

                // Station Dot
                if (isImportant)
                  // BIGGER dot for important stations (Origin, Interchange/Transfer, Destination)
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0F141F),
                      border: Border.all(
                        color: lineColor,
                        width: 4.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: lineColor.withValues(alpha: 0.45),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                else
                  // Smaller dot for intermediate stations
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: lineColor,
                      border: Border.all(
                        color: const Color(0xFF0F141F),
                        width: 2,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Right: Station Label and details
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: isImportant ? 10.0 : 6.0,
                horizontal: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      // Station Name
                      Flexible(
                        child: Text(
                          node.name,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: isImportant ? 15 : 12.5,
                            fontWeight: isImportant ? FontWeight.w700 : FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Station Code Badge
                      if (node.code != null && node.code!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: lineColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            node.code!,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: isImportant ? 10.5 : 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],

                      // Interchange Line Badges
                      if (isImportant && node.allCodes.length > 1) ...[
                        const SizedBox(width: 4),
                        for (final extraCode in node.allCodes.where((c) => c != node.code)) ...[
                          Container(
                            margin: const EdgeInsets.only(left: 3),
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              extraCode,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),

                  // Subtitle / Instruction (e.g. "Board towards Bukit Panjang", "Transfer")
                  if (node.subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      node.subtitle!,
                      style: GoogleFonts.plusJakartaSans(
                        color: isImportant
                            ? Colors.white.withValues(alpha: 0.70)
                            : Colors.white.withValues(alpha: 0.40),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalkSegmentRow(DiagramSegment segment) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left: Dashed line & Pedestrian walk icon
            SizedBox(
              width: 48,
              child: Center(
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: segment.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: segment.color.withValues(alpha: 0.5),
                      width: 1.2,
                    ),
                  ),
                  child: Icon(
                    Icons.directions_walk_rounded,
                    color: segment.color,
                    size: 15,
                  ),
                ),
              ),
            ),

            // Right: Walk details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          segment.instruction ?? 'Walk to connection',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (segment.isSheltered)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D26A).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'SHELTERED',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF00D26A),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        '${segment.durationMinutes} min',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShuttleSegmentRow(DiagramSegment segment) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left: Shuttle bus badge
            SizedBox(
              width: 48,
              child: Center(
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: segment.color.withValues(alpha: 0.20),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: segment.color,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.directions_bus_rounded,
                    color: segment.color,
                    size: 16,
                  ),
                ),
              ),
            ),

            // Right: Shuttle information
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: segment.color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: segment.color.withValues(alpha: 0.40),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            segment.title,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${segment.durationMinutes} min',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (segment.instruction != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          segment.instruction!,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
