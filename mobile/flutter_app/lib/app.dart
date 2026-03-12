import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/services/auth_session_controller.dart';
import 'features/splash/presentation/pages/splash_page.dart';

class KineoCoachApp extends StatefulWidget {
  const KineoCoachApp({super.key});

  @override
  State<KineoCoachApp> createState() => _KineoCoachAppState();
}

class _KineoCoachAppState extends State<KineoCoachApp> {
  late final AuthSessionController _sessionController;
  late final Future<void> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _sessionController = AuthSessionController();
    _bootstrapFuture = _sessionController.bootstrap();
  }

  @override
  void dispose() {
    _sessionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthSessionScope(
      controller: _sessionController,
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: AppBootstrap(bootstrapFuture: _bootstrapFuture),
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}

class AppBootstrap extends StatelessWidget {
  const AppBootstrap({super.key, required this.bootstrapFuture});

  final Future<void> bootstrapFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: bootstrapFuture,
      builder: (context, snapshot) {
        final sessionController = AuthSessionScope.of(context);

        if (snapshot.connectionState != ConnectionState.done ||
            !sessionController.isReady) {
          return const SplashPage();
        }

        return AppRouter.buildPage(
          sessionController.isAuthenticated
              ? AppRouter.dashboard
              : AppRouter.auth,
        );
      },
    );
  }
}
