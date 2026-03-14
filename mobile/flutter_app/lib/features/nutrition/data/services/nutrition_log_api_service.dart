import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../activity/data/services/offline_activity_queue_service.dart';
import '../../../auth/data/services/auth_session_store.dart';

class NutritionSubmitResult {
  const NutritionSubmitResult({
    required this.sent,
    required this.queuedOffline,
  });

  final bool sent;
  final bool queuedOffline;
}

class NutritionLogApiService {
  const NutritionLogApiService();

  Future<NutritionSubmitResult> submitNutrition({
    required String mealLabel,
    required int adherenceScore,
    required int proteinGrams,
    required int hydrationLiters,
    String notes = '',
  }) async {
    final session = await AuthSessionStore().load();
    final payload = {
      'meal_label': mealLabel,
      'adherence_score': adherenceScore,
      'protein_grams': proteinGrams,
      'hydration_liters': hydrationLiters,
      'notes': notes,
    };
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/v1/activity/nutrition'),
        headers: {
          'Content-Type': 'application/json',
          if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('No se pudo registrar la nutricion');
      }
      await const OfflineActivityQueueService().flush();
      return const NutritionSubmitResult(sent: true, queuedOffline: false);
    } catch (_) {
      await const OfflineActivityQueueService().enqueueNutrition(payload);
      return const NutritionSubmitResult(sent: false, queuedOffline: true);
    }
  }
}
