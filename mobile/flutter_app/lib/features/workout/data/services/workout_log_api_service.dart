import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../activity/data/services/offline_activity_queue_service.dart';
import '../../../auth/data/services/auth_session_store.dart';

class WorkoutSubmitResult {
  const WorkoutSubmitResult({required this.sent, required this.queuedOffline});

  final bool sent;
  final bool queuedOffline;
}

class WorkoutLogApiService {
  const WorkoutLogApiService();

  Future<WorkoutSubmitResult> submitWorkout({
    required int sessionMinutes,
    required String focus,
    required String energyLevel,
    String? dayIsoDate,
    int? planId,
    List<Map<String, dynamic>> blockStates = const [],
    String notes = '',
  }) async {
    final session = await AuthSessionStore().load();
    final payload = {
      'session_minutes': sessionMinutes,
      'focus': focus,
      'energy_level': energyLevel,
      if (dayIsoDate != null) 'day_iso_date': dayIsoDate,
      if (planId != null) 'plan_id': planId,
      'block_states': blockStates,
      'notes': notes,
    };
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/v1/activity/workouts'),
        headers: {
          'Content-Type': 'application/json',
          if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('No se pudo registrar la sesion');
      }
      await const OfflineActivityQueueService().flush();
      return const WorkoutSubmitResult(sent: true, queuedOffline: false);
    } catch (_) {
      await const OfflineActivityQueueService().enqueueWorkout(payload);
      return const WorkoutSubmitResult(sent: false, queuedOffline: true);
    }
  }
}
