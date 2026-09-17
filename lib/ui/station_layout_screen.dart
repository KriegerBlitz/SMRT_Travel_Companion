import 'package:flutter/material.dart';
import '../core/canonical_line_codes.dart';
import 'theme.dart';

class StationLayoutScreen extends StatefulWidget {
  final ValueChanged<StationInfo>? onStationSelected;

  const StationLayoutScreen({
    super.key,
    this.onStationSelected,
  });

  @override
  State<StationLayoutScreen> createState() => _StationLayoutScreenState();
}

class _StationLayoutScreenState extends State<StationLayoutScreen> {
  late final TextEditingController _searchController;
  StationInfo? _selectedStation;
  List<StationInfo> _searchResults = [];

  final List<String> _bundledOfflineStations = [
    'Jurong East',
    'Pioneer',
    'Dhoby Ghaut',
    'City Hall',
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: 'Jurong East');
    _selectedStation = CanonicalLineCodes.stations.firstWhere(
      (s) => s.name.toLowerCase() == 'jurong east',
      orElse: () => CanonicalLineCodes.stations.first,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  MRTLine? _selectedLine;

  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _searchResults = CanonicalLineCodes.stations
          .where((s) =>
              s.name.toLowerCase().contains(q) || s.code.toLowerCase().contains(q))
          .take(5)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final stationName = _selectedStation?.name ?? 'Jurong East';

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Station map',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 18),

              // Search Bar
              Container(
                decoration: AppTheme.cardDecoration(
                  bgColor: AppTheme.cardBg,
                  radius: 14,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppTheme.textMuted, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search station...',
                          hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                          border: InputBorder.none,
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.textMuted, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // MRT/LRT Line Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildLineFilterChip(null, 'All (165)'),
                    const SizedBox(width: 6),
                    ...MRTLine.values.map((line) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _buildLineFilterChip(line, line.displayName),
                        )),
                  ],
                ),
              ),

              if (_selectedLine != null) ...[
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: CanonicalLineCodes.getStationsForLine(_selectedLine!).map((stn) {
                      final isCurrent = _selectedStation?.code == stn.code;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedStation = stn;
                              _searchController.text = stn.name;
                            });
                            widget.onStationSelected?.call(stn);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isCurrent ? AppTheme.purplePrimary : AppTheme.cardBgSecondary,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isCurrent ? AppTheme.purpleLight : AppTheme.cardBorder),
                            ),
                            child: Text(
                              '${stn.code} ${stn.name}',
                              style: TextStyle(
                                color: isCurrent ? Colors.white : AppTheme.textSecondary,
                                fontSize: 11,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              // Search Auto-complete suggestions
              if (_searchResults.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: AppTheme.cardDecoration(),
                  child: Column(
                    children: _searchResults.map((stn) {
                      return ListTile(
                        dense: true,
                        leading: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: stn.primaryLine.color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            stn.code,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          stn.name,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedStation = stn;
                            _searchController.text = stn.name;
                            _searchResults = [];
                          });
                          widget.onStationSelected?.call(stn);
                        },
                      );
                    }).toList(),
                  ),
                ),

              const SizedBox(height: 18),

              // Platform Layout Diagram Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                decoration: AppTheme.cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${stationName.toUpperCase()} · PLATFORM LAYOUT',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Schematic Diagram
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Column(
                          children: [
                            // NS Line Platform Bar (Purple)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF282046),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.purpleLight.withValues(alpha: 0.5),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'NS line platform',
                                style: TextStyle(
                                  color: Color(0xFFDDD6FE),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            // Connecting vertical lines
                            SizedBox(
                              height: 38,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Container(width: 1.5, color: AppTheme.cardBorder),
                                  Container(width: 1.5, color: AppTheme.cardBorder),
                                ],
                              ),
                            ),

                            // EW Line Platform Bar (Brown/Amber)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF38260F),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.amberWarning.withValues(alpha: 0.4),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'EW line platform',
                                style: TextStyle(
                                  color: Color(0xFFFDE68A),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            // Connecting vertical line to Concourse
                            Container(
                              height: 34,
                              width: 1.5,
                              color: AppTheme.cardBorder,
                            ),

                            // Concourse box
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 22, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF23262D),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.cardBorder),
                              ),
                              child: const Text(
                                'Concourse',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 56),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Offline / Online station availability notes
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: const BoxDecoration(
                      color: AppTheme.purpleLight,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bundled offline: ${_bundledOfflineStations.join(', ')}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: const BoxDecoration(
                      color: AppTheme.textMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Other stations open via browser link',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLineFilterChip(MRTLine? line, String label) {
    final isSelected = _selectedLine == line;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedLine = line;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? (line?.color ?? AppTheme.purplePrimary) : AppTheme.cardBgSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? (line?.color ?? AppTheme.purpleLight) : AppTheme.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textMuted,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
