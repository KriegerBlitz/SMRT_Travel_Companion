class RouteFamiliarity {
  static final Map<String, int> _visitCounts = {
    'tampines_to_raffles_place': 18, // Rachel: Daily commuter (High Familiarity)
    'bedok_to_sgh': 2, // Mdm Lim: Fortnightly hospital visit (Low Familiarity)
  };

  /// Returns whether a user is familiar with a route (threshold >= 5 commutes).
  static bool isFamiliar(String routeId) {
    final count = _visitCounts[routeId.toLowerCase()] ?? 0;
    return count >= 5;
  }

  /// Increments visit count when a commuter completes a journey.
  static void recordTrip(String routeId) {
    final key = routeId.toLowerCase();
    _visitCounts[key] = (_visitCounts[key] ?? 0) + 1;
  }

  /// Get visit count for display / debugging.
  static int getTripCount(String routeId) {
    return _visitCounts[routeId.toLowerCase()] ?? 0;
  }
}
