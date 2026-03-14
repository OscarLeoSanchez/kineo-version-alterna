import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../auth/data/services/auth_session_store.dart';

class NutritionPhotoApiService {
  const NutritionPhotoApiService();

  Future<Map<String, dynamic>> analyzePhoto({
    required String mealLabel,
    required String filePath,
  }) async {
    final session = await AuthSessionStore().load();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        '${AppConfig.apiBaseUrl}/api/v1/experience/nutrition/photo-analysis',
      ),
    );
    if (session != null) {
      request.headers['Authorization'] = 'Bearer ${session.accessToken}';
    }
    request.fields['meal_label'] = mealLabel;
    request.files.add(await http.MultipartFile.fromPath('photo', filePath));
    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('No se pudo analizar la foto');
    }
    return jsonDecode(body) as Map<String, dynamic>;
  }
}
