import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../domain/models/auth_session.dart';

class AuthApiService {
  const AuthApiService();

  Future<AuthSession> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await http.post(
      _buildUri('/api/v1/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'full_name': fullName,
      }),
    );
    return _parseSession(response);
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      _buildUri('/api/v1/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _parseSession(response);
  }

  Future<AuthSession> me(String token) async {
    final response = await http.get(
      _buildUri('/api/v1/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Sesion invalida');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return AuthSession(
      accessToken: token,
      email: body['email'] as String,
      fullName: body['full_name'] as String,
    );
  }

  Future<AuthSession> updateProfile({
    required String token,
    required String fullName,
  }) async {
    final response = await http.patch(
      _buildUri('/api/v1/auth/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'full_name': fullName}),
    );

    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(response));
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return AuthSession(
      accessToken: token,
      email: body['email'] as String,
      fullName: body['full_name'] as String,
    );
  }

  Future<String> checkApiConnection() async {
    final healthUri = _buildUri('/api/v1/health');
    final response = await http.get(
      healthUri,
    );
    if (response.statusCode != 200) {
      final bodyPreview = response.body.isEmpty ? 'sin contenido' : response.body;
      throw Exception(
        'API sin respuesta valida en $healthUri (status ${response.statusCode}): $bodyPreview',
      );
    }
    return 'API conectada en $healthUri';
  }

  Uri _buildUri(String path) {
    return Uri.parse('${AppConfig.apiBaseUrl}$path');
  }

  AuthSession _parseSession(http.Response response) {
    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(response));
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final user = body['user'] as Map<String, dynamic>;
    return AuthSession(
      accessToken: body['access_token'] as String,
      email: user['email'] as String,
      fullName: user['full_name'] as String,
    );
  }

  String _extractErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final detail = body['detail'];
        if (detail is String && detail.isNotEmpty) {
          if (detail == 'Email already registered') {
            return 'Ese correo ya esta registrado. Prueba ingresar.';
          }
          if (detail == 'Invalid credentials') {
            return 'Credenciales invalidas. Revisa tu correo y contrasena.';
          }
          return detail;
        }
        if (detail is List) {
          final issues = detail
              .whereType<Map<String, dynamic>>()
              .map((issue) {
                final path = (issue['loc'] as List<dynamic>? ?? const [])
                    .whereType<String>()
                    .where((segment) => segment != 'body')
                    .join(' > ');
                final message = issue['msg'] as String? ?? 'Valor invalido';
                if (path.isEmpty) {
                  return message;
                }
                return '$path: $message';
              })
              .where((message) => message.isNotEmpty)
              .join('. ');
          if (issues.isNotEmpty) {
            return issues;
          }
        }
      }
    } catch (_) {
      // Fallback to status-based messages below when body is not JSON.
    }

    return switch (response.statusCode) {
      409 => 'Ese correo ya esta registrado. Prueba ingresar.',
      401 => 'Credenciales invalidas. Revisa tu correo y contrasena.',
      422 => 'Revisa los datos enviados. El correo debe ser valido y la contrasena debe tener al menos 4 caracteres.',
      _ => 'No fue posible autenticarte en este momento.',
    };
  }
}
