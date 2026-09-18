import 'package:flutter/foundation.dart';

/// Central controller governing Debug / Simulation Mode.
///
/// STRICT COMPETITION COMPLIANCE:
/// PS2 Brief explicitly states: "Presenting mocked data as live is an automatic score cap."
/// Therefore, simulation data is LOCKED and CANNOT be injected unless [isDebugMode]
/// is explicitly set to `true`.
class DebugService extends ChangeNotifier {
  static final DebugService instance = DebugService._();
  DebugService._();

  // ---------------------------------------------------------------------------
  // Master Switch: Default is strictly FALSE (Live mode)
  // ---------------------------------------------------------------------------
  bool _isDebugMode = false;
  bool get isDebugMode => _isDebugMode;

  // ---------------------------------------------------------------------------
  // Individual Simulation Scenarios (Only take effect if isDebugMode is true)
  // ---------------------------------------------------------------------------
  bool _simulateDisruption = false;
  bool _simulateLiftOutage = false;
  bool _simulateRainNowcast = false;
  bool _simulateCrowdSurge = false;
  int _simulatedDeadReckoningSeconds = 0;

  bool get simulateDisruption => _isDebugMode && _simulateDisruption;
  bool get simulateLiftOutage => _isDebugMode && _simulateLiftOutage;
  bool get simulateRainNowcast => _isDebugMode && _simulateRainNowcast;
  bool get simulateCrowdSurge => _isDebugMode && _simulateCrowdSurge;
  int get simulatedDeadReckoningSeconds => _isDebugMode ? _simulatedDeadReckoningSeconds : 0;

  /// Enables or disables Debug Mode globally.
  /// When disabled, all simulation switches are immediately neutralized.
  void setDebugMode(bool enabled) {
    if (_isDebugMode == enabled) return;
    _isDebugMode = enabled;
    if (!_isDebugMode) {
      _resetSimulationSwitches();
    }
    notifyListeners();
  }

  /// Toggles simulated train service disruption (EWL signalling fault + Free MRT Shuttle).
  void setSimulateDisruption(bool value) {
    if (!_isDebugMode) return;
    _simulateDisruption = value;
    notifyListeners();
  }

  /// Toggles simulated lift outage (Outram Park Exit 7 lift out of service).
  void setSimulateLiftOutage(bool value) {
    if (!_isDebugMode) return;
    _simulateLiftOutage = value;
    notifyListeners();
  }

  /// Toggles simulated weather nowcast (Thundery showers for 2-hour window).
  void setSimulateRainNowcast(bool value) {
    if (!_isDebugMode) return;
    _simulateRainNowcast = value;
    notifyListeners();
  }

  /// Toggles simulated platform crowd forecast spike (High crowd prediction).
  void setSimulateCrowdSurge(bool value) {
    if (!_isDebugMode) return;
    _simulateCrowdSurge = value;
    notifyListeners();
  }

  /// Sets dead-reckoning elapsed seconds for underground testing.
  void setDeadReckoningSeconds(int seconds) {
    if (!_isDebugMode) return;
    _simulatedDeadReckoningSeconds = seconds;
    notifyListeners();
  }

  /// Resets all scenario switches to clean live baseline.
  void _resetSimulationSwitches() {
    _simulateDisruption = false;
    _simulateLiftOutage = false;
    _simulateRainNowcast = false;
    _simulateCrowdSurge = false;
    _simulatedDeadReckoningSeconds = 0;
  }

  /// Resets everything back to live mode.
  void resetToLiveMode() {
    _isDebugMode = false;
    _resetSimulationSwitches();
    notifyListeners();
  }

  /// Returns list of currently active simulated scenarios for audit badges.
  List<String> get activeSimulationLabels {
    if (!_isDebugMode) return const [];
    final list = <String>[];
    if (_simulateDisruption) list.add('EWL Disruption + Free Shuttle');
    if (_simulateLiftOutage) list.add('Outram Park Lift Outage');
    if (_simulateRainNowcast) list.add('2-Hour Rain Nowcast');
    if (_simulateCrowdSurge) list.add('High Crowd Platform Spike');
    if (_simulatedDeadReckoningSeconds > 0) {
      list.add('Timer Fast-Forward (+${_simulatedDeadReckoningSeconds}s)');
    }
    return list;
  }

  /// Diagnostic report for judges and developer verification
  Map<String, dynamic> get diagnosticSummary => {
        'debugModeActive': _isDebugMode,
        'simulatedDisruption': simulateDisruption,
        'simulatedLiftOutage': simulateLiftOutage,
        'simulatedRain': simulateRainNowcast,
        'simulatedCrowd': simulateCrowdSurge,
        'activeScenarios': activeSimulationLabels,
      };
}
