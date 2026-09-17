import 'package:flutter/material.dart';
import '../../core/canonical_line_codes.dart';
import '../../services/lta_models.dart';

class AllStationsView extends StatefulWidget {
  final Map<String, StationCrowdInfo> crowdMap;
  final void Function(StationInfo station) onStationSelected;

  const AllStationsView({
    super.key,
    required this.crowdMap,
    required this.onStationSelected,
  });

  @override
  State<AllStationsView> createState() => _AllStationsViewState();
}

class _AllStationsViewState extends State<AllStationsView> {
  String _searchQuery = '';
  MRTLine? _selectedLineFilter;

  @override
  Widget build(BuildContext context) {
    // Filter stations
    final query = _searchQuery.trim().toLowerCase();
    final filtered = CanonicalLineCodes.stations.where((stn) {
      // Line filter
      if (_selectedLineFilter != null) {
        final matchesLine = CanonicalLineCodes.stationServesLine(stn, _selectedLineFilter!);
        if (!matchesLine) return false;
      }
      // Text search
      if (query.isNotEmpty) {
        final matchesName = stn.name.toLowerCase().contains(query);
        final matchesCode = stn.code.toLowerCase().contains(query) ||
            stn.allCodes.any((c) => c.toLowerCase().contains(query));
        if (!matchesName && !matchesCode) return false;
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Directory Header Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.teal.shade700),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.hub_outlined, color: Colors.tealAccent, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'All Singapore MRT & LRT Stations',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade900,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.tealAccent),
                    ),
                    child: Text(
                      '${filtered.length} / ${CanonicalLineCodes.stations.length}',
                      style: const TextStyle(
                        color: Colors.tealAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Complete directory across EWL, NSL, NEL, CCL, DTL, TEL, BPLRT, SLRT, and PLRT. Tap any station to center on the live map.',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(height: 12),

              // Search Box
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search station by name or code (e.g. Bedok, TE29, Jurong...)',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                  filled: true,
                  fillColor: Colors.black38,
                  prefixIcon: const Icon(Icons.search, color: Colors.tealAccent, size: 18),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white60, size: 16),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blueGrey.shade700),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Line Filter Scroll
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(null, 'All Lines (${CanonicalLineCodes.stations.length})', Colors.blueGrey),
              ...MRTLine.values.map((line) {
                final count = CanonicalLineCodes.getStationsForLine(line).length;
                return _buildFilterChip(line, '${line.code} ($count)', line.color);
              }),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Station Cards List
        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            child: const Text(
              'No stations match your filter.',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            itemBuilder: (context, idx) {
              final stn = filtered[idx];
              final crowd = widget.crowdMap[stn.code]?.realTime ?? CrowdLevel.low;

              Color crowdColor = const Color(0xFF22C55E);
              if (crowd == CrowdLevel.high) {
                crowdColor = const Color(0xFFEF4444);
              } else if (crowd == CrowdLevel.moderate) {
                crowdColor = const Color(0xFFF59E0B);
              }

              return Card(
                color: const Color(0xFF1E293B),
                margin: const EdgeInsets.only(bottom: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.blueGrey.shade800),
                ),
                child: InkWell(
                  onTap: () => widget.onStationSelected(stn),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        // Line color indicator bar
                        Container(
                          width: 4,
                          height: 36,
                          decoration: BoxDecoration(
                            color: stn.primaryLine.color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Station codes pills
                        Wrap(
                          spacing: 4,
                          children: stn.allCodes.map((code) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: stn.primaryLine.color.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: stn.primaryLine.color.withValues(alpha: 0.8)),
                              ),
                              child: Text(
                                code,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(width: 10),

                        // Station Name & line
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      stn.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (stn.isInterchange) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade900,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: const Text(
                                        'INT',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                stn.primaryLine.displayName,
                                style: TextStyle(color: Colors.white54, fontSize: 10),
                              ),
                            ],
                          ),
                        ),

                        // Real-time crowd pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: crowdColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: crowdColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: crowdColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                crowd.label.toUpperCase(),
                                style: TextStyle(
                                  color: crowdColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.chevron_right, color: Colors.white38, size: 16),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildFilterChip(MRTLine? line, String label, Color color) {
    final isSelected = _selectedLineFilter == line;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        selected: isSelected,
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        backgroundColor: const Color(0xFF1E293B),
        selectedColor: color.withValues(alpha: 0.35),
        side: BorderSide(
          color: isSelected ? color : Colors.blueGrey.shade700,
          width: isSelected ? 1.5 : 1,
        ),
        checkmarkColor: Colors.white,
        showCheckmark: false,
        onSelected: (_) {
          setState(() {
            _selectedLineFilter = isSelected ? null : line;
          });
        },
      ),
    );
  }
}
