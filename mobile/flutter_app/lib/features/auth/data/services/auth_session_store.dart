import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/auth_session.dart';

class AuthSessionStore {
  static const _tokenKey = 'auth.access_token';
  static const _emailKey = 'auth.email';
  static const _fullNameKey = 'auth.full_name';

  Future<void> save(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, session.accessToken);
    await prefs.setString(_emailKey, session.email);
    await prefs.setString(_fullNameKey, session.fullName);
  }

  Future<AuthSession?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      return null;
    }

    return AuthSession(
      accessToken: token,
      email: prefs.getString(_emailKey) ?? '',
      fullName: prefs.getString(_fullNameKey) ?? '',
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_fullNameKey);
  }
}
