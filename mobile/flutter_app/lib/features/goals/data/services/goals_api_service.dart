import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../auth/data/services/auth_session_store.dart';

class GoalsApiService {
  const GoalsApiService();

  Future<Map<String, dynamic>> fetchCurrentGoal() async {
    final session = await AuthSessionStore().load();
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/goals/current'),
      headers: {
        if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudo cargar el objetivo');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> updateGoal({
    required int workoutSessionsTarget,
    required int nutritionAdherenceTarget,
    required int weightCheckinsTarget,
    required bool remindersEnabled,
    required String reminderTime,
  }) async {
    final session = await AuthSessionStore().load();
    final response = await http.put(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/goals/current'),
      headers: {
        'Content-Type': 'application/json',
        if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
      },
      body: jsonEncode({
        'workout_sessions_target': workoutSessionsTarget,
        'nutrition_adherence_target': nutritionAdherenceTarget,
        'weight_checkins_target': weightCheckinsTarget,
        'reminders_enabled': remindersEnabled,
        'reminder_time': reminderTime,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudo actualizar el objetivo');
    }
  }
}
