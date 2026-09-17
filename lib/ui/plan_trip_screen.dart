import 'package:flutter/material.dart';
import '../ai/trip_input_parser.dart';
import '../services/simulator_service.dart';
import 'theme.dart';

class PlanTripScreen extends StatefulWidget {
  final SimulatorService simulator;
  final VoidCallback? onBack;
  final VoidCallback onStartTrip;

  const PlanTripScreen({
    super.key,
    required this.simulator,
    this.onBack,
    required this.onStartTrip,
  });

  @override
  State<PlanTripScreen> createState() => _PlanTripScreenState();
}

class _PlanTripScreenState extends State<PlanTripScreen> {
  late final TextEditingController _controller;
  int _selectedRouteIndex = 1; // 0: Original EW, 1: Alternative Shuttle
  ParsedTripIntent? _parsedIntent;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: 'Get me from Tampines to Raffles Place avoiding crowds',
    );
    _parseCurrentQuery();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _parseCurrentQuery() {
    setState(() {
      _parsedIntent = TripInputParser.parse(_controller.text);
    });
  }

  String _formatPref(String? pref) {
    if (pref == null) return 'avoid crowds';
    switch (pref) {
      case 'avoid_crowds':
        return 'avoid crowds';
      case 'step_free':
        return 'step-free';
      case 'sheltered':
        return 'sheltered';
      case 'fastest':
        return 'fastest';
      default:
        return pref.replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisrupted = widget.simulator.forceDisruption;
    final isCrowdSpike = widget.simulator.forceCrowdForecastSpike;
    final isLiftDown = widget.simulator.forceLiftOutage;

    // Derived values
    final etaMinutes = _selectedRouteIndex == 0
        ? 22
        : _selectedRouteIndex == 1
            ? 37
            : 34;
    final etaConfidence = isDisrupted || isCrowdSpike ? 'Amber' : 'High';
    final etaConfidenceColor =
        isDisrupted || isCrowdSpike ? AppTheme.amberWarning : AppTheme.greenSuccess;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Back Button
                    Row(
                      children: [
                        if (widget.onBack != null)
                          InkWell(
                            onTap: widget.onBack,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.cardBg,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.cardBorder),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: AppTheme.textPrimary,
                                size: 16,
                              ),
                            ),
                          ),
                        if (widget.onBack != null) const SizedBox(width: 14),
                        const Text(
                          'Plan a trip',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Query Search Bar
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
                              controller: _controller,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Where to? (e.g. Tampines to Raffles Place)',
                                hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                                border: InputBorder.none,
                              ),
                              onChanged: (_) => _parseCurrentQuery(),
                              onSubmitted: (_) => _parseCurrentQuery(),
                            ),
                          ),
                          if (_controller.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear, color: AppTheme.textMuted, size: 18),
                              onPressed: () {
                                _controller.clear();
                                _parseCurrentQuery();
                              },
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Parsed Tags Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Parsed: ',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildParsedTag(
                                  _parsedIntent?.fromStation != null
                                      ? 'from ${_parsedIntent!.fromStation}'
                                      : 'from Tampines',
                                ),
                                const SizedBox(width: 6),
                                _buildParsedTag(
                                  _parsedIntent?.toStation != null
                                      ? 'to ${_parsedIntent!.toStation}'
                                      : 'to Raffles Place',
                                ),
                                const SizedBox(width: 6),
                                _buildParsedTag(
                                  _formatPref(_parsedIntent?.preference),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Quick Benchmark Query Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildSampleQueryChip('Tampines to Raffles Place avoiding crowds'),
                          const SizedBox(width: 8),
                          _buildSampleQueryChip('Bedok to SGH with wheelchair access'),
                          const SizedBox(width: 8),
                          _buildSampleQueryChip('Bugis to Jurong avoiding crowds'),
                          const SizedBox(width: 8),
                          _buildSampleQueryChip('City Hall to Changi Airport sheltered from rain'),
                          const SizedBox(width: 8),
                          _buildSampleQueryChip('Woodlands to Marina Bay'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Rerouted Alert Banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.amberBannerBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.amberWarning.withValues(alpha: 0.9), width: 1.2),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.refresh_rounded,
                              color: AppTheme.amberWarning,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isLiftDown
                                  ? 'Rerouted: lift down at Somerset. Take the free shuttle bus from Tampines — leave 10 min earlier.'
                                  : 'Rerouted: heavy crowd alert on EW Line. Alternative express connection recommended — leave 10 min earlier.',
                              style: const TextStyle(
                                color: Color(0xFFFED7AA),
                                fontSize: 13,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Route Option Cards Container
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: AppTheme.cardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Route 1 (Original EW direct)
                          InkWell(
                            onTap: () => setState(() => _selectedRouteIndex = 0),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedRouteIndex == 0
                                    ? AppTheme.purplePillBg
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: _selectedRouteIndex == 0
                                    ? Border.all(color: AppTheme.purplePrimary, width: 1.2)
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF009645), // EW green
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'EW',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Tampines → Raffles Place',
                                          style: TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(Icons.circle, size: 6, color: AppTheme.textMuted),
                                            SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                'Original · EW line direct',
                                                style: TextStyle(
                                                  color: AppTheme.textMuted,
                                                  fontSize: 12,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Text(
                                    '22 min',
                                    style: TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),

                          // Route 2 (Alternative Shuttle)
                          InkWell(
                            onTap: () => setState(() => _selectedRouteIndex = 1),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedRouteIndex == 1
                                    ? AppTheme.purplePillBg
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: _selectedRouteIndex == 1
                                    ? Border.all(color: AppTheme.purplePrimary, width: 1.2)
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.circle, size: 8, color: AppTheme.purpleLight),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Alternative · Shuttle from Tampines',
                                      style: TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '37 min',
                                    style: TextStyle(
                                      color: _selectedRouteIndex == 1
                                          ? AppTheme.textPrimary
                                          : AppTheme.textMuted,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),

                          // Route 3 (Accessible WAB Bus 147 · Step-free)
                          InkWell(
                            onTap: () => setState(() => _selectedRouteIndex = 2),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedRouteIndex == 2
                                    ? AppTheme.purplePillBg
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: _selectedRouteIndex == 2
                                    ? Border.all(color: AppTheme.purplePrimary, width: 1.2)
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.accessible_rounded, size: 14, color: AppTheme.greenSuccess),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Accessible · WAB Bus 147 (Sheltered)',
                                      style: TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '34 min',
                                    style: TextStyle(
                                      color: _selectedRouteIndex == 2
                                          ? AppTheme.textPrimary
                                          : AppTheme.textMuted,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const Divider(color: AppTheme.cardBorder, height: 28),

                          // Confidence-scored ETA Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Confidence-scored ETA',
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                etaConfidence,
                                style: TextStyle(
                                  color: etaConfidenceColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          // Large Display
                          Text(
                            '$etaMinutes min',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -1,
                            ),
                          ),

                          const SizedBox(height: 2),

                          Text(
                            _selectedRouteIndex == 0
                                ? 'Direct train · Normal line frequency'
                                : _selectedRouteIndex == 1
                                    ? (isDisrupted
                                        ? '+15 min vs. usual · crowd rising, 1 active alert'
                                        : '+15 min vs. usual · alternative shuttle connection')
                                    : '100% step-free · WAB Bus 147 (18 seats) · CoveredLinkWay sheltered',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Dynamic advice / crowd recommendation row
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBgSecondary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _selectedRouteIndex == 2
                                      ? Icons.accessible_rounded
                                      : Icons.luggage_outlined,
                                  color: _selectedRouteIndex == 2
                                      ? AppTheme.greenSuccess
                                      : AppTheme.textSecondary,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selectedRouteIndex == 2
                                        ? 'Step-free route verified · Lift A at Exit 3 available'
                                        : 'Car 4 is less crowded on this route',
                                    style: TextStyle(
                                      color: _selectedRouteIndex == 2
                                          ? AppTheme.greenSuccess
                                          : AppTheme.textSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Start Trip Coral Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: widget.onStartTrip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.coralCTA,
                    foregroundColor: const Color(0xFF121316),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Start trip',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParsedTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.purplePillBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.purpleLight.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFDDD6FE),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSampleQueryChip(String query) {
    return InkWell(
      onTap: () {
        _controller.text = query;
        _parseCurrentQuery();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.cardBgSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt, size: 13, color: AppTheme.amberWarning),
            const SizedBox(width: 4),
            Text(
              query,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
