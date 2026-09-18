import 'package:flutter/material.dart';
import '../../core/map/leaflet_map_view.dart';

/// Home Screen: The live interactive map foundation.
/// Awaiting user instructions for home page layout, persona cards, and routing panel.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Live Singapore Leaflet Map (Clear, unblurred)
          const Positioned.fill(
            child: LeafletMapView(
              initialLat: 1.3521,
              initialLng: 103.8198,
              initialZoom: 13.0,
              isBlurred: false,
            ),
          ),

          // 2. Minimal top floating badge
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.directions_subway_rounded, color: Color(0xFF00D26A), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'SMRT Travel Companion',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
