class OnboardingProfile {
  const OnboardingProfile({
    required this.fullName,
    required this.age,
    required this.birthDate,
    required this.sex,
    required this.genderIdentity,
    required this.heightCm,
    required this.weightKg,
    required this.goal,
    required this.activityLevel,
    required this.workoutDaysPerWeek,
    required this.sessionMinutes,
    required this.trainingLocation,
    required this.cookingStyle,
    required this.mealsPerDay,
    required this.equipment,
    required this.dietaryPreferences,
    required this.allergies,
    required this.foodDislikes,
    required this.restrictions,
    required this.bodyMeasurements,
    required this.additionalNotes,
  });

  final String fullName;
  final int age;
  final String? birthDate;
  final String? sex;
  final String? genderIdentity;
  final int heightCm;
  final int weightKg;
  final String goal;
  final String activityLevel;
  final int workoutDaysPerWeek;
  final int sessionMinutes;
  final String trainingLocation;
  final String cookingStyle;
  final int mealsPerDay;
  final List<String> equipment;
  final List<String> dietaryPreferences;
  final List<String> allergies;
  final List<String> foodDislikes;
  final List<String> restrictions;
  final Map<String, double> bodyMeasurements;
  final String additionalNotes;

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'age': age,
      'birth_date': birthDate,
      'sex': sex,
      'gender_identity': genderIdentity,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'goal': goal,
      'activity_level': activityLevel,
      'workout_days_per_week': workoutDaysPerWeek,
      'session_minutes': sessionMinutes,
      'training_location': trainingLocation,
      'cooking_style': cookingStyle,
      'meals_per_day': mealsPerDay,
      'equipment': equipment,
      'dietary_preferences': dietaryPreferences,
      'allergies': allergies,
      'food_dislikes': foodDislikes,
      'restrictions': restrictions,
      'body_measurements': bodyMeasurements,
      'additional_notes': additionalNotes,
    };
  }

  factory OnboardingProfile.fromJson(Map<String, dynamic> json) {
    return OnboardingProfile(
      fullName: json['full_name']?.toString() ?? '',
      age: json['age'] as int? ?? 30,
      birthDate: json['birth_date']?.toString(),
      sex: json['sex']?.toString(),
      genderIdentity: json['gender_identity']?.toString(),
      heightCm: json['height_cm'] as int? ?? 175,
      weightKg: json['weight_kg'] as int? ?? 78,
      goal: json['goal']?.toString() ?? 'Perder grasa',
      activityLevel: json['activity_level']?.toString() ?? 'Intermedio',
      workoutDaysPerWeek: json['workout_days_per_week'] as int? ?? 4,
      sessionMinutes: json['session_minutes'] as int? ?? 45,
      trainingLocation: json['training_location']?.toString() ?? 'Mixto',
      cookingStyle: json['cooking_style']?.toString() ?? 'Simple',
      mealsPerDay: json['meals_per_day'] as int? ?? 4,
      equipment: (json['equipment'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      dietaryPreferences:
          (json['dietary_preferences'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList(),
      allergies: (json['allergies'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      foodDislikes: (json['food_dislikes'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      restrictions: (json['restrictions'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      bodyMeasurements:
          (json['body_measurements'] as Map<String, dynamic>? ?? const {}).map(
            (key, value) => MapEntry(key, (value as num?)?.toDouble() ?? 0),
          ),
      additionalNotes: json['additional_notes']?.toString() ?? '',
    );
  }
}
