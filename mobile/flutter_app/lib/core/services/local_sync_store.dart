import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalSyncStore {
  static const _workoutSummaryKey = 'cache.workout.summary';
  static const _nutritionSummaryKey = 'cache.nutrition.summary';
  static const _historyKey = 'cache.activity.history';
  static const _pendingWorkoutsKey = 'queue.workouts';
  static const _pendingNutritionKey = 'queue.nutrition';

  const LocalSyncStore();

  Future<Map<String, dynamic>?> readWorkoutSummary() =>
      _readJsonObject(_workoutSummaryKey);

  Future<void> writeWorkoutSummary(Map<String, dynamic> data) =>
      _writeJsonObject(_workoutSummaryKey, data);

  Future<Map<String, dynamic>?> readNutritionSummary() =>
      _readJsonObject(_nutritionSummaryKey);

  Future<void> writeNutritionSummary(Map<String, dynamic> data) =>
      _writeJsonObject(_nutritionSummaryKey, data);

  Future<Map<String, dynamic>?> readHistory() => _readJsonObject(_historyKey);

  Future<void> writeHistory(Map<String, dynamic> data) =>
      _writeJsonObject(_historyKey, data);

  Future<List<Map<String, dynamic>>> readPendingWorkouts() =>
      _readJsonList(_pendingWorkoutsKey);

  Future<void> writePendingWorkouts(List<Map<String, dynamic>> items) =>
      _writeJsonList(_pendingWorkoutsKey, items);

  Future<List<Map<String, dynamic>>> readPendingNutrition() =>
      _readJsonList(_pendingNutritionKey);

  Future<void> writePendingNutrition(List<Map<String, dynamic>> items) =>
      _writeJsonList(_pendingNutritionKey, items);

  Future<Map<String, dynamic>?> _readJsonObject(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return (jsonDecode(raw) as Map).cast<String, dynamic>();
  }

  Future<void> _writeJsonObject(String key, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(data));
  }

  Future<List<Map<String, dynamic>>> _readJsonList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    return (jsonDecode(raw) as List<dynamic>)
        .map((item) => (item as Map).cast<String, dynamic>())
        .toList();
  }

  Future<void> _writeJsonList(
    String key,
    List<Map<String, dynamic>> items,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(items));
  }
}
