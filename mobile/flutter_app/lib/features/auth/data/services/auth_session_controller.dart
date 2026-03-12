import 'package:flutter/widgets.dart';

import '../../domain/models/auth_session.dart';
import 'auth_api_service.dart';
import 'auth_session_store.dart';

class AuthSessionController extends ChangeNotifier {
  AuthSessionController({
    AuthSessionStore? store,
    AuthApiService? apiService,
  }) : _store = store ?? AuthSessionStore(),
       _apiService = apiService ?? const AuthApiService();

  final AuthSessionStore _store;
  final AuthApiService _apiService;

  AuthSession? _session;
  bool _isReady = false;

  AuthSession? get session => _session;
  bool get isReady => _isReady;
  bool get isAuthenticated => _session != null;

  Future<void> bootstrap() async {
    final storedSession = await _store.load();
    if (storedSession == null) {
      _session = null;
      _isReady = true;
      notifyListeners();
      return;
    }

    try {
      final refreshedSession = await _apiService.me(storedSession.accessToken);
      _session = refreshedSession;
      await _store.save(refreshedSession);
    } catch (_) {
      await _store.clear();
      _session = null;
    }

    _isReady = true;
    notifyListeners();
  }

  Future<void> setSession(AuthSession session) async {
    _session = session;
    _isReady = true;
    await _store.save(session);
    notifyListeners();
  }

  Future<void> updateProfileName(String fullName) async {
    final currentSession = _session;
    if (currentSession == null) {
      return;
    }

    final updatedSession = await _apiService.updateProfile(
      token: currentSession.accessToken,
      fullName: fullName,
    );
    await setSession(updatedSession);
  }

  Future<void> logout() async {
    await _store.clear();
    _session = null;
    _isReady = true;
    notifyListeners();
  }
}

class AuthSessionScope extends InheritedNotifier<AuthSessionController> {
  const AuthSessionScope({
    super.key,
    required AuthSessionController controller,
    required super.child,
  }) : super(notifier: controller);

  static AuthSessionController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AuthSessionScope>();
    assert(scope != null, 'AuthSessionScope no disponible en este contexto.');
    return scope!.notifier!;
  }
}
