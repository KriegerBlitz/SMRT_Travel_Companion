import 'package:flutter/material.dart';
import '../services/lta_models.dart';
import '../services/simulator_service.dart';
import 'theme.dart';

class SimulatorScreen extends StatefulWidget {
  final SimulatorService simulator;
  final VoidCallback? onClose;

  const SimulatorScreen({
    super.key,
    required this.simulator,
    this.onClose,
  });

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  final List<String> _stops = [
    'Jurong East',
    'Bukit Batok',
    'Bukit Gombak',
    'Novena',
    'Newton',
    'Orchard',
    'Somerset',
    'Dhoby Ghaut',
    'City Hall',
  ];

  @override
  Widget build(BuildContext context) {
    final simulator = widget.simulator;
    final isMockData = simulator.isSimulated;
    final crowdLevel = simulator.forcedCrowdLevel;
    final currentStopIndex = simulator.currentStop.clamp(1, 9);
    final currentStopName = _stops[currentStopIndex - 1];
    final isDisrupted = simulator.forceDisruption;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Simulator + DEV ONLY badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Simulator',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.amberWarning,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'DEV ONLY',
                          style: TextStyle(
                            color: Color(0xFF1F1A14),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.onClose != null)
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: AppTheme.textSecondary),
                      onPressed: widget.onClose,
                    ),
                ],
              ),

              const SizedBox(height: 18),

              // Yellow/Amber Banner: SIMULATED DATA — not live
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.amberBannerBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.amberWarning.withValues(alpha: 0.8),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppTheme.amberWarning,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'SIMULATED DATA — not live',
                      style: TextStyle(
                        color: AppTheme.amberWarning,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Segmented Tabs: [Live API] [Mock data]
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          simulator.applyScenario(DemoScenario.live);
                          setState(() {});
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !isMockData
                                ? AppTheme.purplePrimary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Live API',
                            style: TextStyle(
                              color: !isMockData
                                  ? Colors.white
                                  : AppTheme.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          if (!isMockData) {
                            simulator.applyScenario(DemoScenario.rachelDisruption);
                            setState(() {});
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isMockData
                                ? AppTheme.purplePrimary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Mock data',
                            style: TextStyle(
                              color: isMockData
                                  ? Colors.white
                                  : AppTheme.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // SCENARIO PRESETS Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PRESET SCENARIOS',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...DemoScenario.values.map((scenario) {
                      final isSelected = simulator.activeScenario == scenario;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () {
                            simulator.applyScenario(scenario);
                            setState(() {});
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.purplePillBg : AppTheme.cardBgSecondary,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? AppTheme.purplePrimary : AppTheme.cardBorder,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                  size: 16,
                                  color: isSelected ? AppTheme.purpleLight : AppTheme.textMuted,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        scenario.title,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : AppTheme.textPrimary,
                                          fontSize: 13,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        scenario.description,
                                        style: const TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 11,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // CROWD LEVEL OVERRIDE Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: AppTheme.cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CROWD LEVEL OVERRIDE',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Station: Jurong East',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 3 crowd level pills
                    Row(
                      children: [
                        _buildCrowdButton(
                          title: 'Low',
                          isSelected: crowdLevel == CrowdLevel.low,
                          activeColor: AppTheme.cardBgSecondary,
                          textColor: Colors.white,
                          onTap: () {
                            simulator.setCrowdLevel(CrowdLevel.low);
                            setState(() {});
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildCrowdButton(
                          title: 'Med',
                          isSelected: crowdLevel == CrowdLevel.moderate,
                          activeColor: AppTheme.amberWarning,
                          textColor: Colors.black,
                          onTap: () {
                            simulator.setCrowdLevel(CrowdLevel.moderate);
                            setState(() {});
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildCrowdButton(
                          title: 'High',
                          isSelected: crowdLevel == CrowdLevel.high,
                          activeColor: const Color(0xFFDC2626), // Red
                          textColor: Colors.white,
                          onTap: () {
                            simulator.setCrowdLevel(CrowdLevel.high);
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // DEAD-RECKONING TIMER Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: AppTheme.cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DEAD-RECKONING TIMER',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Current stop: $currentStopIndex of 9',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stepper: [-] Novena [+]
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: currentStopIndex > 1
                              ? () {
                                  simulator.setCurrentStop(currentStopIndex - 1);
                                  setState(() {});
                                }
                              : null,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 48,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.cardBgSecondary,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.cardBorder),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              '–',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          currentStopName,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        InkWell(
                          onTap: currentStopIndex < 9
                              ? () {
                                  simulator.setCurrentStop(currentStopIndex + 1);
                                  setState(() {});
                                }
                              : null,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 48,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.cardBgSecondary,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.cardBorder),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              '+',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // FACILITY & WEATHER OVERRIDES Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FACILITY & WEATHER OVERRIDES',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Lift Outage (Outram Park / Dhoby Ghaut)',
                            style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                          ),
                        ),
                        Switch.adaptive(
                          value: simulator.forceLiftOutage,
                          onChanged: (val) {
                            simulator.toggleLiftOutage(val);
                            setState(() {});
                          },
                          activeThumbColor: AppTheme.amberWarning,
                        ),
                      ],
                    ),
                    const Divider(color: AppTheme.cardBorder, height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Rain Nowcast (Trigger CoveredLinkWay)',
                            style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                          ),
                        ),
                        Switch.adaptive(
                          value: simulator.forceRainNowcast,
                          onChanged: (val) {
                            simulator.toggleRainNowcast(val);
                            setState(() {});
                          },
                          activeThumbColor: AppTheme.purpleLight,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Trigger disruption Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    simulator.toggleDisruption(!isDisrupted);
                    if (!isDisrupted) {
                      simulator.toggleCrowdForecastSpike(true);
                      simulator.setCrowdLevel(CrowdLevel.high);
                    }
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          !isDisrupted
                              ? '🚨 Disruption triggered! EWL Signal Fault & Free Shuttle activated.'
                              : '✅ Disruption cleared. Restored normal operations.',
                        ),
                        backgroundColor: !isDisrupted
                            ? const Color(0xFFDC2626)
                            : AppTheme.greenSuccess,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDisrupted
                        ? const Color(0xFF4B1D1D)
                        : const Color(0xFFDC2626), // Deep red
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    isDisrupted ? 'Disruption Active (Tap to Clear)' : 'Trigger disruption',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCrowdButton({
    required String title,
    required bool isSelected,
    required Color activeColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : AppTheme.cardBgSecondary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? activeColor : AppTheme.cardBorder,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? textColor : AppTheme.textMuted,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
