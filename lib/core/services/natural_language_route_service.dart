import '../models/route_plan.dart';
import '../transit/canonical_line_table.dart';
import 'transit_routing_engine.dart';
import 'weather_service.dart';

/// Parsed natural language journey request result.
class ParsedJourneyResult {
  final String rawQuery;
  final String origin;
  final String destination;
  final String persona; // 'mdmLim', 'rachel', or 'general'
  final bool isWheelchairAccessible;
  final RoutePlan routePlan;
  final WeatherForecastResult weather;

  const ParsedJourneyResult({
    required this.rawQuery,
    required this.origin,
    required this.destination,
    required this.persona,
    required this.isWheelchairAccessible,
    required this.routePlan,
    required this.weather,
  });

  String get etaDisplay => '${routePlan.totalDurationMinutes} mins';
}

/// Service that parses natural language transit prompts (e.g. "Bugis to Harborfront on Wheelchair")
/// and executes intelligent door-to-door multi-modal route planning.
class NaturalLanguageRouteService {
  final TransitRoutingEngine _engine;
  final WeatherService _weatherService;

  NaturalLanguageRouteService({
    TransitRoutingEngine? engine,
    WeatherService? weatherService,
  })  : _engine = engine ?? TransitRoutingEngine(),
        _weatherService = weatherService ?? WeatherService();

  /// Interprets a natural language prompt and produces a comprehensive door-to-door route plan.
  Future<ParsedJourneyResult> interpretAndPlanRoute(String query) async {
    final lower = query.toLowerCase().trim();

    // 1. Detect Persona & Accessibility Constraints
    final isWheelchair = lower.contains('wheelchair') ||
        lower.contains('barrier-free') ||
        lower.contains('no stair') ||
        lower.contains('accessibility') ||
        lower.contains('lift') ||
        lower.contains('mdm lim') ||
        lower.contains('senior');

    final isRachel = lower.contains('rachel') ||
        lower.contains('fastest') ||
        lower.contains('commute') ||
        lower.contains('rush');

    final persona = isWheelchair ? 'mdmLim' : (isRachel ? 'rachel' : 'general');

    // 2. Extract Origin and Destination
    String origin = 'Bugis';
    String destination = 'HarbourFront';

    if (lower.contains(' to ')) {
      final parts = lower.split(' to ');
      var rawOrigin = parts[0].replaceAll('from', '').trim();
      var rawDest = parts[1];

      // Strip modifiers like "on wheelchair", "fastest route", etc.
      rawDest = rawDest
          .replaceAll('on wheelchair', '')
          .replaceAll('with wheelchair', '')
          .replaceAll('wheelchair', '')
          .replaceAll('please', '')
          .replaceAll('by mrt', '')
          .trim();

      origin = _cleanLocationName(rawOrigin, defaultVal: 'Bugis');
      destination = _cleanLocationName(rawDest, defaultVal: 'HarbourFront');
    }

    // 3. Resolve Coordinates via Canonical Line Table or Singapore Defaults
    final originStation = _findStation(origin);
    final destStation = _findStation(destination);

    final startLat = originStation?.lat ?? 1.3005;
    final startLon = originStation?.lon ?? 103.8558;
    final endLat = destStation?.lat ?? 1.2654;
    final endLon = destStation?.lon ?? 103.8222;

    // 4. Fetch Weather Nowcast for Origin/City
    final weather = await _weatherService.checkRainNowcast(area: origin);

    // 5. Plan Multi-Modal Journey through Routing Engine
    final plan = await _engine.planCommuterJourney(
      originName: origin,
      startLat: startLat,
      startLon: startLon,
      destinationName: destination,
      endLat: endLat,
      endLon: endLon,
      persona: persona,
    );

    return ParsedJourneyResult(
      rawQuery: query,
      origin: origin,
      destination: destination,
      persona: persona,
      isWheelchairAccessible: isWheelchair,
      routePlan: plan,
      weather: weather,
    );
  }

  String _cleanLocationName(String input, {required String defaultVal}) {
    if (input.isEmpty) return defaultVal;
    // Normalize well-known variations
    final clean = input.toLowerCase();
    if (clean.contains('harbor') || clean.contains('harbour')) return 'HarbourFront';
    if (clean.contains('bugis')) return 'Bugis';
    if (clean.contains('tampines')) return 'Tampines';
    if (clean.contains('raffles')) return 'Raffles Place';
    if (clean.contains('bedok')) return 'Bedok';
    if (clean.contains('outram')) return 'Outram Park';
    if (clean.contains('sgh') || clean.contains('hospital')) return 'Singapore General Hospital';
    return input[0].toUpperCase() + input.substring(1);
  }

  Station? _findStation(String name) {
    final q = name.toLowerCase();
    for (final s in CanonicalLineTable.allStations) {
      if (s.name.toLowerCase().contains(q) || q.contains(s.name.toLowerCase())) {
        return s;
      }
    }
    return null;
  }
}
