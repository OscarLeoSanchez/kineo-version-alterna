import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../auth/data/services/auth_session_store.dart';

class ReportsApiService {
  const ReportsApiService();

  Future<Map<String, dynamic>> fetchWeeklyReport() async {
    final session = await AuthSessionStore().load();
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/reports/weekly'),
      headers: {
        if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudo cargar el reporte semanal');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
