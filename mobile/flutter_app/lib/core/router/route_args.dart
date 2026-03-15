/// Typed argument classes for named routes.
/// Use these when calling Navigator.pushNamed to avoid unsafe dynamic casts.

class ShoppingListArgs {
  final List<Map<String, dynamic>> meals;
  final String? planDate;
  const ShoppingListArgs({required this.meals, this.planDate});
}

class WorkoutModeArgs {
  final Map<String, dynamic> workoutDay;
  final String? planId;
  const WorkoutModeArgs({required this.workoutDay, this.planId});
}

class WorkoutSessionArgs {
  final Map<String, dynamic> workoutDay;
  const WorkoutSessionArgs({required this.workoutDay});
}

/// Route name constants. Prefer these over raw string literals.
class AppRoutes {
  const AppRoutes._();

  static const home = '/';
  static const auth = '/auth';
  static const onboarding = '/onboarding';
  static const history = '/history';
  static const goals = '/goals';
  static const planGeneration = '/plan-generation';
  static const profile = '/profile';
  static const controlCenter = '/control-center';
  static const workoutSession = '/workout-session';
  static const workoutMode = '/workout-mode';
  static const shoppingList = '/shopping-list';
  static const progress = '/progress';
}
