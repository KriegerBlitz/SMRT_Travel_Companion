import 'dart:async';
import '../models/route_plan.dart';

/// Current real-time state of an active in-progress journey.
class LiveJourneyState {
  final RoutePlan plan;
  final int currentLegIndex;
  final int currentStationIndex;
  final String currentStopName;
  final String? nextStopName;
  final int minutesToNextStop;
  final int remainingEtaMinutes;
  final double progressFraction; // 0.0 to 1.0
  final bool isNavigating;
  final bool isArrived;
  final String navigationInstruction;

  const LiveJourneyState({
    required this.plan,
    required this.currentLegIndex,
    required this.currentStationIndex,
    required this.currentStopName,
    this.nextStopName,
    required this.minutesToNextStop,
    required this.remainingEtaMinutes,
    required this.progressFraction,
    required this.isNavigating,
    required this.isArrived,
    required this.navigationInstruction,
  });

  /// Formatted remaining ETA string
  String get remainingEtaDisplay =>
      isArrived ? 'Arrived' : '$remainingEtaMinutes min remaining';
}

/// Service managing real-time journey navigation, live ETA calculations,
/// and station-by-station progress tracking.
class LiveJourneyService {
  LiveJourneyState? _currentState;
  final _stateController = StreamController<LiveJourneyState>.broadcast();
  Timer? _tickerTimer;

  Stream<LiveJourneyState> get stateStream => _stateController.stream;
  LiveJourneyState? get currentState => _currentState;

  /// Starts active navigation for a selected [RoutePlan].
  LiveJourneyState startJourney(RoutePlan plan) {
    _tickerTimer?.cancel();

    final firstLeg = plan.legs.isNotEmpty ? plan.legs.first : null;
    final firstStop = firstLeg?.departureStop ?? plan.origin;
    final nextStop = firstLeg?.arrivalStop ?? plan.destination;

    _currentState = LiveJourneyState(
      plan: plan,
      currentLegIndex: 0,
      currentStationIndex: 0,
      currentStopName: firstStop,
      nextStopName: nextStop,
      minutesToNextStop: (firstLeg?.durationMinutes ?? 4).clamp(1, 5),
      remainingEtaMinutes: plan.totalDurationMinutes,
      progressFraction: 0.0,
      isNavigating: true,
      isArrived: false,
      navigationInstruction: firstLeg?.instruction ?? 'Proceed along route',
    );

    _stateController.add(_currentState!);
    return _currentState!;
  }

  /// Advances the journey to the next step / station along the route.
  /// Supports both simulated GPS progression and live commuter advancement.
  LiveJourneyState advanceStep() {
    if (_currentState == null || !_currentState!.isNavigating) {
      throw StateError('No active journey in progress');
    }

    final plan = _currentState!.plan;
    final totalLegs = plan.legs.length;
    final nextLegIndex = _currentState!.currentLegIndex + 1;
    final nextStationIndex = _currentState!.currentStationIndex + 1;

    // Check if journey is completed
    if (nextLegIndex >= totalLegs) {
      _currentState = LiveJourneyState(
        plan: plan,
        currentLegIndex: totalLegs - 1,
        currentStationIndex: nextStationIndex,
        currentStopName: plan.destination,
        nextStopName: null,
        minutesToNextStop: 0,
        remainingEtaMinutes: 0,
        progressFraction: 1.0,
        isNavigating: false,
        isArrived: true,
        navigationInstruction: 'You have arrived at your destination!',
      );
      _stateController.add(_currentState!);
      return _currentState!;
    }

    final activeLeg = plan.legs[nextLegIndex];
    final fraction = (nextLegIndex / totalLegs).clamp(0.0, 1.0);
    final remainingMinutes = (plan.totalDurationMinutes * (1.0 - fraction))
        .round()
        .clamp(1, plan.totalDurationMinutes);

    _currentState = LiveJourneyState(
      plan: plan,
      currentLegIndex: nextLegIndex,
      currentStationIndex: nextStationIndex,
      currentStopName: activeLeg.departureStop,
      nextStopName: activeLeg.arrivalStop,
      minutesToNextStop: (activeLeg.durationMinutes / 2).ceil().clamp(1, 8),
      remainingEtaMinutes: remainingMinutes,
      progressFraction: fraction,
      isNavigating: true,
      isArrived: false,
      navigationInstruction: activeLeg.instruction ??
          'Proceed on ${activeLeg.lineOrService ?? activeLeg.mode} towards ${activeLeg.arrivalStop}',
    );

    _stateController.add(_currentState!);
    return _currentState!;
  }

  /// Cancels and ends the active navigation session.
  void stopJourney() {
    _tickerTimer?.cancel();
    _currentState = null;
  }

  void dispose() {
    _tickerTimer?.cancel();
    _stateController.close();
  }
}
