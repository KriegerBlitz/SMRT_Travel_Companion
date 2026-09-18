import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Floating tactile touch controls (Zoom In, Zoom Out, Recenter) for Leaflet Map
class MapTouchControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onRecenter;

  const MapTouchControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onRecenter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTouchButton(
          icon: Icons.add_rounded,
          tooltip: 'Zoom in',
          onTap: onZoomIn,
        ),
        const SizedBox(height: 8),
        _buildTouchButton(
          icon: Icons.remove_rounded,
          tooltip: 'Zoom out',
          onTap: onZoomOut,
        ),
        const SizedBox(height: 8),
        _buildTouchButton(
          icon: Icons.my_location_rounded,
          tooltip: 'Recenter Singapore',
          onTap: onRecenter,
        ),
      ],
    );
  }

  Widget _buildTouchButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}
