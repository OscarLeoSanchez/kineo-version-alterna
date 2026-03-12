import 'package:flutter/material.dart';

import '../../../auth/data/services/auth_session_controller.dart';
import '../../../nutrition/presentation/pages/nutrition_page.dart';
import '../../../onboarding/data/services/onboarding_api_service.dart';
import '../../../progress/presentation/pages/progress_page.dart';
import '../../../subscription/presentation/pages/subscription_page.dart';
import '../../../workout/presentation/pages/workout_page.dart';
import '../../../../core/router/app_router.dart';
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
  late final PageController _pageController;
  bool _showPageSplash = false;
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

  final _pages = const [
    DashboardPage(key: PageStorageKey('dashboard-page')),
    WorkoutPage(key: PageStorageKey('workout-page')),
    NutritionPage(key: PageStorageKey('nutrition-page')),
    ProgressPage(key: PageStorageKey('progress-page')),
    ControlCenterPage(key: PageStorageKey('control-center-page')),
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
    _pageController = PageController();
    _loadProfileStatus();
  }

  @override
  void dispose() {
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
            icon: Icons.account_circle_rounded,
            tooltip: 'Perfil',
            onTap: () {
              Navigator.of(context).pushNamed(AppRouter.profile);
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5EFE4), Color(0xFFEAEFEC)],
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
              children: List.generate(
                _pages.length,
                (index) => _ShellStage(child: _pages[index]),
              ),
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
                      colors: [Color(0xFFF5E8D7), Color(0xFFE3EEE8)],
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
      floatingActionButton: _selectedIndex == 0 && !_loadingProfile && !_hasProfile
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
              border: Border.all(color: const Color(0xFFD6DDD7)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF143C3A).withValues(alpha: 0.08),
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
  const _ShellStage({
    required this.child,
  });

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
          icon: Icon(icon, color: const Color(0xFF143C3A)),
        ),
      ),
    );
  }
}
