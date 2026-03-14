class SessionDataCache {
  SessionDataCache._();

  static final SessionDataCache instance = SessionDataCache._();

  Map<String, dynamic>? workoutSummary;
  Map<String, dynamic>? nutritionSummary;
  Map<String, dynamic>? history;
  List<Map<String, dynamic>>? planHistory;

  bool get hasWorkoutBundle =>
      workoutSummary != null &&
      nutritionSummary != null &&
      history != null &&
      planHistory != null;
}
