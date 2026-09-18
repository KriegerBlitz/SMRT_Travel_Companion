import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'lta_service.dart';

/// Represents a pedestrian or accessibility feature extracted from OSM or DataMall.
class PedestrianFeature {
  final String id;
  final String type; // 'covered_linkway', 'footway', 'steps', 'elevator'
  final String name;
  final bool isSheltered;
  final bool isWheelchairAccessible;
  final List<List<double>> coordinates; // [[lat, lon], ...]

  const PedestrianFeature({
    required this.id,
    required this.type,
    this.name = '',
    required this.isSheltered,
    this.isWheelchairAccessible = true,
    required this.coordinates,
  });
}

/// Service that pulls CoveredLinkWay, footways, stairs, and station lifts
/// from OpenStreetMap Overpass API and LTA DataMall geospatial layers.
///
/// STRICT LICENCE & USAGE COMPLIANCE:
/// Overpass API queries are STRICTLY CACHED in-memory with bounding-box hashing
/// to avoid hammering public infrastructure (per OSM usage policies and PS2 brief).
class GeospatialOverpassService {
  final http.Client _client;
  final LtaDataMallService _ltaService;

  // In-memory cache keyed by rounded bounding box string: "minLat,minLon,maxLat,maxLon"
  static final Map<String, List<PedestrianFeature>> _overpassCache = {};

  GeospatialOverpassService({
    http.Client? client,
    LtaDataMallService? ltaService,
  })  : _client = client ?? http.Client(),
        _ltaService = ltaService ?? LtaDataMallService();

  /// Exposes the underlying LTA DataMall service for geospatial layer queries
  LtaDataMallService get ltaService => _ltaService;

  /// Queries pedestrian and covered infrastructure around a bounding box.
  /// Strictly checks cache first to adhere to OSM tile & API fair usage rules.
  Future<List<PedestrianFeature>> getPedestrianInfrastructure({
    required double centerLat,
    required double centerLon,
    double radiusDegrees = 0.005, // ~500m radius
  }) async {
    final minLat = (centerLat - radiusDegrees).toStringAsFixed(3);
    final minLon = (centerLon - radiusDegrees).toStringAsFixed(3);
    final maxLat = (centerLat + radiusDegrees).toStringAsFixed(3);
    final maxLon = (centerLon + radiusDegrees).toStringAsFixed(3);
    final cacheKey = '$minLat,$minLon,$maxLat,$maxLon';

    // 1. Check strict in-memory cache
    if (_overpassCache.containsKey(cacheKey)) {
      return _overpassCache[cacheKey]!;
    }

    // 2. Query Overpass API with rate-limiting safety
    try {
      final query = '''
[out:json][timeout:10];
(
  way["highway"="footway"]($minLat,$minLon,$maxLat,$maxLon);
  way["covered"="yes"]($minLat,$minLon,$maxLat,$maxLon);
  way["highway"="steps"]($minLat,$minLon,$maxLat,$maxLon);
  node["highway"="elevator"]($minLat,$minLon,$maxLat,$maxLon);
);
out geom;
''';
      final uri = Uri.parse(ApiConfig.overpassApiUrl);
      final response = await _client.post(
        uri,
        body: {'data': query},
        headers: {'User-Agent': 'SMRTTravelCompanion/1.0 (Singapore Hackathon)'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final elements = data['elements'] as List<dynamic>? ?? [];
        final features = <PedestrianFeature>[];

        for (final el in elements) {
          final elMap = el as Map<String, dynamic>;
          final tags = elMap['tags'] as Map<String, dynamic>? ?? {};
          final highway = tags['highway']?.toString() ?? '';
          final isCovered = tags['covered'] == 'yes' || tags['indoor'] == 'yes';
          final isWheelchair = tags['wheelchair'] != 'no' && highway != 'steps';

          final rawGeom = elMap['geometry'] as List<dynamic>?;
          final coords = <List<double>>[];
          if (rawGeom != null) {
            for (final pt in rawGeom) {
              final pMap = pt as Map<String, dynamic>;
              final lat = (pMap['lat'] as num?)?.toDouble() ?? 0.0;
              final lon = (pMap['lon'] as num?)?.toDouble() ?? 0.0;
              coords.add([lat, lon]);
            }
          } else if (elMap['lat'] != null && elMap['lon'] != null) {
            coords.add([
              (elMap['lat'] as num).toDouble(),
              (elMap['lon'] as num).toDouble(),
            ]);
          }

          features.add(
            PedestrianFeature(
              id: elMap['id']?.toString() ?? '',
              type: isCovered
                  ? 'covered_linkway'
                  : (highway == 'steps' ? 'steps' : (highway == 'elevator' ? 'elevator' : 'footway')),
              name: tags['name']?.toString() ?? '',
              isSheltered: isCovered,
              isWheelchairAccessible: isWheelchair,
              coordinates: coords,
            ),
          );
        }

        _overpassCache[cacheKey] = features;
        return features;
      }
    } catch (_) {
      // Overpass network failure or rate limit: fallback gracefully
    }

    // 3. Bundled Fallback: Curated CoveredLinkWay segments for primary Singapore corridors
    final fallback = _getBundledCorridorFeatures(centerLat, centerLon);
    _overpassCache[cacheKey] = fallback;
    return fallback;
  }

  /// Bundled fallback CoveredLinkWay and step-free pedestrian paths
  /// Ensures app works offline or when OSM public servers are quiet/rate-limited
  List<PedestrianFeature> _getBundledCorridorFeatures(double lat, double lon) {
    // Bedok MRT ➔ Bus Interchange / Clinic corridor
    if ((lat - 1.324).abs() < 0.01 && (lon - 103.930).abs() < 0.01) {
      return const [
        PedestrianFeature(
          id: 'bedok-clw-1',
          type: 'covered_linkway',
          name: 'Bedok CoveredLinkWay to Interchange',
          isSheltered: true,
          isWheelchairAccessible: true,
          coordinates: [
            [1.3240, 103.9300],
            [1.3232, 103.9306],
            [1.3225, 103.9312],
          ],
        ),
      ];
    }

    // Outram Park EWL ➔ SGH Hospital Linkway
    if ((lat - 1.280).abs() < 0.01 && (lon - 103.839).abs() < 0.01) {
      return const [
        PedestrianFeature(
          id: 'outram-sgh-clw',
          type: 'covered_linkway',
          name: 'SGH Outram Park Sheltered Hospital Linkway',
          isSheltered: true,
          isWheelchairAccessible: true,
          coordinates: [
            [1.2803, 103.8395],
            [1.2797, 103.8378],
            [1.2792, 103.8364],
          ],
        ),
        PedestrianFeature(
          id: 'outram-exit-7-lift',
          type: 'elevator',
          name: 'Outram Park Exit 7 Lift to Street Level',
          isSheltered: true,
          isWheelchairAccessible: true,
          coordinates: [
            [1.2801, 103.8392],
          ],
        ),
      ];
    }

    // Tampines MRT ➔ Bus Interchange Bay 3 Linkway
    if ((lat - 1.353).abs() < 0.01 && (lon - 103.945).abs() < 0.01) {
      return const [
        PedestrianFeature(
          id: 'tampines-clw-1',
          type: 'covered_linkway',
          name: 'Tampines Covered Concourse Walkway',
          isSheltered: true,
          isWheelchairAccessible: true,
          coordinates: [
            [1.3533, 103.9452],
            [1.3538, 103.9446],
            [1.3545, 103.9438],
          ],
        ),
      ];
    }

    // Bugis MRT ➔ Bugis Junction Linkway
    if ((lat - 1.300).abs() < 0.01 && (lon - 103.855).abs() < 0.01) {
      return const [
        PedestrianFeature(
          id: 'bugis-junction-clw',
          type: 'covered_linkway',
          name: 'Bugis Junction Underground Pedestrian Link',
          isSheltered: true,
          isWheelchairAccessible: true,
          coordinates: [
            [1.3005, 103.8558],
            [1.3001, 103.8550],
          ],
        ),
      ];
    }

    return [];
  }

  /// Clears in-memory cache (for testing)
  static void clearCache() {
    _overpassCache.clear();
  }

  /// Returns total number of cached bounding boxes
  static int get cachedQueriesCount => _overpassCache.length;
}
