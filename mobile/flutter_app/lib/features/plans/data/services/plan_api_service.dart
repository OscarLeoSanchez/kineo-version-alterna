import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/services/personalized_headers_service.dart';
import '../../../auth/data/services/auth_session_store.dart';

class PlanApiService {
  const PlanApiService();

  Future<Map<String, dynamic>> fetchCurrentPlan() async {
    final session = await AuthSessionStore().load();
    final personalizedHeaders = await const PersonalizedHeadersService()
        .build();
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/plans/current'),
      headers: {
        ...personalizedHeaders,
        if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudo cargar el plan');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> fetchPlanHistory() async {
    final session = await AuthSessionStore().load();
    final personalizedHeaders = await const PersonalizedHeadersService()
        .build();
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/plans/history'),
      headers: {
        ...personalizedHeaders,
        if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudo cargar el historial de planes');
    }

    return (jsonDecode(response.body) as List<dynamic>)
        .cast<Map<String, dynamic>>();
  }
}
