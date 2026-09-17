import 'package:flutter/material.dart';
import '../services/simulator_service.dart';
import 'accessibility_screen.dart';
import 'home_dashboard_screen.dart';
import 'in_transit_screen.dart';
import 'plan_trip_screen.dart';
import 'route_map_screen.dart';
import 'simulator_screen.dart';
import 'station_layout_screen.dart';
import 'theme.dart';

typedef RedesignShell = MainShell;

class MainShell extends StatefulWidget {
  final SimulatorService simulator;

  const MainShell({
    super.key,
    required this.simulator,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _activeTab = 0; // 0: Home, 1: Plan, 2: Map, 3: Transit, 4: Access, 5: Layout
  bool _isHighContrast = false;

  @override
  void initState() {
    super.initState();
    widget.simulator.addListener(_onSimulatorChanged);
  }

  @override
  void dispose() {
    widget.simulator.removeListener(_onSimulatorChanged);
    super.dispose();
  }

  void _onSimulatorChanged() {
    if (mounted) setState(() {});
  }

  void _openSimulatorModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: const BoxDecoration(
          color: AppTheme.bgDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SimulatorScreen(
                simulator: widget.simulator,
                onClose: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine current screen
    Widget screenContent;
    switch (_activeTab) {
      case 0:
        screenContent = HomeDashboardScreen(
          simulator: widget.simulator,
          onPlanTrip: () => setState(() => _activeTab = 1),
          onOpenSimulator: _openSimulatorModal,
          onOpenAccessibility: () => setState(() => _activeTab = 4),
          onOpenStationMap: () => setState(() => _activeTab = 5),
        );
        break;
      case 1:
        screenContent = PlanTripScreen(
          simulator: widget.simulator,
          onBack: () => setState(() => _activeTab = 0),
          onStartTrip: () => setState(() => _activeTab = 3),
        );
        break;
      case 2:
        screenContent = RouteMapScreen(
          simulator: widget.simulator,
          onBack: () => setState(() => _activeTab = 0),
        );
        break;
      case 3:
        screenContent = InTransitScreen(
          simulator: widget.simulator,
          onBack: () => setState(() => _activeTab = 0),
        );
        break;
      case 4:
        screenContent = AccessibilityScreen(
          isHighContrast: _isHighContrast,
          onToggleHighContrast: (val) => setState(() => _isHighContrast = val),
        );
        break;
      case 5:
        screenContent = StationLayoutScreen(
          onStationSelected: (_) {},
        );
        break;
      default:
        screenContent = HomeDashboardScreen(
          simulator: widget.simulator,
          onPlanTrip: () => setState(() => _activeTab = 1),
          onOpenSimulator: _openSimulatorModal,
          onOpenAccessibility: () => setState(() => _activeTab = 4),
          onOpenStationMap: () => setState(() => _activeTab = 5),
        );
    }

    final mobileApp = Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        bottom: false,
        child: screenContent,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.cardBg,
          border: Border(
            top: BorderSide(color: AppTheme.cardBorder, width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Home'),
                _buildNavItem(1, Icons.alt_route_rounded, 'Plan'),
                _buildNavItem(2, Icons.map_rounded, 'Map'),
                _buildNavItem(3, Icons.directions_subway_rounded, 'Transit'),
                _buildNavItem(4, Icons.accessibility_new_rounded, 'Access'),
                _buildNavItem(5, Icons.layers_rounded, 'Layout'),
              ],
            ),
          ),
        ),
      ),
    );

    // Vertical mobile framing with desktop bars
    return Scaffold(
      backgroundColor: const Color(0xFF090A0F),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          decoration: BoxDecoration(
            color: AppTheme.bgDark,
            border: Border.symmetric(
              vertical: BorderSide(
                color: AppTheme.cardBorder.withValues(alpha: 0.7),
                width: 1.5,
              ),
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black87,
                blurRadius: 36,
                spreadRadius: 8,
              ),
            ],
          ),
          child: mobileApp,
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _activeTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTab = index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 21,
                color: isSelected ? AppTheme.purpleLight : AppTheme.textMuted,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
