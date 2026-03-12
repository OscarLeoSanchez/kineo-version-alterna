import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../auth/data/services/auth_session_store.dart';

class NutritionLogApiService {
  const NutritionLogApiService();

  Future<void> submitNutrition({
    required String mealLabel,
    required int adherenceScore,
    required int proteinGrams,
    required int hydrationLiters,
    String notes = '',
  }) async {
    final session = await AuthSessionStore().load();
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/activity/nutrition'),
      headers: {
        'Content-Type': 'application/json',
        if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
      },
      body: jsonEncode({
        'meal_label': mealLabel,
        'adherence_score': adherenceScore,
        'protein_grams': proteinGrams,
        'hydration_liters': hydrationLiters,
        'notes': notes,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('No se pudo registrar la nutricion');
    }
  }
}
