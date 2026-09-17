import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class WeatherNowcast {
  final String area;
  final String forecast; // e.g. "Passing Showers", "Fair", "Cloudy", "Thundery Showers"
  final bool isRaining;
  final DateTime updateTime;

  const WeatherNowcast({
    required this.area,
    required this.forecast,
    required this.isRaining,
    required this.updateTime,
  });

  factory WeatherNowcast.fair(String area) {
    return WeatherNowcast(
      area: area,
      forecast: 'Fair (Day)',
      isRaining: false,
      updateTime: DateTime.now(),
    );
  }

  factory WeatherNowcast.rainy(String area, {String? customText}) {
    return WeatherNowcast(
      area: area,
      forecast: customText ?? 'Passing Showers',
      isRaining: true,
      updateTime: DateTime.now(),
    );
  }
}

class WeatherService {
  static const String endpoint =
      'https://api-open.data.gov.sg/v2/real-time/api/two-hr-forecast';
  static const String fallbackEndpoint =
      'https://api.data.gov.sg/v1/environment/2-hour-weather-forecast';

  /// Fetches the 2-hour weather nowcast from data.gov.sg (no API key required).
  /// Focuses on areas relevant to Mdm Lim's commute (Bedok, Bukit Merah / Outram).
  Future<Map<String, WeatherNowcast>> getNowcast() async {
    final Map<String, WeatherNowcast> results = {
      'Bedok': WeatherNowcast.fair('Bedok'),
      'Bukit Merah': WeatherNowcast.fair('Bukit Merah'),
    };

    try {
      final response = await http
          .get(Uri.parse(endpoint))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['data']?['items'] as List?;
        if (items != null && items.isNotEmpty) {
          final forecasts = items.first['forecasts'] as List?;
          if (forecasts != null) {
            for (final f in forecasts) {
              final area = f['area']?.toString() ?? '';
              final forecast = f['forecast']?.toString() ?? '';
              final isRain = forecast.toLowerCase().contains('rain') ||
                  forecast.toLowerCase().contains('shower') ||
                  forecast.toLowerCase().contains('storm');

              if (area.toLowerCase().contains('bedok')) {
                results['Bedok'] = WeatherNowcast(
                  area: 'Bedok',
                  forecast: forecast,
                  isRaining: isRain,
                  updateTime: DateTime.now(),
                );
              } else if (area.toLowerCase().contains('bukit merah') ||
                  area.toLowerCase().contains('city') ||
                  area.toLowerCase().contains('outram')) {
                results['Bukit Merah'] = WeatherNowcast(
                  area: 'Bukit Merah',
                  forecast: forecast,
                  isRaining: isRain,
                  updateTime: DateTime.now(),
                );
              }
            }
            return results;
          }
        }
      }
    } catch (e) {
      debugPrint('Live weather nowcast fetch error (using fallback): $e');
    }

    return results;
  }
}
