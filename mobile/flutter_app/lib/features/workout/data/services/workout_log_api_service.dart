import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../auth/data/services/auth_session_store.dart';

class WorkoutLogApiService {
  const WorkoutLogApiService();

  Future<void> submitWorkout({
    required int sessionMinutes,
    required String focus,
    required String energyLevel,
    String notes = '',
  }) async {
    final session = await AuthSessionStore().load();
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/activity/workouts'),
      headers: {
        'Content-Type': 'application/json',
        if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
      },
      body: jsonEncode({
        'session_minutes': sessionMinutes,
        'focus': focus,
        'energy_level': energyLevel,
        'notes': notes,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('No se pudo registrar la sesion');
    }
  }
}
