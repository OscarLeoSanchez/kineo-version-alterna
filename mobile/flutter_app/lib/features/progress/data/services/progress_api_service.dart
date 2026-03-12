import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/services/personalized_headers_service.dart';
import '../../../auth/data/services/auth_session_store.dart';

class ProgressApiService {
  const ProgressApiService();

  Future<Map<String, dynamic>> fetchProgressSummary() async {
    final session = await AuthSessionStore().load();
    final personalizedHeaders = await const PersonalizedHeadersService().build();
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/experience/progress'),
      headers: {
        ...personalizedHeaders,
        if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudo cargar el progreso');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
