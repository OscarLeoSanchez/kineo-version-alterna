import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../auth/data/services/auth_session_store.dart';

class WorkoutBlockApiService {
  const WorkoutBlockApiService();

  Future<void> saveBlockState({
    required String dayIsoDate,
    required String blockTitle,
    required bool completed,
    required List<String> selectedExercises,
    int? planId,
  }) async {
    final session = await AuthSessionStore().load();
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/activity/workout-blocks'),
      headers: {
        'Content-Type': 'application/json',
        if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
      },
      body: jsonEncode({
        if (planId != null) 'plan_id': planId,
        'day_iso_date': dayIsoDate,
        'block_title': blockTitle,
        'completed': completed,
        'selected_exercises': selectedExercises,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('No se pudo guardar el estado del bloque');
    }
  }
}
