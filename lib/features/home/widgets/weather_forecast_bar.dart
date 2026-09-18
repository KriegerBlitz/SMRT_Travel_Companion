import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/weather_service.dart';

/// Real-time 2-Hour Singapore Weather Forecast bar with emoji
class WeatherForecastBar extends StatelessWidget {
  final WeatherForecastResult? weather;
  final bool isLoading;

  const WeatherForecastBar({
    super.key,
    required this.weather,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && weather == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Fetching Singapore 2-hour nowcast...',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    final emoji = weather?.emoji ?? '⛅';
    final forecastText = weather?.forecast ?? 'Passing Clouds';
    final isRain = weather?.isRainingOrImminent ?? false;
    final isSimulated = weather?.isSimulated ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isRain
            ? const Color(0xFF1E1B4B).withValues(alpha: 0.7) // Rain indigo tone
            : const Color(0xFF0E1726).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRain
              ? const Color(0xFF6366F1).withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          // Weather Emoji
          Text(
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 10),

          // Forecast Text & Location
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        forecastText,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '· 2h Nowcast',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  isRain
                      ? 'Rain imminent in Central area · Sheltered routing recommended'
                      : 'Central Singapore · Dry conditions for outdoor walkways',
                  style: GoogleFonts.plusJakartaSans(
                    color: isRain
                        ? const Color(0xFFA5B4FC)
                        : Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Live / Simulated Compliance Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: isSimulated
                  ? null
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Color(0xFFE2E8F0),
                      ],
                    ),
              color: isSimulated ? const Color(0xFFEF4444).withValues(alpha: 0.2) : null,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSimulated
                    ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.5),
              ),
              boxShadow: isSimulated
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            child: Text(
              isSimulated ? 'SIMULATED' : 'LIVE NOWCAST',
              style: GoogleFonts.jetBrainsMono(
                color: isSimulated ? const Color(0xFFEF4444) : Colors.black,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
