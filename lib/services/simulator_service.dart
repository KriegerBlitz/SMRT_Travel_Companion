import 'package:flutter/foundation.dart';
import 'lta_models.dart';

enum DemoScenario {
  live('Live LTA DataMall', 'Unmodified real-time data feeds.'),
  rachelDisruption(
    'Rachel: Morning Rush Disruption',
    'EWL Signal Fault near Tampines. Free MRT Shuttle activated. Crowd rising.',
  ),
  mdmLimLiftOutage(
    'Mdm Lim: Outram Park Lift Down',
    'Lift 2 Out of Service at Exit 1. Recommends WAB Bus 147 with live seat load.',
  ),
  mdmLimRainSheltered(
    'Mdm Lim: Weather Alert',
    '2-Hour Rain Nowcast triggered. Proactively routes via CoveredLinkWay.',
  );

  final String title;
  final String description;
  const DemoScenario(this.title, this.description);
}

class SimulatorService extends ChangeNotifier {
  DemoScenario _activeScenario = DemoScenario.live;
  bool _forceDisruption = false;
  CrowdLevel _forcedCrowdLevel = CrowdLevel.low;
  bool _forceCrowdForecastSpike = false;
  bool _forceLiftOutage = false;
  bool _forceRainNowcast = false;
  int _deadReckoningElapsedSeconds = 0;
  int _currentStop = 4;

  DemoScenario get activeScenario => _activeScenario;
  bool get forceDisruption => _forceDisruption;
  CrowdLevel get forcedCrowdLevel => _forcedCrowdLevel;
  bool get forceCrowdForecastSpike => _forceCrowdForecastSpike;
  bool get forceLiftOutage => _forceLiftOutage;
  bool get forceRainNowcast => _forceRainNowcast;
  int get deadReckoningElapsedSeconds => _deadReckoningElapsedSeconds;
  int get currentStop => _currentStop;
  bool get isDeadReckoningApproaching => _currentStop == 4;

  void setCurrentStop(int stop) {
    _currentStop = stop.clamp(1, 9);
    notifyListeners();
  }

  /// Mandatory Rule: Returns true whenever any simulation toggle is active.
  /// UI MUST display the [Simulated Data] badge whenever this is true.
  bool get isSimulated =>
      _activeScenario != DemoScenario.live ||
      _forceDisruption ||
      _forcedCrowdLevel != CrowdLevel.low ||
      _forceCrowdForecastSpike ||
      _forceLiftOutage ||
      _forceRainNowcast ||
      _deadReckoningElapsedSeconds > 0;

  void applyScenario(DemoScenario scenario) {
    _activeScenario = scenario;
    switch (scenario) {
      case DemoScenario.live:
        _forceDisruption = false;
        _forcedCrowdLevel = CrowdLevel.low;
        _forceCrowdForecastSpike = false;
        _forceLiftOutage = false;
        _forceRainNowcast = false;
        _deadReckoningElapsedSeconds = 0;
        break;
      case DemoScenario.rachelDisruption:
        _forceDisruption = true;
        _forcedCrowdLevel = CrowdLevel.high;
        _forceCrowdForecastSpike = true;
        _forceLiftOutage = false;
        _forceRainNowcast = false;
        break;
      case DemoScenario.mdmLimLiftOutage:
        _forceDisruption = false;
        _forcedCrowdLevel = CrowdLevel.moderate;
        _forceCrowdForecastSpike = false;
        _forceLiftOutage = true;
        _forceRainNowcast = false;
        break;
      case DemoScenario.mdmLimRainSheltered:
        _forceDisruption = false;
        _forcedCrowdLevel = CrowdLevel.low;
        _forceCrowdForecastSpike = false;
        _forceLiftOutage = false;
        _forceRainNowcast = true;
        break;
    }
    notifyListeners();
  }

  void toggleDisruption(bool val) {
    _forceDisruption = val;
    notifyListeners();
  }

  void setCrowdLevel(CrowdLevel level) {
    _forcedCrowdLevel = level;
    notifyListeners();
  }

  void toggleCrowdForecastSpike(bool val) {
    _forceCrowdForecastSpike = val;
    notifyListeners();
  }

  void toggleLiftOutage(bool val) {
    _forceLiftOutage = val;
    notifyListeners();
  }

  void toggleRainNowcast(bool val) {
    _forceRainNowcast = val;
    notifyListeners();
  }

  void advanceDeadReckoningTimer(int seconds) {
    _deadReckoningElapsedSeconds += seconds;
    notifyListeners();
  }

  void resetDeadReckoningTimer() {
    _deadReckoningElapsedSeconds = 0;
    notifyListeners();
  }
}
