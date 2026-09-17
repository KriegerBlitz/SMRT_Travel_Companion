import '../services/lta_models.dart';
import '../services/onemap_service.dart';

class DisruptionPersonalizer {
  /// Generates a single, personalized, actionable sentence based on the user's route and LTA alert.
  /// Used directly for TTS playback (Mdm Lim) and notification banners (Rachel).
  static String personalizeAlert({
    required DoorToDoorRoute route,
    required TrainServiceAlert alert,
    required bool isFamiliarRoute,
    required bool isAccessibilityUser,
    FacilityMaintenance? liftOutage,
    bool isRaining = false,
  }) {
    // 1. Accessibility Lift Outage prioritization for Mdm Lim
    if (isAccessibilityUser && liftOutage != null && liftOutage.isOutOfService) {
      if (isFamiliarRoute) {
        return '${liftOutage.locationDescription} is down. Take WAB Bus 147 directly to SGH.';
      } else {
        return 'Notice for SGH trip: ${liftOutage.locationDescription} at ${liftOutage.stationName} is under maintenance. We have rerouted you via Wheelchair-Accessible Bus 147 from Bedok with seats available.';
      }
    }

    // 2. Weather Alert prioritization for Mdm Lim
    if (isAccessibilityUser && isRaining) {
      return 'Passing showers forecast: Your route has been updated to use the covered linkway from Outram Park Exit 1 to keep you sheltered.';
    }

    // 3. Train Service Disruption prioritization
    if (alert.isDisrupted) {
      final hasShuttle = alert.freeMrtShuttle;
      final line = alert.line;

      if (isFamiliarRoute) {
        // Crisp, actionable advice for Rachel's daily commute
        if (hasShuttle) {
          return 'Delay likely today, +15 min: Take the Free MRT Shuttle from ${route.originName}, leave 10 min earlier.';
        } else {
          return 'Disruption on $line line: +20 min delay expected. Leave earlier or take public bus alternative.';
        }
      } else {
        // Detailed guidance for less familiar commuters
        if (hasShuttle) {
          return '$line train services disrupted near ${alert.affectedStations.join(', ')}. Free MRT Shuttle buses are operating at station bus stops. Expect a 15-minute delay to ${route.destinationName}.';
        } else {
          return 'Active service alert on $line: Trains delayed. Please consider alternate bus routes or allow extra travel time.';
        }
      }
    }

    // 4. Normal conditions
    if (isFamiliarRoute) {
      return 'All clear on your regular commute. On-time departure recommended.';
    } else {
      return 'All train and bus legs on your route to ${route.destinationName} are operating normally.';
    }
  }
}
