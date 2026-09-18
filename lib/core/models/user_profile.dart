/// User preferences configuring journey options.
/// General-purpose: core routing algorithms evaluate these preferences,
/// rather than hardcoded persona strings.
class UserPreferences {
  final bool requiresWheelchair;
  final bool avoidStairs;
  final bool preferSheltered;
  final bool highDisruptionSensitivity;
  final double walkingSpeedMultiplier; // 1.0 = normal, 0.7 = slower (e.g. elderly)

  const UserPreferences({
    this.requiresWheelchair = false,
    this.avoidStairs = false,
    this.preferSheltered = false,
    this.highDisruptionSensitivity = false,
    this.walkingSpeedMultiplier = 1.0,
  });

  UserPreferences copyWith({
    bool? requiresWheelchair,
    bool? avoidStairs,
    bool? preferSheltered,
    bool? highDisruptionSensitivity,
    double? walkingSpeedMultiplier,
  }) {
    return UserPreferences(
      requiresWheelchair: requiresWheelchair ?? this.requiresWheelchair,
      avoidStairs: avoidStairs ?? this.avoidStairs,
      preferSheltered: preferSheltered ?? this.preferSheltered,
      highDisruptionSensitivity:
          highDisruptionSensitivity ?? this.highDisruptionSensitivity,
      walkingSpeedMultiplier:
          walkingSpeedMultiplier ?? this.walkingSpeedMultiplier,
    );
  }
}

/// User account / profile representing a commuter.
class UserProfile {
  final String id;
  final String name;
  final String badge;
  final String description;
  final String defaultOrigin;
  final String defaultDestination;
  final UserPreferences preferences;

  const UserProfile({
    required this.id,
    required this.name,
    required this.badge,
    required this.description,
    required this.defaultOrigin,
    required this.defaultDestination,
    required this.preferences,
  });

  /// Standard general commuter (no special constraints)
  static const UserProfile general = UserProfile(
    id: 'general',
    name: 'General Commuter',
    badge: '👤 Standard',
    description: 'Standard multi-modal transit with normal walking pace',
    defaultOrigin: 'Bugis',
    defaultDestination: 'HarbourFront',
    preferences: UserPreferences(),
  );

  /// Demo User: Rachel (Fixed-schedule commuter on East-West Line)
  static const UserProfile demoRachel = UserProfile(
    id: 'demo_rachel',
    name: 'Rachel (Demo)',
    badge: '👩‍💼 Fixed Schedule',
    description: 'Tampines ➔ Raffles Place daily commuter. Strict 08:45 arrival.',
    defaultOrigin: 'Tampines',
    defaultDestination: 'Raffles Place',
    preferences: UserPreferences(
      highDisruptionSensitivity: true,
      walkingSpeedMultiplier: 1.1,
    ),
  );

  /// Demo User: Mdm Lim (Accessibility-constrained occasional traveler)
  static const UserProfile demoMdmLim = UserProfile(
    id: 'demo_mdm_lim',
    name: 'Mdm Lim (Demo)',
    badge: '👵 Accessibility',
    description: 'Bedok ➔ SGH clinic. Requires step-free lifts and covered paths.',
    defaultOrigin: 'Bedok',
    defaultDestination: 'Singapore General Hospital',
    preferences: UserPreferences(
      requiresWheelchair: true,
      avoidStairs: true,
      preferSheltered: true,
      walkingSpeedMultiplier: 0.7,
    ),
  );

  /// All demo user profiles available for quick evaluator switching
  static const List<UserProfile> allProfiles = [
    general,
    demoRachel,
    demoMdmLim,
  ];

  UserProfile copyWith({
    String? id,
    String? name,
    String? badge,
    String? description,
    String? defaultOrigin,
    String? defaultDestination,
    UserPreferences? preferences,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      badge: badge ?? this.badge,
      description: description ?? this.description,
      defaultOrigin: defaultOrigin ?? this.defaultOrigin,
      defaultDestination: defaultDestination ?? this.defaultDestination,
      preferences: preferences ?? this.preferences,
    );
  }
}
