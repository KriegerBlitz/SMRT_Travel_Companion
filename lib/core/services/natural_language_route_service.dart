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
  final List<RoutePlan> allOptions;
  final WeatherForecastResult weather;

  const ParsedJourneyResult({
    required this.rawQuery,
    required this.origin,
    required this.destination,
    required this.persona,
    required this.isWheelchairAccessible,
    required this.routePlan,
    this.allOptions = const [],
    required this.weather,
  });

  String get etaDisplay => '${routePlan.totalDurationMinutes} mins';
}

/// Service that parses natural language transit prompts (e.g. "Bugis to Harborfront on Wheelchair", "EW28 to NS24")
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

    // 2. Extract Origin and Destination (Station Codes or Station Names)
    String origin = 'Bugis';
    String destination = 'HarbourFront';

    // Check if query contains station codes like EW28, NS24, DT14, NE1, CC19, TE20
    final codeMatches = RegExp(r'\b([A-Za-z]{2,4}\s*\d{1,2})\b')
        .allMatches(query)
        .map((m) => m.group(1)!.replaceAll(' ', '').toUpperCase())
        .where((code) => CanonicalLineTable.findStationByCodeOrName(code) != null)
        .toList();

    if (codeMatches.length >= 2) {
      final s1 = CanonicalLineTable.findStationByCodeOrName(codeMatches[0])!;
      final s2 = CanonicalLineTable.findStationByCodeOrName(codeMatches[1])!;
      origin = s1.name;
      destination = s2.name;
    } else if (codeMatches.length == 1 && (lower.contains(' to ') || lower.contains(' from '))) {
      // One station code and one location name
      final codeStation = CanonicalLineTable.findStationByCodeOrName(codeMatches.first)!;
      if (lower.startsWith('from') || lower.indexOf(codeMatches.first.toLowerCase()) < lower.indexOf('to')) {
        origin = codeStation.name;
        final parts = lower.split(' to ');
        if (parts.length > 1) {
          destination = _cleanLocationName(parts[1], defaultVal: 'HarbourFront');
        }
      } else {
        destination = codeStation.name;
        final parts = lower.split(' to ');
        origin = _cleanLocationName(parts[0].replaceAll('from', ''), defaultVal: 'Bugis');
      }
    } else if (lower.contains(' to ') || lower.contains(' -> ') || lower.contains(' towards ')) {
      final separator = lower.contains(' -> ')
          ? ' -> '
          : (lower.contains(' towards ') ? ' towards ' : ' to ');
      final parts = lower.split(separator);
      var rawOrigin = parts[0].replaceAll('from', '').trim();
      var rawDest = parts[1];

      // Strip modifiers like "on wheelchair", "fastest route", etc.
      rawDest = rawDest
          .replaceAll('on wheelchair', '')
          .replaceAll('with wheelchair', '')
          .replaceAll('wheelchair', '')
          .replaceAll('please', '')
          .replaceAll('by mrt', '')
          .replaceAll('by bus', '')
          .trim();

      origin = _cleanLocationName(rawOrigin, defaultVal: 'Bugis');
      destination = _cleanLocationName(rawDest, defaultVal: 'HarbourFront');
    } else {
      // Check if single location or station code matches
      final s = CanonicalLineTable.findStationByCodeOrName(query);
      if (s != null) {
        destination = s.name;
      }
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

    // 5. Plan Multi-Modal Journey Options through Routing Engine
    final allOptions = await _engine.planCommuterJourneyOptions(
      originName: origin,
      startLat: startLat,
      startLon: startLon,
      destinationName: destination,
      endLat: endLat,
      endLon: endLon,
      persona: persona,
    );

    final primaryPlan = allOptions.isNotEmpty
        ? allOptions.first
        : await _engine.planCommuterJourney(
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
      routePlan: primaryPlan,
      allOptions: allOptions.isNotEmpty ? allOptions : [primaryPlan],
      weather: weather,
    );
  }

  String _cleanLocationName(String input, {required String defaultVal}) {
    if (input.isEmpty) return defaultVal;

    // Check station code or exact station name match first (e.g. EW28 -> Pioneer)
    final matchedStation = CanonicalLineTable.findStationByCodeOrName(input);
    if (matchedStation != null) {
      return matchedStation.name;
    }

    // Normalize well-known variations
    final clean = input.toLowerCase().trim();
    if (clean.contains('harbor') || clean.contains('harbour')) return 'HarbourFront';
    if (clean.contains('bugis')) return 'Bugis';
    if (clean.contains('tampines')) return 'Tampines';
    if (clean.contains('raffles')) return 'Raffles Place';
    if (clean.contains('bedok')) return 'Bedok';
    if (clean.contains('outram')) return 'Outram Park';
    if (clean.contains('pioneer')) return 'Pioneer';
    if (clean.contains('jurong')) return 'Jurong East';
    if (clean.contains('sgh') || clean.contains('hospital')) return 'Singapore General Hospital';
    return input[0].toUpperCase() + input.substring(1);
  }

  Station? _findStation(String name) {
    return CanonicalLineTable.findStationByCodeOrName(name);
  }
}
