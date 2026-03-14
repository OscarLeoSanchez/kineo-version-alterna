import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/services/personalized_headers_service.dart';
import '../../../auth/data/services/auth_session_store.dart';
import '../../domain/models/plan_modification.dart';

class PlanModificationApiService {
  const PlanModificationApiService();

  Future<Map<String, String>> _headers({bool withContentType = false}) async {
    final session = await AuthSessionStore().load();
    final personalized =
        await const PersonalizedHeadersService().build();
    return {
      ...personalized,
      if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
      if (withContentType) 'Content-Type': 'application/json',
    };
  }

  Future<PlanModification> createModification(
    Map<String, dynamic> data,
  ) async {
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/api/v1/plans/modifications/',
    );

    final response = await http.post(
      uri,
      headers: await _headers(withContentType: true),
      body: jsonEncode(data),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'No se pudo crear la modificación (${response.statusCode})',
      );
    }

    return PlanModification.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<PlanModification>> listModifications() async {
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/api/v1/plans/modifications/',
    );

    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode != 200) {
      throw Exception(
        'No se pudo cargar las modificaciones (${response.statusCode})',
      );
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map(PlanModification.fromJson)
        .toList();
  }

  Future<void> deleteModification(int modId) async {
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/api/v1/plans/modifications/$modId',
    );

    final response =
        await http.delete(uri, headers: await _headers());

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'No se pudo eliminar la modificación $modId (${response.statusCode})',
      );
    }
  }
}
