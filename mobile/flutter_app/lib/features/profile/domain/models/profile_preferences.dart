class ProfilePreferences {
  const ProfilePreferences({
    required this.coachingStyle,
    required this.units,
    required this.remindersEnabled,
    required this.experienceMode,
    required this.dailyPriority,
    required this.recommendationDepth,
    required this.proactiveAdjustments,
  });

  final String coachingStyle;
  final String units;
  final bool remindersEnabled;
  final String experienceMode;
  final String dailyPriority;
  final String recommendationDepth;
  final bool proactiveAdjustments;

  factory ProfilePreferences.defaults() {
    return const ProfilePreferences(
      coachingStyle: 'Equilibrado',
      units: 'Metricas',
      remindersEnabled: true,
      experienceMode: 'Full',
      dailyPriority: 'Adherencia',
      recommendationDepth: 'Profunda',
      proactiveAdjustments: true,
    );
  }

  ProfilePreferences copyWith({
    String? coachingStyle,
    String? units,
    bool? remindersEnabled,
    String? experienceMode,
    String? dailyPriority,
    String? recommendationDepth,
    bool? proactiveAdjustments,
  }) {
    return ProfilePreferences(
      coachingStyle: coachingStyle ?? this.coachingStyle,
      units: units ?? this.units,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      experienceMode: experienceMode ?? this.experienceMode,
      dailyPriority: dailyPriority ?? this.dailyPriority,
      recommendationDepth: recommendationDepth ?? this.recommendationDepth,
      proactiveAdjustments:
          proactiveAdjustments ?? this.proactiveAdjustments,
    );
  }

  String get membershipPlan => experienceMode;
}
