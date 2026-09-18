import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/user_profile.dart';

/// Modal bottom sheet for managing commuter account settings, switching between
/// general commuting and demo personas, and fine-tuning accessibility preferences.
class CommuterAccountSheet extends StatefulWidget {
  final UserProfile currentProfile;
  final ValueChanged<UserProfile> onProfileChanged;

  const CommuterAccountSheet({
    super.key,
    required this.currentProfile,
    required this.onProfileChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required UserProfile currentProfile,
    required ValueChanged<UserProfile> onProfileChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => CommuterAccountSheet(
        currentProfile: currentProfile,
        onProfileChanged: onProfileChanged,
      ),
    );
  }

  @override
  State<CommuterAccountSheet> createState() => _CommuterAccountSheetState();
}

class _CommuterAccountSheetState extends State<CommuterAccountSheet> {
  late UserProfile _selected;
  late bool _requiresWheelchair;
  late bool _avoidStairs;
  late bool _preferSheltered;
  late bool _highDisruptionSensitivity;
  late double _walkingSpeedMultiplier;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentProfile;
    _requiresWheelchair = _selected.preferences.requiresWheelchair;
    _avoidStairs = _selected.preferences.avoidStairs;
    _preferSheltered = _selected.preferences.preferSheltered;
    _highDisruptionSensitivity =
        _selected.preferences.highDisruptionSensitivity;
    _walkingSpeedMultiplier = _selected.preferences.walkingSpeedMultiplier;
  }

  void _applyProfile(UserProfile profile) {
    setState(() {
      _selected = profile;
      _requiresWheelchair = profile.preferences.requiresWheelchair;
      _avoidStairs = profile.preferences.avoidStairs;
      _preferSheltered = profile.preferences.preferSheltered;
      _highDisruptionSensitivity =
          profile.preferences.highDisruptionSensitivity;
      _walkingSpeedMultiplier = profile.preferences.walkingSpeedMultiplier;
    });
    widget.onProfileChanged(profile);
  }

  void _updateCustomPreferences() {
    final updatedPrefs = _selected.preferences.copyWith(
      requiresWheelchair: _requiresWheelchair,
      avoidStairs: _avoidStairs,
      preferSheltered: _preferSheltered,
      highDisruptionSensitivity: _highDisruptionSensitivity,
      walkingSpeedMultiplier: _walkingSpeedMultiplier,
    );
    final updatedProfile = _selected.copyWith(preferences: updatedPrefs);
    setState(() {
      _selected = updatedProfile;
    });
    widget.onProfileChanged(updatedProfile);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1.2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Grab handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Sheet Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Commuter Account & Preferences',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Select account or customize transit preferences',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF94A3B8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white12, height: 1),

            // Scrollable Content with mouse drag support
            Flexible(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad,
                  },
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 14, 20, 16 + bottomPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section 1: Account / Profile Selection
                      Text(
                        'COMMUTER ACCOUNTS (DEMO PROFILES)',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 10),

                      ...UserProfile.allProfiles.map((profile) {
                        final isSelected = profile.id == _selected.id;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            onTap: () => _applyProfile(profile),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.45)
                                      : Colors.white.withValues(alpha: 0.10),
                                  width: isSelected ? 1.4 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white.withValues(
                                              alpha: 0.10,
                                            ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        profile.badge,
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: isSelected
                                              ? Colors.black
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              profile.name,
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                    color: Colors.white,
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                            if (isSelected) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.greenAccent
                                                      .withValues(alpha: 0.20),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: Colors.greenAccent
                                                        .withValues(alpha: 0.4),
                                                  ),
                                                ),
                                                child: Text(
                                                  'Active',
                                                  style:
                                                      GoogleFonts.plusJakartaSans(
                                                        color:
                                                            Colors.greenAccent,
                                                        fontSize: 9.5,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          profile.description,
                                          style: GoogleFonts.plusJakartaSans(
                                            color: const Color(0xFF94A3B8),
                                            fontSize: 11.5,
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    isSelected
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_off_rounded,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white30,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 16),

                      // Section 2: Custom Routing Preferences
                      Text(
                        'ROUTING PREFERENCES',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Switch 1: Wheelchair
                      _buildSwitchTile(
                        title: 'Wheelchair & Step-Free Access',
                        subtitle: 'Requires lift-only access, completely avoids stairs and escalators',
                        value: _requiresWheelchair,
                        icon: Icons.accessible_rounded,
                        onChanged: (val) {
                          setState(() {
                            _requiresWheelchair = val;
                            if (val) _avoidStairs = true;
                          });
                          _updateCustomPreferences();
                        },
                      ),

                      // Switch 2: Avoid Stairs
                      _buildSwitchTile(
                        title: 'Avoid Stairs',
                        subtitle:
                            'Prioritizes escalators, ramps, and elevators',
                        value: _avoidStairs,
                        icon: Icons.stairs_rounded,
                        onChanged: (val) {
                          setState(() => _avoidStairs = val);
                          _updateCustomPreferences();
                        },
                      ),

                      // Switch 3: Sheltered Walkways (CoveredLinkWay)
                      _buildSwitchTile(
                        title: 'Sheltered Walkways (CoveredLinkWay)',
                        subtitle: 'Prioritizes roofed connections during rain or intense heat',
                        value: _preferSheltered,
                        icon: Icons.umbrella_rounded,
                        onChanged: (val) {
                          setState(() => _preferSheltered = val);
                          _updateCustomPreferences();
                        },
                      ),

                      // Switch 4: High Disruption Sensitivity
                      _buildSwitchTile(
                        title: 'High Disruption Sensitivity',
                        subtitle: 'Immediately triggers proactive rerouting and shuttle buses',
                        value: _highDisruptionSensitivity,
                        icon: Icons.notifications_active_rounded,
                        onChanged: (val) {
                          setState(() => _highDisruptionSensitivity = val);
                          _updateCustomPreferences();
                        },
                      ),

                      const SizedBox(height: 12),

                      // Slider: Walking Speed Multiplier
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.10),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.directions_walk_rounded,
                                      color: Colors.white70,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Walking Pace Multiplier',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${_walkingSpeedMultiplier.toStringAsFixed(1)}x',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: _walkingSpeedMultiplier,
                              min: 0.6,
                              max: 1.4,
                              divisions: 8,
                              activeColor: Colors.white,
                              inactiveColor: Colors.white24,
                              onChanged: (val) {
                                setState(() => _walkingSpeedMultiplier = val);
                                _updateCustomPreferences();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF94A3B8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.white.withValues(alpha: 0.35),
            inactiveThumbColor: Colors.white38,
            inactiveTrackColor: Colors.white10,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
