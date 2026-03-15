import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'route_args.dart';
import '../../features/auth/presentation/pages/auth_page.dart';
import '../../features/dashboard/presentation/pages/home_shell.dart';
import '../../features/history/presentation/pages/history_page.dart';
import '../../features/nutrition/presentation/pages/shopping_list_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/plans/presentation/pages/plan_generation_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/progress/presentation/pages/progress_page.dart';
import '../../features/settings/presentation/pages/goals_settings_page.dart';
import '../../features/subscription/presentation/pages/subscription_page.dart';
import '../../features/workout/presentation/screens/workout_mode_screen.dart';
import '../../features/workout/presentation/screens/workout_session_screen.dart';

class AppRouter {
  static const String auth = '/auth';
  static const String dashboard = '/';
  static const String history = '/history';
  static const String goals = '/goals';
  static const String onboarding = '/onboarding';
  static const String planGeneration = '/plan-generation';
  static const String profile = '/profile';
  static const String controlCenter = '/control-center';
  static const String workoutMode = '/workout-mode';
  static const String workoutSession = '/workout-session';
  static const String progress = '/progress';
  static const String shoppingList = '/shopping-list';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case auth:
        return _buildAnimatedRoute(settings);
      case onboarding:
        return _buildAnimatedRoute(settings);
      case history:
        return _buildAnimatedRoute(settings);
      case goals:
        return _buildAnimatedRoute(settings);
      case planGeneration:
        return _buildAnimatedRoute(settings);
      case profile:
        return _buildAnimatedRoute(settings);
      case controlCenter:
        return _buildAnimatedRoute(settings);
      case workoutMode:
        return _buildAnimatedRoute(settings);
      case progress:
        return _buildAnimatedRoute(settings);
      case shoppingList:
        return _buildAnimatedRoute(settings);
      case workoutSession:
        return _buildAnimatedRoute(settings);
      case dashboard:
      default:
        return _buildAnimatedRoute(settings);
    }
  }

  static PageRouteBuilder<void> _buildAnimatedRoute(RouteSettings settings) {
    return PageRouteBuilder<void>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, animation, __) {
        return buildPage(settings.name, settings);
      },
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final fade = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        final slide = Tween<Offset>(
          begin: const Offset(0.03, 0.02),
          end: Offset.zero,
        ).animate(fade);
        final scale = Tween<double>(
          begin: 0.985,
          end: 1,
        ).animate(fade);
        return Stack(
          fit: StackFit.expand,
          children: [
            FadeTransition(
              opacity: fade,
              child: SlideTransition(
                position: slide,
                child: ScaleTransition(
                  scale: scale,
                  child: child,
                ),
              ),
            ),
            IgnorePointer(
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, _) {
                  final splashOpacity = (1 - animation.value) * 0.26;
                  return Opacity(
                    opacity: splashOpacity.clamp(0, 1),
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.gradientSurfaceStart, AppColors.gradientSurfaceEnd],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  static Widget buildPage(String? routeName, [RouteSettings? settings]) {
    switch (routeName) {
      case auth:
        return const AuthPage();
      case onboarding:
        return const OnboardingPage();
      case history:
        return const HistoryPage();
      case goals:
        return const GoalsSettingsPage();
      case planGeneration:
        return const PlanGenerationPage();
      case profile:
        return const ProfilePage();
      case controlCenter:
        return const ControlCenterPage();
      case workoutMode:
        final rawArgs = settings?.arguments;
        if (rawArgs is WorkoutModeArgs) {
          // New typed path: WorkoutModeArgs carries workoutDay + planId.
          // WorkoutModeScreen still accepts the flat fields — extract them.
          final day = rawArgs.workoutDay;
          return WorkoutModeScreen(
            exerciseName: day['exerciseName'] as String? ?? '',
            dayIsoDate: day['dayIsoDate'] as String? ??
                DateTime.now().toIso8601String().substring(0, 10),
            blockTitle: day['blockTitle'] as String?,
          );
        } else if (rawArgs is Map<String, dynamic>) {
          // Legacy map path — still supported.
          return WorkoutModeScreen(
            exerciseName: rawArgs['exerciseName'] as String? ?? '',
            dayIsoDate: rawArgs['dayIsoDate'] as String? ??
                DateTime.now().toIso8601String().substring(0, 10),
            blockTitle: rawArgs['blockTitle'] as String?,
          );
        } else if (rawArgs != null) {
          return _RouteErrorPage(
            routeName: workoutMode,
            expected: 'WorkoutModeArgs or Map<String, dynamic>',
            received: rawArgs.runtimeType.toString(),
          );
        }
        return WorkoutModeScreen(
          exerciseName: '',
          dayIsoDate: DateTime.now().toIso8601String().substring(0, 10),
        );
      case progress:
        return const ProgressPage();
      case shoppingList:
        final rawShoppingArgs = settings?.arguments;
        if (rawShoppingArgs is ShoppingListArgs) {
          return ShoppingListPage(weeklyMeals: rawShoppingArgs.meals);
        } else if (rawShoppingArgs is List) {
          // Legacy list path — still supported.
          return ShoppingListPage(weeklyMeals: rawShoppingArgs);
        } else if (rawShoppingArgs != null) {
          return _RouteErrorPage(
            routeName: shoppingList,
            expected: 'ShoppingListArgs or List',
            received: rawShoppingArgs.runtimeType.toString(),
          );
        }
        return ShoppingListPage(weeklyMeals: const []);
      case workoutSession:
        final rawSessionArgs = settings?.arguments;
        if (rawSessionArgs is WorkoutSessionArgs) {
          return WorkoutSessionScreen(workoutDay: rawSessionArgs.workoutDay);
        } else if (rawSessionArgs is Map<String, dynamic>) {
          // Legacy map path — still supported.
          return WorkoutSessionScreen(workoutDay: rawSessionArgs);
        } else if (rawSessionArgs != null) {
          return _RouteErrorPage(
            routeName: workoutSession,
            expected: 'WorkoutSessionArgs or Map<String, dynamic>',
            received: rawSessionArgs.runtimeType.toString(),
          );
        }
        return WorkoutSessionScreen(workoutDay: const {});
      case dashboard:
      default:
        return const HomeShellPage();
    }
  }
}

/// Shown when a route receives arguments of an unexpected type.
class _RouteErrorPage extends StatelessWidget {
  const _RouteErrorPage({
    required this.routeName,
    required this.expected,
    required this.received,
  });

  final String routeName;
  final String expected;
  final String received;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error de navegación')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Argumento inesperado para "$routeName"',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Se esperaba: $expected\nSe recibió: $received',
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRouter.dashboard,
                  (route) => false,
                );
              },
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    );
  }
}
