import 'package:flutter/material.dart';

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
                          colors: [Color(0xFFF5E8D7), Color(0xFFE0ECE6)],
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
        final args =
            settings?.arguments as Map<String, dynamic>? ?? const {};
        return WorkoutModeScreen(
          exerciseName: args['exerciseName'] as String? ?? '',
          dayIsoDate: args['dayIsoDate'] as String? ??
              DateTime.now().toIso8601String().substring(0, 10),
          blockTitle: args['blockTitle'] as String?,
        );
      case progress:
        return const ProgressPage();
      case shoppingList:
        final meals =
            settings?.arguments as List<dynamic>? ?? const <dynamic>[];
        return ShoppingListPage(weeklyMeals: meals);
      case dashboard:
      default:
        return const HomeShellPage();
    }
  }
}
