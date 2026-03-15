import 'dart:async';

import 'package:flutter/material.dart';

import '../../../auth/data/services/auth_session_controller.dart';
import '../../../nutrition/presentation/pages/nutrition_page.dart';
import '../../../onboarding/data/services/onboarding_api_service.dart';
import '../../../progress/presentation/pages/progress_page.dart';
import '../../../subscription/presentation/pages/subscription_page.dart';
import '../../../workout/presentation/pages/workout_page.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/session_data_cache.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/offline_banner.dart';
import '../../../activity/data/services/activity_history_api_service.dart';
import '../../../plans/data/services/plan_api_service.dart';
import '../../../nutrition/data/services/nutrition_api_service.dart';
import '../../../workout/data/services/workout_api_service.dart';
import 'dashboard_page.dart';

class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key});

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  int _selectedIndex = 0;
  bool _hasProfile = false;
  bool _loadingProfile = true;
  late final List<Widget> _pages;
  PageController _pageController = PageController();
  bool _showPageSplash = false;
  bool _isOnline = true;
  StreamSubscription<bool>? _connectivitySub;
  static const _titles = [
    'Inicio',
    'Workout',
    'Nutricion',
    'Progreso',
    'Control',
  ];

  static const _destinations = [
    NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Inicio'),
    NavigationDestination(
      icon: Icon(Icons.fitness_center_rounded),
      label: 'Workout',
    ),
    NavigationDestination(
      icon: Icon(Icons.restaurant_menu_rounded),
      label: 'Nutricion',
    ),
    NavigationDestination(
      icon: Icon(Icons.auto_graph_rounded),
      label: 'Progreso',
    ),
    NavigationDestination(
      icon: Icon(Icons.workspace_premium_rounded),
      label: 'Control',
    ),
  ];


  Future<void> _logout() async {
    await AuthSessionScope.of(context).logout();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRouter.auth, (route) => false);
  }

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardPage(
        key: const PageStorageKey('dashboard-page'),
        onNavigateToTab: _changeTab,
      ),
      const WorkoutPage(key: PageStorageKey('workout-page')),
      const NutritionPage(key: PageStorageKey('nutrition-page')),
      const ProgressPage(key: PageStorageKey('progress-page')),
      const ControlCenterPage(key: PageStorageKey('control-center-page')),
    ];
    _pageController = PageController();
    _loadProfileStatus();
    _warmUpPrimaryData();
    _initConnectivity();
  }

  void _initConnectivity() {
    final service = ConnectivityService.instance;
    _isOnline = service.currentlyOnline;
    service.startPolling(interval: const Duration(seconds: 15));
    _connectivitySub = service.isOnline.listen((online) {
      if (!mounted) return;
      setState(() => _isOnline = online);
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _changeTab(int index) async {
    if (_selectedIndex == index) {
      return;
    }
    setState(() {
      _selectedIndex = index;
      _showPageSplash = true;
    });
    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
    if (!mounted) return;
    setState(() {
      _showPageSplash = false;
    });
  }

  Future<void> _loadProfileStatus() async {
    try {
      final profile = await const OnboardingApiService().fetchLatestProfile();
      if (!mounted) return;
      setState(() {
        _hasProfile = profile != null;
        _loadingProfile = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingProfile = false;
      });
    }
  }

  Future<void> _warmUpPrimaryData() async {
    final cache = SessionDataCache.instance;
    if (cache.hasWorkoutBundle) {
      return;
    }
    try {
      final results = await Future.wait([
        const WorkoutApiService().fetchWorkoutSummary(),
        const NutritionApiService().fetchNutritionSummary(),
        const ActivityHistoryApiService().fetchHistory(),
        const PlanApiService().fetchPlanHistory(),
      ]);
      cache
        ..workoutSummary = results[0] as Map<String, dynamic>
        ..nutritionSummary = results[1] as Map<String, dynamic>
        ..history = results[2] as Map<String, dynamic>
        ..planHistory = results[3] as List<Map<String, dynamic>>;
    } catch (_) {
      // keep shell responsive; pages fall back to their own loading path
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          _TopBarIcon(
            icon: Icons.history_rounded,
            tooltip: 'Historial',
            onTap: () {
              Navigator.of(context).pushNamed(AppRouter.history);
            },
          ),
          _TopBarIcon(
            icon: Icons.flag_rounded,
            tooltip: 'Objetivos',
            onTap: () {
              Navigator.of(context).pushNamed(AppRouter.goals);
            },
          ),
          _TopBarIcon(
            icon: Icons.logout_rounded,
            tooltip: 'Cerrar sesion',
            onTap: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          OfflineBanner(isOffline: !_isOnline),
          Expanded(
            child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.surfaceCanvas, AppColors.surfaceMist],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                  _showPageSplash = true;
                });
                Future.delayed(const Duration(milliseconds: 240), () {
                  if (!mounted) return;
                  setState(() {
                    _showPageSplash = false;
                  });
                });
              },
              children: _pages.map((page) => _ShellStage(child: page)).toList(),
            ),
            IgnorePointer(
              ignoring: !_showPageSplash,
              child: AnimatedOpacity(
                opacity: _showPageSplash ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.gradientSurfaceStart, AppColors.gradientSurfaceEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ],
        ),
            ),
          ),
        ],
      ),
      floatingActionButton:
          _selectedIndex == 0 && !_loadingProfile && !_hasProfile
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.of(
                  context,
                ).pushNamed(AppRouter.onboarding);
                if (result == true) {
                  setState(() {
                    _selectedIndex = 0;
                  });
                  await _loadProfileStatus();
                }
              },
              label: const Text('Completar onboarding'),
              icon: const Icon(Icons.tune_rounded),
            )
          : null,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.cardBorderWarm),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: NavigationBar(
              height: 72,
              selectedIndex: _selectedIndex,
              destinations: _destinations,
              onDestinationSelected: (index) {
                _changeTab(index);
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ShellStage extends StatelessWidget {
  const _ShellStage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class _TopBarIcon extends StatelessWidget {
  const _TopBarIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Material(
        color: Colors.white.withValues(alpha: 0.92),
        shape: const CircleBorder(),
        child: IconButton(
          onPressed: onTap,
          tooltip: tooltip,
          icon: Icon(icon, color: AppColors.primary),
        ),
      ),
    );
  }
}
