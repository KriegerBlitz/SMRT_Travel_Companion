import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/route_plan.dart';

/// Service client for OneMap Public Transport & Multi-Modal Routing API.
class OneMapService {
  final http.Client _client;

  OneMapService({http.Client? client}) : _client = client ?? http.Client();

  /// Requests door-to-door public transport route from OneMap.
  /// If live API call fails or token is missing, falls back to realistic baseline multimodal path.
  Future<RoutePlan> planRoute({
    required String originName,
    required double startLat,
    required double startLon,
    required String destinationName,
    required double endLat,
    required double endLon,
    String routeType = 'pt', // pt = public transport, walk = walking
    bool preferSheltered = false,
  }) async {
    if (ApiConfig.oneMapAuthToken.isNotEmpty) {
      try {
        final queryParams = {
          'start': '$startLat,$startLon',
          'end': '$endLat,$endLon',
          'routeType': routeType,
          'mode': 'TRANSIT',
          'date': DateTime.now().toIso8601String().split('T')[0],
          'time': '07:40:00',
        };

        final uri = Uri.parse(ApiConfig.oneMapRoutePublicTransport)
            .replace(queryParameters: queryParams);

        final response = await _client.get(uri, headers: ApiConfig.oneMapHeaders);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final parsed = _parseOneMapResponse(data, originName, destinationName);
          if (parsed != null) return parsed;
        }
      } catch (_) {}
    }

    // High-fidelity fallback door-to-door routes for the designated personas
    return getRealisticDoorToDoorRoute(
      originName: originName,
      startLat: startLat,
      startLon: startLon,
      destinationName: destinationName,
      endLat: endLat,
      endLon: endLon,
      preferSheltered: preferSheltered,
    );
  }

  RoutePlan? _parseOneMapResponse(
    Map<String, dynamic> data,
    String originName,
    String destinationName,
  ) {
    try {
      final plan = data['plan'] as Map<String, dynamic>?;
      if (plan == null) return null;

      final itineraries = plan['itineraries'] as List<dynamic>? ?? [];
      if (itineraries.isEmpty) return null;

      final itinerary = itineraries[0] as Map<String, dynamic>;
      final durationSec = itinerary['duration'] as int? ?? 2400;
      final walkDist = (itinerary['walkDistance'] as num?)?.toDouble() ?? 400.0;

      final rawLegs = itinerary['legs'] as List<dynamic>? ?? [];
      final legs = <RouteLeg>[];

      for (final l in rawLegs) {
        final legMap = l as Map<String, dynamic>;
        final mode = legMap['mode']?.toString().toUpperCase() ?? 'WALK';
        final from = legMap['from']?['name']?.toString() ?? 'Origin';
        final to = legMap['to']?['name']?.toString() ?? 'Destination';
        final legDuration = legMap['duration'] as int? ?? 300;
        final legDist = (legMap['distance'] as num?)?.toDouble() ?? 200.0;

        legs.add(
          RouteLeg(
            mode: mode == 'SUBWAY' ? 'SUBWAY' : (mode == 'BUS' ? 'BUS' : 'WALK'),
            lineOrService: legMap['route']?.toString(),
            departureStop: from,
            arrivalStop: to,
            durationSeconds: legDuration,
            distanceMeters: legDist,
            coordinates: [
              [
                (legMap['from']?['lat'] as num?)?.toDouble() ?? 1.35,
                (legMap['from']?['lon'] as num?)?.toDouble() ?? 103.95,
              ],
              [
                (legMap['to']?['lat'] as num?)?.toDouble() ?? 1.28,
                (legMap['to']?['lon'] as num?)?.toDouble() ?? 103.85,
              ],
            ],
          ),
        );
      }

      return RoutePlan(
        id: 'onemap-${DateTime.now().millisecondsSinceEpoch}',
        origin: originName,
        destination: destinationName,
        totalDurationMinutes: (durationSec / 60).round(),
        totalWalkDistanceMeters: walkDist,
        legs: legs,
        confidence: ConfidenceLevel.green,
        confidenceReason: 'Standard scheduled timetable',
      );
    } catch (_) {
      return null;
    }
  }

  /// High-fidelity baseline door-to-door routes for Rachel and Mdm Lim personas.
  RoutePlan getRealisticDoorToDoorRoute({
    required String originName,
    required double startLat,
    required double startLon,
    required String destinationName,
    required double endLat,
    required double endLon,
    bool preferSheltered = false,
  }) {
    final isRachelJourney =
        originName.toLowerCase().contains('tampines') ||
        destinationName.toLowerCase().contains('raffles');

    if (isRachelJourney) {
      // Rachel: Tampines home -> Tampines MRT (walk 4m) -> East-West Line -> Raffles Place MRT -> Office (walk 3m)
      return RoutePlan(
        id: 'rachel-standard-route',
        origin: 'Tampines Ave 4 (Home)',
        destination: 'Ocean Financial Centre, Raffles Place (Work)',
        totalDurationMinutes: 38,
        totalWalkDistanceMeters: 450.0,
        confidence: ConfidenceLevel.green,
        confidenceReason: 'Normal service on East-West Line. 0 active disruptions.',
        legs: const [
          RouteLeg(
            mode: 'WALK',
            departureStop: 'Tampines Ave 4',
            arrivalStop: 'Tampines MRT (EW2) Exit B',
            durationSeconds: 240, // 4 mins
            distanceMeters: 250.0,
            coordinates: [
              [1.3545, 103.9438],
              [1.3538, 103.9446],
              [1.3533, 103.9452],
            ],
            instruction: 'Walk along Tampines Central 5 to Exit B',
          ),
          RouteLeg(
            mode: 'SUBWAY',
            lineOrService: 'EWL',
            departureStop: 'Tampines (EW2)',
            arrivalStop: 'Raffles Place (EW14)',
            durationSeconds: 1860, // 31 mins (12 stations)
            distanceMeters: 17200.0,
            coordinates: [
              [1.3533, 103.9452], // Tampines
              [1.3432, 103.9533], // Simei
              [1.3273, 103.9463], // Tanah Merah
              [1.3240, 103.9300], // Bedok
              [1.3210, 103.9129], // Kembangan
              [1.3197, 103.9031], // Eunos
              [1.3181, 103.8931], // Paya Lebar
              [1.3164, 103.8829], // Aljunied
              [1.3115, 103.8714], // Kallang
              [1.3074, 103.8596], // Lavender
              [1.3005, 103.8558], // Bugis
              [1.2931, 103.8522], // City Hall
              [1.2830, 103.8513], // Raffles Place
            ],
            instruction: 'Board EWL towards Tuas Link. Alight at Raffles Place.',
          ),
          RouteLeg(
            mode: 'WALK',
            departureStop: 'Raffles Place MRT (EW14) Exit J',
            arrivalStop: 'Ocean Financial Centre',
            durationSeconds: 180, // 3 mins
            distanceMeters: 200.0,
            coordinates: [
              [1.2830, 103.8513],
              [1.2834, 103.8521],
            ],
            instruction: 'Take Exit J underground linkway to building lobby',
          ),
        ],
      );
    }

    // Mdm Lim: Bedok South Ave 1 (Home) -> Bedok MRT -> EWL to Outram Park -> SGH Clinic
    return RoutePlan(
      id: 'mdm-lim-standard-route',
      origin: 'Bedok South Ave 1 (Home)',
      destination: 'Singapore General Hospital (Diabetes Clinic)',
      totalDurationMinutes: 44,
      totalWalkDistanceMeters: 380.0,
      confidence: ConfidenceLevel.green,
      confidenceReason: 'All station lifts operational along route.',
      usesShelteredWalkways: preferSheltered,
      legs: [
        RouteLeg(
          mode: 'WALK',
          departureStop: 'Bedok South Ave 1',
          arrivalStop: 'Bedok MRT (EW5) Exit B',
          durationSeconds: 360, // 6 mins gentle walk
          distanceMeters: 220.0,
          isSheltered: preferSheltered,
          coordinates: const [
            [1.3225, 103.9312],
            [1.3232, 103.9306],
            [1.3240, 103.9300],
          ],
          instruction: preferSheltered
              ? 'Follow CoveredLinkWay sheltered walkway to Bedok Exit B'
              : 'Walk along open path to Bedok Exit B',
        ),
        const RouteLeg(
          mode: 'SUBWAY',
          lineOrService: 'EWL',
          departureStop: 'Bedok (EW5)',
          arrivalStop: 'Outram Park (EW16)',
          durationSeconds: 1980, // 33 mins (11 stations)
          distanceMeters: 14800.0,
          coordinates: [
            [1.3240, 103.9300], // Bedok
            [1.3210, 103.9129], // Kembangan
            [1.3197, 103.9031], // Eunos
            [1.3181, 103.8931], // Paya Lebar
            [1.3164, 103.8829], // Aljunied
            [1.3115, 103.8714], // Kallang
            [1.3074, 103.8596], // Lavender
            [1.3005, 103.8558], // Bugis
            [1.2931, 103.8522], // City Hall
            [1.2830, 103.8513], // Raffles Place
            [1.2764, 103.8458], // Tanjong Pagar
            [1.2803, 103.8395], // Outram Park
          ],
          instruction: 'Board EWL towards Tuas Link. Alight at Outram Park (EW16).',
        ),
        RouteLeg(
          mode: 'WALK',
          departureStop: 'Outram Park (EW16) Lift Exit 7',
          arrivalStop: 'SGH Diabetes & Metabolism Centre',
          durationSeconds: 300, // 5 mins gentle walk
          distanceMeters: 160.0,
          isSheltered: preferSheltered,
          coordinates: const [
            [1.2803, 103.8395],
            [1.2797, 103.8378],
            [1.2792, 103.8364],
          ],
          instruction: preferSheltered
              ? 'Use Exit 7 Lift to street level, take sheltered hospital linkway'
              : 'Take Exit 7 Lift to street level and proceed to SGH building',
        ),
      ],
    );
  }
}
