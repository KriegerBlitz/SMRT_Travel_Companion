import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/canonical_line_codes.dart';
import 'lta_models.dart';

class LTAService {
  static const String baseUrl = 'https://datamall2.mytransport.sg/ltaodataservice';

  final String? apiKey;

  LTAService({this.apiKey});

  Map<String, String> get _headers => {
        if (apiKey != null && apiKey!.isNotEmpty) 'AccountKey': apiKey!,
        'accept': 'application/json',
      };

  /// Fetch active Train Service Alerts
  Future<List<TrainServiceAlert>> getTrainServiceAlerts() async {
    if (apiKey == null || apiKey!.isEmpty) {
      return [TrainServiceAlert.normal()];
    }

    try {
      final response = await http
          .get(Uri.parse('$baseUrl/TrainServiceAlerts'), headers: _headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final value = data['value'];
        if (value != null && value is Map<String, dynamic>) {
          final status = value['Status'] is int ? value['Status'] as int : 1;
          if (status == 2 && value['AffectedSegments'] is List) {
            final segments = value['AffectedSegments'] as List;
            return segments
                .map((seg) => TrainServiceAlert.fromJson({
                      'Status': 2,
                      'Line': CanonicalLineCodes.reconcileLineCode(
                          seg['Line']?.toString() ?? 'ALL'),
                      'Direction': seg['Direction'] ?? 'Both',
                      'Stations': seg['Stations'] ?? '',
                      'FreePublicBus': seg['FreePublicBus'] ?? false,
                      'FreeMRTShuttle': seg['FreeMRTShuttle'] ?? false,
                      'Message': value['Message']?['Content'] ?? '',
                    }))
                .toList();
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching live TrainServiceAlerts: $e');
    }

    return [TrainServiceAlert.normal()];
  }

  /// Fetch Station Crowd Information (PCDRealTime + PCDForecast)
  Future<Map<String, StationCrowdInfo>> getCrowdDensity() async {
    final Map<String, StationCrowdInfo> crowdMap = {};

    // Standard baseline: all stations start at Low/Moderate
    for (final stn in CanonicalLineCodes.stations) {
      crowdMap[stn.code] = StationCrowdInfo(
        stationCode: stn.code,
        realTime: CrowdLevel.low,
        forecast30Min: CrowdLevel.low,
      );
    }

    if (apiKey != null && apiKey!.isNotEmpty) {
      try {
        final response = await http
            .get(
              Uri.parse('$baseUrl/PCDRealTime?TrainLine=EWL'),
              headers: _headers,
            )
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final list = data['value'] as List?;
          if (list != null) {
            for (final item in list) {
              final stn = item['Station']?.toString() ?? '';
              final density = item['CrowdLevel']?.toString() ?? 'l';
              if (crowdMap.containsKey(stn)) {
                crowdMap[stn] = StationCrowdInfo(
                  stationCode: stn,
                  realTime: CrowdLevel.fromString(density),
                  forecast30Min: crowdMap[stn]?.forecast30Min ?? CrowdLevel.low,
                );
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error fetching live PCDRealTime: $e');
      }
    }

    return crowdMap;
  }

  /// Fetch Facilities Maintenance (v2/FacilitiesMaintenance) - Lift outages
  Future<List<FacilityMaintenance>> getFacilitiesMaintenance() async {
    if (apiKey != null && apiKey!.isNotEmpty) {
      try {
        final response = await http
            .get(
              Uri.parse('$baseUrl/v2/FacilitiesMaintenance'),
              headers: _headers,
            )
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final list = data['value'] as List?;
          if (list != null) {
            return list
                .map((item) => FacilityMaintenance.fromJson(item))
                .toList();
          }
        }
      } catch (e) {
        debugPrint('Error fetching live FacilitiesMaintenance: $e');
      }
    }

    return const [];
  }

  /// Fetch Wheelchair Accessible Bus (WAB) arrivals (v3/BusArrival)
  Future<List<BusArrivalInfo>> getBusArrivals(
    String busStopCode, {
    String? serviceFilter,
  }) async {
    if (apiKey != null && apiKey!.isNotEmpty) {
      try {
        final uri = Uri.parse(
            '$baseUrl/v3/BusArrival?BusStopCode=$busStopCode${serviceFilter != null ? '&ServiceNo=$serviceFilter' : ''}');
        final response = await http.get(uri, headers: _headers).timeout(
              const Duration(seconds: 4),
            );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final services = data['Services'] as List?;
          if (services != null) {
            final List<BusArrivalInfo> arrivals = [];
            for (final svc in services) {
              final nextBus = svc['NextBus'] as Map<String, dynamic>?;
              if (nextBus != null) {
                final load = nextBus['Load']?.toString() ?? 'SEA';
                final isWab = nextBus['Feature']?.toString() == 'WAB';
                final type = nextBus['Type']?.toString() ?? 'SD';
                final etaStr = nextBus['EstimatedArrival']?.toString();
                int etaMin = 3;
                if (etaStr != null && etaStr.isNotEmpty) {
                  final etaDate = DateTime.tryParse(etaStr);
                  if (etaDate != null) {
                    etaMin = etaDate.difference(DateTime.now()).inMinutes;
                    if (etaMin < 1) etaMin = 1;
                  }
                }

                arrivals.add(BusArrivalInfo(
                  serviceNo: svc['ServiceNo']?.toString() ?? '',
                  busStopCode: busStopCode,
                  load: load,
                  isWab: isWab,
                  type: type,
                  estimatedMinutes: etaMin,
                ));
              }
            }
            return arrivals;
          }
        }
      } catch (e) {
        debugPrint('Error fetching live BusArrival: $e');
      }
    }

    // Default fallback WAB bus info for Outram Park / SGH route
    return [
      BusArrivalInfo(
        serviceNo: '147',
        busStopCode: '06011', // Outram Park Stn Exit 1/SGH
        load: 'SEA',
        isWab: true,
        type: 'DD',
        estimatedMinutes: 4,
      ),
      BusArrivalInfo(
        serviceNo: '197',
        busStopCode: '06011',
        load: 'SDA',
        isWab: true,
        type: 'SD',
        estimatedMinutes: 9,
      ),
    ];
  }
}
