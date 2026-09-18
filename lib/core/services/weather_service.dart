import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../debug/debug_service.dart';

/// Real-time 2-hour weather nowcast from data.gov.sg (no API key required).
/// Feeds Mdm Lim's covered-vs-uncovered route choice only.
class WeatherService {
  final http.Client _client;
  final DebugService _debugService;

  WeatherService({http.Client? client, DebugService? debugService})
      : _client = client ?? http.Client(),
        _debugService = debugService ?? DebugService.instance;

  /// Checks whether rain is forecast within the next 2 hours for a target Singapore location.
  /// (e.g. 'Bedok', 'Outram', 'Tampines', 'Bukit Merah')
  Future<WeatherForecastResult> checkRainNowcast({
    required String area,
    bool simulateRain = false,
  }) async {
    final shouldSimulate = simulateRain || _debugService.simulateRainNowcast;
    if (shouldSimulate) {
      return WeatherForecastResult(
        area: area,
        forecast: 'Thundery Showers',
        isRainingOrImminent: true,
        isSimulated: true,
      );
    }

    try {
      final response = await _client.get(Uri.parse(ApiConfig.weatherTwoHourForecast));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];
        if (items.isNotEmpty) {
          final forecasts = items[0]['forecasts'] as List<dynamic>? ?? [];
          for (final f in forecasts) {
            final fArea = f['area']?.toString().toLowerCase() ?? '';
            if (fArea.contains(area.toLowerCase()) || area.toLowerCase().contains(fArea)) {
              final forecastText = f['forecast']?.toString() ?? 'Fair';
              final isRain = _isRainCondition(forecastText);
              return WeatherForecastResult(
                area: area,
                forecast: forecastText,
                isRainingOrImminent: isRain,
                isSimulated: false,
              );
            }
          }
        }
      }
    } catch (_) {}

    // Graceful default: clear weather unless simulated
    return WeatherForecastResult(
      area: area,
      forecast: 'Passing Clouds',
      isRainingOrImminent: false,
      isSimulated: false,
    );
  }

  bool _isRainCondition(String forecast) {
    final text = forecast.toLowerCase();
    return text.contains('rain') ||
        text.contains('shower') ||
        text.contains('storm') ||
        text.contains('drizzle');
  }
}

class WeatherForecastResult {
  final String area;
  final String forecast;
  final bool isRainingOrImminent;
  final bool isSimulated;

  const WeatherForecastResult({
    required this.area,
    required this.forecast,
    required this.isRainingOrImminent,
    this.isSimulated = false,
  });

  @override
  String toString() => '$area: $forecast (Rain risk: $isRainingOrImminent)';
}
