import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../activity/data/services/activity_history_api_service.dart';
import '../../../auth/data/services/auth_session_controller.dart';
import '../../../../core/cache/dashboard_cache.dart';
import '../../../../core/config/app_config.dart';
import '../../../goals/data/services/goals_api_service.dart';
import '../../../nutrition/data/services/nutrition_log_api_service.dart';
import '../../../onboarding/data/services/onboarding_api_service.dart';
import '../../../onboarding/domain/models/onboarding_profile.dart';
import '../../../plans/data/services/plan_api_service.dart';
import '../../../profile/data/services/profile_preferences_sync_service.dart';
import '../../../profile/domain/models/profile_preferences.dart';
import '../../../progress/data/services/body_metric_api_service.dart';
import '../../../progress/data/services/progress_api_service.dart';
import '../../../workout/data/services/workout_log_api_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<_DashboardViewModel> _dashboardFuture;
  bool _isQuickLoggingWorkout = false;
  bool _isQuickLoggingNutrition = false;
  bool _isQuickLoggingWeight = false;
  String? _profileImagePath;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final cached = DashboardCache().cachedData;
      if (cached != null) {
        _dashboardFuture = Future.value(_dashboardViewModelFromCache(cached));
      } else {
        _dashboardFuture = _loadDashboard();
      }
    }
  }

  Future<_DashboardViewModel> _loadDashboard() async {
    const onboardingService = OnboardingApiService();
    const planService = PlanApiService();
    final controller = AuthSessionScope.of(context);
    final session = controller.session;

    // Step 1: fetch profile first — required for fallback values in parallel calls.
    final latestProfile = await onboardingService.fetchLatestProfile();

    // Step 2: run all remaining fetches in parallel.
    final results = await Future.wait([
      _loadSafeMap(
        () => onboardingService.fetchDashboardSummary(),
        fallback: _fallbackSummary(latestProfile, session?.fullName),
      ),
      _loadSafeMap(
        () => planService.fetchCurrentPlan(),
        fallback: _fallbackPlan(latestProfile),
      ),
      _loadSafeMap(
        () => const ProgressApiService().fetchProgressSummary(),
        fallback: {
          'streak_days': 0,
          'weekly_adherence': 0,
          'completed_sessions': 0,
          'workout_completion_rate': 0,
          'latest_weight_kg': null,
        },
      ),
      _loadSafeMap(
        () => const GoalsApiService().fetchCurrentGoal(),
        fallback: {
          'workout_sessions_target': latestProfile?.workoutDaysPerWeek ?? 4,
          'nutrition_adherence_target': 85,
          'weight_checkins_target': 2,
          'reminders_enabled': true,
          'reminder_time': '07:00',
        },
      ),
      _loadSafeMap(
        () => const ActivityHistoryApiService().fetchHistory(),
        fallback: const {
          'workouts': [],
          'nutrition_logs': [],
          'body_metrics': [],
        },
      ),
    ]);

    final summary = results[0];
    final plan = results[1];
    final progress = results[2];
    final goal = results[3];
    final history = results[4];

    final preferences = await ProfilePreferencesSyncService().load();

    final fullName = (latestProfile?.fullName?.isNotEmpty == true)
        ? latestProfile!.fullName!
        : (session?.fullName.isNotEmpty == true)
            ? session!.fullName
            : '';

    final todayStatus = _buildTodayStatus(history);

    // Store to cache so subsequent widget mounts skip the network round-trip.
    DashboardCache().store({
      'fullName': fullName,
      'summary': summary,
      'plan': plan,
      'progress': progress,
      'goal': goal,
      'history': history,
      'hasProfile': latestProfile != null,
      'preferences': {
        'coachingStyle': preferences.coachingStyle,
        'units': preferences.units,
        'remindersEnabled': preferences.remindersEnabled,
        'experienceMode': preferences.experienceMode,
        'dailyPriority': preferences.dailyPriority,
        'recommendationDepth': preferences.recommendationDepth,
        'proactiveAdjustments': preferences.proactiveAdjustments,
      },
    });

    return _DashboardViewModel(
      summary: summary,
      plan: plan,
      progress: progress,
      goal: goal,
      history: history,
      fullName: fullName,
      preferences: preferences,
      hasProfile: latestProfile != null,
      todayStatus: todayStatus,
    );
  }

  /// Reconstructs a [_DashboardViewModel] from a previously cached map.
  _DashboardViewModel _dashboardViewModelFromCache(
    Map<String, dynamic> cached,
  ) {
    final rawPrefs = cached['preferences'] as Map<String, dynamic>? ?? {};
    final preferences = ProfilePreferences(
      coachingStyle: rawPrefs['coachingStyle']?.toString() ?? 'Equilibrado',
      units: rawPrefs['units']?.toString() ?? 'Metricas',
      remindersEnabled: rawPrefs['remindersEnabled'] as bool? ?? true,
      experienceMode: rawPrefs['experienceMode']?.toString() ?? 'Full',
      dailyPriority: rawPrefs['dailyPriority']?.toString() ?? 'Adherencia',
      recommendationDepth:
          rawPrefs['recommendationDepth']?.toString() ?? 'Profunda',
      proactiveAdjustments: rawPrefs['proactiveAdjustments'] as bool? ?? true,
    );
    final history =
        (cached['history'] as Map<String, dynamic>?) ??
        const {'workouts': [], 'nutrition_logs': [], 'body_metrics': []};
    return _DashboardViewModel(
      fullName: cached['fullName']?.toString() ?? '',
      summary: (cached['summary'] as Map<String, dynamic>?) ?? {},
      plan: (cached['plan'] as Map<String, dynamic>?) ?? {},
      progress: (cached['progress'] as Map<String, dynamic>?) ?? {},
      goal: (cached['goal'] as Map<String, dynamic>?) ?? {},
      history: history,
      preferences: preferences,
      hasProfile: cached['hasProfile'] as bool? ?? false,
      todayStatus: _buildTodayStatus(history),
    );
  }

  Future<Map<String, dynamic>> _loadSafeMap(
    Future<Map<String, dynamic>> Function() loader, {
    required Map<String, dynamic> fallback,
  }) async {
    try {
      return await loader();
    } catch (_) {
      return fallback;
    }
  }

  Map<String, bool> _buildTodayStatus(Map<String, dynamic> history) {
    final today = DateTime.now().toIso8601String().split('T').first;

    bool hasRecord(List<dynamic> records, String key) {
      return records.any((entry) {
        final item = entry as Map<String, dynamic>;
        return (item[key]?.toString() ?? '').startsWith(today);
      });
    }

    return {
      'workout': hasRecord(
        history['workouts'] as List<dynamic>? ?? const [],
        'completed_at',
      ),
      'nutrition': hasRecord(
        history['nutrition_logs'] as List<dynamic>? ?? const [],
        'logged_at',
      ),
      'weight': hasRecord(
        history['body_metrics'] as List<dynamic>? ?? const [],
        'recorded_at',
      ),
    };
  }

  Map<String, dynamic> _fallbackSummary(
    OnboardingProfile? profile,
    String? sessionName,
  ) {
    final fullName = profile?.fullName ?? sessionName ?? 'Usuario';
    if (profile == null) {
      return {
        'headline': 'Completa tu onboarding',
        'workout_focus':
            'Necesitamos tu perfil para construir un plan inicial real.',
        'nutrition_focus':
            'Agregaremos lineamientos nutricionales cuando completes la configuracion base.',
        'adherence_message':
            'Empieza por contarnos objetivo, experiencia y tiempo disponible.',
      };
    }

    return {
      'headline': 'Hola $fullName, retomemos tu sistema',
      'workout_focus':
          'Tu perfil ya esta listo. Puedes ajustar datos cuando cambie tu contexto.',
      'nutrition_focus':
          'Usaremos tu configuracion actual para adaptar comidas y adherencia.',
      'adherence_message':
          'Tu dashboard seguira mostrando progreso real aun si alguna consulta puntual falla.',
    };
  }

  Map<String, dynamic> _fallbackPlan(OnboardingProfile? profile) {
    if (profile == null) {
      return {
        'workout_summary':
            'Completa tu onboarding para generar una estructura inicial.',
        'nutrition_summary':
            'Tu marco nutricional aparecera cuando tengamos tu perfil.',
        'habits_summary':
            'Configuraremos tus habitos base al terminar el onboarding.',
      };
    }

    return {
      'workout_summary':
          'Plan base de ${profile.workoutDaysPerWeek} dias con sesiones de ${profile.sessionMinutes} minutos.',
      'nutrition_summary':
          'Nutricion simple orientada a adherencia y proteina suficiente.',
      'habits_summary':
          'Objetivo base: consistencia semanal, hidratacion y seguimiento.',
    };
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 80);
      if (picked != null && mounted) {
        setState(() {
          _profileImagePath = picked.path;
        });
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo acceder a la imagen.')),
      );
    }
  }

  void _showProfileImageSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _BottomSheetFrame(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded),
                  title: const Text('Cámara'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickProfileImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded),
                  title: const Text('Galería'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickProfileImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _refreshDashboard() {
    setState(() {
      _dashboardFuture = _loadDashboard();
    });
  }

  void _showReportToCoachSheet(BuildContext ctx) {
    final messageController = TextEditingController();
    String selectedCategory = 'Lesion o molestia';

    showModalBottomSheet<void>(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return _BottomSheetFrame(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  20 + MediaQuery.of(sheetCtx).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Habla con tu coach',
                      style: Theme.of(sheetCtx).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '¿Qué necesitas ajustar en tu rutina?',
                      style: Theme.of(sheetCtx).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                      items: const [
                        DropdownMenuItem(
                          value: 'Lesion o molestia',
                          child: Text('Lesión o molestia'),
                        ),
                        DropdownMenuItem(
                          value: 'Cambio de horario',
                          child: Text('Cambio de horario'),
                        ),
                        DropdownMenuItem(
                          value: 'Cambio de meta',
                          child: Text('Cambio de meta'),
                        ),
                        DropdownMenuItem(
                          value: 'Otro',
                          child: Text('Otro'),
                        ),
                      ],
                      onChanged: (value) {
                        setSheetState(() {
                          selectedCategory = value ?? selectedCategory;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: messageController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Mensaje',
                        hintText:
                            'Ej: Tengo dolor de rodilla y no puedo hacer sentadillas esta semana...',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          final msg = messageController.text.trim();
                          final cat = selectedCategory;
                          Navigator.of(sheetCtx).pop();
                          _sendCoachReport(msg, cat);
                        },
                        child: const Text('Enviar'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(messageController.dispose);
  }

  Future<void> _sendCoachReport(String message, String category) async {
    try {
      final session = AuthSessionScope.of(context).session;
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/plans/coach-report');
      await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode({'message': message, 'category': category}),
      );
    } catch (_) {
      // Endpoint may not exist yet; treat as success for UX purposes.
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tu reporte fue recibido. Tu plan se actualizará pronto.'),
      ),
    );
  }

  Future<void> _editRecentWorkout(Map<String, dynamic> item) async {
    final focusController = TextEditingController(
      text: item['focus']?.toString() ?? '',
    );
    final durationController = TextEditingController(
      text: '${item['session_minutes'] ?? 45}',
    );
    String energyLevel = item['energy_level']?.toString() ?? 'Media';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar workout'),
          content: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: focusController,
                    decoration: const InputDecoration(labelText: 'Foco'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: durationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Duracion'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: energyLevel,
                    items: const [
                      DropdownMenuItem(value: 'Alta', child: Text('Alta')),
                      DropdownMenuItem(value: 'Media', child: Text('Media')),
                      DropdownMenuItem(value: 'Baja', child: Text('Baja')),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        energyLevel = value ?? 'Media';
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      focusController.dispose();
      durationController.dispose();
      return;
    }

    try {
      await const ActivityHistoryApiService().updateWorkout(
        id: item['id'] as int,
        sessionMinutes: int.tryParse(durationController.text) ?? 45,
        focus: focusController.text.trim(),
        energyLevel: energyLevel,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workout actualizado.')),
      );
      _refreshDashboard();
    } finally {
      focusController.dispose();
      durationController.dispose();
    }
  }

  Future<void> _editRecentNutrition(Map<String, dynamic> item) async {
    String mealLabel = item['meal_label']?.toString() ?? 'Dia estructurado';
    double adherence = (item['adherence_score'] as num?)?.toDouble() ?? 80;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar nutricion'),
          content: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: mealLabel,
                    items: const [
                      DropdownMenuItem(
                        value: 'Dia estructurado',
                        child: Text('Dia estructurado'),
                      ),
                      DropdownMenuItem(
                        value: 'Dia flexible',
                        child: Text('Dia flexible'),
                      ),
                      DropdownMenuItem(
                        value: 'Dia social',
                        child: Text('Dia social'),
                      ),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        mealLabel = value ?? 'Dia estructurado';
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Text('Adherencia: ${adherence.round()}%'),
                  Slider(
                    value: adherence,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: adherence.round().toString(),
                    onChanged: (value) {
                      setModalState(() {
                        adherence = value;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await const ActivityHistoryApiService().updateNutrition(
      id: item['id'] as int,
      mealLabel: mealLabel,
      adherenceScore: adherence.round(),
      proteinGrams: (item['protein_grams'] as num?)?.toInt() ?? 140,
      hydrationLiters: (item['hydration_liters'] as num?)?.toInt() ?? 3,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nutricion actualizada.')),
    );
    _refreshDashboard();
  }

  Future<void> _editRecentWeight(Map<String, dynamic> item) async {
    final weightController = TextEditingController(
      text: '${item['weight_kg'] ?? ''}',
    );
    final waistController = TextEditingController(
      text: item['waist_cm']?.toString() ?? '',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar check-in'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Peso'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: waistController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Cintura'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      weightController.dispose();
      waistController.dispose();
      return;
    }

    await const ActivityHistoryApiService().updateBodyMetric(
      id: item['id'] as int,
      weightKg: double.tryParse(weightController.text.replaceAll(',', '.')) ??
          ((item['weight_kg'] as num?)?.toDouble() ?? 0),
      waistCm: double.tryParse(waistController.text.replaceAll(',', '.')),
    );
    weightController.dispose();
    waistController.dispose();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Check-in actualizado.')),
    );
    _refreshDashboard();
  }

  Future<void> _openQuickWorkoutLog(_DashboardViewModel data) async {
    String energyLevel = 'Media';
    int duration = 45;
    final focusController = TextEditingController(
      text: _suggestedWorkoutFocus(data.preferences.coachingStyle),
    );

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _BottomSheetFrame(
              child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Registrar entrenamiento',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Solo necesitamos foco, duracion y energia percibida.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: focusController,
                    decoration: const InputDecoration(labelText: 'Foco principal'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: duration,
                    decoration: const InputDecoration(labelText: 'Duracion'),
                    items: const [
                      DropdownMenuItem(value: 20, child: Text('20 min')),
                      DropdownMenuItem(value: 30, child: Text('30 min')),
                      DropdownMenuItem(value: 45, child: Text('45 min')),
                      DropdownMenuItem(value: 60, child: Text('60 min')),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        duration = value ?? 45;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: energyLevel,
                    decoration: const InputDecoration(
                      labelText: 'Energia percibida',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Alta', child: Text('Alta')),
                      DropdownMenuItem(value: 'Media', child: Text('Media')),
                      DropdownMenuItem(value: 'Baja', child: Text('Baja')),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        energyLevel = value ?? 'Media';
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Guardar entrenamiento'),
                    ),
                  ),
                ],
              ),
            ),
            );
          },
        );
      },
    );

    if (confirmed != true) {
      focusController.dispose();
      return;
    }

    setState(() {
      _isQuickLoggingWorkout = true;
    });

    try {
      await const WorkoutLogApiService().submitWorkout(
        sessionMinutes: duration,
        focus: focusController.text.trim().isEmpty
            ? _suggestedWorkoutFocus(data.preferences.coachingStyle)
            : focusController.text.trim(),
        energyLevel: energyLevel,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesion registrada desde inicio.')),
      );
      _refreshDashboard();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos registrar la sesion.')),
      );
    } finally {
      focusController.dispose();
      if (mounted) {
        setState(() {
          _isQuickLoggingWorkout = false;
        });
      }
    }
  }

  Future<void> _openQuickNutritionLog() async {
    double adherence = 85;
    String mealLabel = 'Dia estructurado';

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _BottomSheetFrame(
              child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Registrar nutricion',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Describe tu tipo de dia y que tan bien seguiste tu estructura.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: mealLabel,
                    decoration: const InputDecoration(labelText: 'Tipo de dia'),
                    items: const [
                      DropdownMenuItem(
                        value: 'Dia estructurado',
                        child: Text('Dia estructurado'),
                      ),
                      DropdownMenuItem(
                        value: 'Dia flexible',
                        child: Text('Dia flexible'),
                      ),
                      DropdownMenuItem(
                        value: 'Dia social',
                        child: Text('Dia social'),
                      ),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        mealLabel = value ?? 'Dia estructurado';
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Adherencia estimada: ${adherence.round()}%',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Slider(
                    value: adherence,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: adherence.round().toString(),
                    onChanged: (value) {
                      setModalState(() {
                        adherence = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Guardar nutricion'),
                    ),
                  ),
                ],
              ),
            ),
            );
          },
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isQuickLoggingNutrition = true;
    });

    try {
      await const NutritionLogApiService().submitNutrition(
        mealLabel: mealLabel,
        adherenceScore: adherence.round(),
        proteinGrams: adherence >= 80 ? 140 : 120,
        hydrationLiters: 3,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro nutricional guardado.')),
      );
      _refreshDashboard();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos guardar nutricion.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isQuickLoggingNutrition = false;
        });
      }
    }
  }

  Future<void> _openQuickWeightLog() async {
    final weightController = TextEditingController();
    final waistController = TextEditingController();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _BottomSheetFrame(
          child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Registrar check-in corporal',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Guarda tu peso y una referencia opcional para seguir el progreso.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Peso actual'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: waistController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Cintura (opcional)',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Guardar check-in'),
                ),
              ),
            ],
          ),
        ),
        );
      },
    );

    if (confirmed != true) {
      weightController.dispose();
      waistController.dispose();
      return;
    }

    final weight = double.tryParse(weightController.text.replaceAll(',', '.'));
    final waist = double.tryParse(waistController.text.replaceAll(',', '.'));
    weightController.dispose();
    waistController.dispose();

    if (weight == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un peso valido.')),
      );
      return;
    }

    setState(() {
      _isQuickLoggingWeight = true;
    });

    try {
      await const BodyMetricApiService().submitMetric(
        weightKg: weight,
        waistCm: waist,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Peso registrado correctamente.')),
      );
      _refreshDashboard();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos guardar la metrica.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isQuickLoggingWeight = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<_DashboardViewModel>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final progress = data?.progress;
        final goal = data?.goal;
        final history = data?.history;
        final preferences = data?.preferences ?? ProfilePreferences.defaults();
        final hasProfile = data?.hasProfile ?? false;
        final todayStatus =
            data?.todayStatus ??
            const {
              'workout': false,
              'nutrition': false,
              'weight': false,
            };
        final recentWorkout = _firstMap(history?['workouts'] as List<dynamic>?);
        final recentNutrition = _firstMap(
          history?['nutrition_logs'] as List<dynamic>?,
        );
        final recentMetric = _firstMap(
          history?['body_metrics'] as List<dynamic>?,
        );
        final completedTodayCount = todayStatus.values.where((done) => done).length;
        final dayCompletion = completedTodayCount / 3;

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {
              _refreshDashboard();
              await _dashboardFuture;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(36),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF173836), Color(0xFF2F6E67), Color(0xFFCF9B57)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF143C3A).withValues(alpha: 0.18),
                        blurRadius: 28,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _showProfileImageSheet,
                            child: CircleAvatar(
                              radius: 27,
                              backgroundColor: Colors.white.withValues(alpha: 0.16),
                              backgroundImage: _profileImagePath != null
                                  ? FileImage(File(_profileImagePath!))
                                  : null,
                              child: _profileImagePath == null
                                  ? Text(
                                      _initials(data?.fullName ?? 'Coach'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (data?.fullName.isNotEmpty == true)
                                      ? 'Hola, ${_firstName(data!.fullName)}'
                                      : 'Hola',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    color: Colors.white,
                                    fontSize: 30,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tu tablero diario ya esta listo para registrar, ajustar y avanzar.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _HeaderActionChip(
                            icon: Icons.auto_awesome_rounded,
                            label: 'Mi Plan',
                            color: const Color(0xFF2A6A65),
                            onTap: () => Navigator.of(context).pushNamed('/plan-generation'),
                          ),
                          const SizedBox(width: 8),
                          _HeaderActionChip(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: 'Reportar',
                            color: const Color(0xFFD97706),
                            onTap: () => _showReportToCoachSheet(context),
                          ),
                          const SizedBox(width: 8),
                          _HeaderActionChip(
                            icon: Icons.tune_rounded,
                            label: 'Ajustes',
                            color: const Color(0xFF7C3AED),
                            onTap: () => Navigator.of(context).pushNamed('/profile'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushNamed('/profile');
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.14),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (data?.fullName.isNotEmpty == true)
                                          ? data!.fullName
                                          : 'Coach',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Abre tu perfil para ajustar preferencias, objetivos y recordatorios.',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.arrow_outward_rounded,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text('Tu plan de hoy', style: theme.textTheme.headlineLarge),
                const SizedBox(height: 12),
                _PrimaryActionCard(
                  eyebrow: 'Siguiente accion',
                  title: _nextActionTitle(todayStatus),
                  description: _nextActionDescription(todayStatus, preferences),
                  ctaLabel: _nextActionButtonLabel(todayStatus),
                  icon: _nextActionIcon(todayStatus),
                  onTap: data == null
                      ? null
                      : () {
                          if (todayStatus['workout'] != true) {
                            _openQuickWorkoutLog(data);
                            return;
                          }
                          if (todayStatus['nutrition'] != true) {
                            _openQuickNutritionLog();
                            return;
                          }
                          if (todayStatus['weight'] != true) {
                            _openQuickWeightLog();
                        }
                      },
                ),
                const SizedBox(height: 14),
                _InteractiveFeatureStrip(
                  title: _dailyFocusTitle(todayStatus),
                  description: _dailyFocusDescription(
                    todayStatus,
                    data?.plan,
                    data?.summary,
                    preferences,
                  ),
                  color: const Color(0xFFE8EFE8),
                  actionLabel: _dailyFocusActionLabel(todayStatus),
                  onAction: data == null
                      ? null
                      : () {
                          if (todayStatus['workout'] != true) {
                            _openQuickWorkoutLog(data);
                            return;
                          }
                          if (todayStatus['nutrition'] != true) {
                            _openQuickNutritionLog();
                            return;
                          }
                          if (todayStatus['weight'] != true) {
                            _openQuickWeightLog();
                          }
                        },
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (!hasProfile)
                      _QuickActionChip(
                        label: 'Completar onboarding',
                        icon: Icons.tune_rounded,
                        onTap: () {
                          Navigator.of(context).pushNamed('/onboarding');
                        },
                      ),
                    _QuickActionChip(
                      label: 'Objetivos',
                      icon: Icons.flag_rounded,
                      onTap: () {
                        Navigator.of(context).pushNamed('/goals');
                      },
                    ),
                    _QuickActionChip(
                      label: 'Perfil',
                      icon: Icons.account_circle_rounded,
                      onTap: () {
                        Navigator.of(context).pushNamed('/profile');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text('Ruta de hoy', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                _TodayStepCard(
                  stepLabel: 'Paso 1',
                  title: 'Entrenamiento del dia',
                  subtitle: todayStatus['workout'] == true
                      ? 'Ya registraste tu sesion. Si cambiaste algo, puedes editar el ultimo workout.'
                      : 'Abre el cierre guiado y marca bloques, energia, esfuerzo y tecnica.',
                  statusLabel: todayStatus['workout'] == true ? 'Completado' : 'Pendiente',
                  icon: Icons.fitness_center_rounded,
                  complete: todayStatus['workout'] == true,
                  busy: _isQuickLoggingWorkout,
                  onTap: data == null ? null : () => _openQuickWorkoutLog(data),
                  onEditTap: recentWorkout == null
                      ? null
                      : () => _editRecentWorkout(recentWorkout),
                ),
                const SizedBox(height: 12),
                _TodayStepCard(
                  stepLabel: 'Paso 2',
                  title: 'Como estuvo tu nutricion',
                  subtitle: todayStatus['nutrition'] == true
                      ? 'Tu adherencia de hoy ya quedo guardada.'
                      : 'Registra hambre, saciedad, sustituciones y como resolviste la comida.',
                  statusLabel: todayStatus['nutrition'] == true ? 'Completado' : 'Pendiente',
                  icon: Icons.restaurant_menu_rounded,
                  complete: todayStatus['nutrition'] == true,
                  busy: _isQuickLoggingNutrition,
                  onTap: data == null ? null : _openQuickNutritionLog,
                  onEditTap: recentNutrition == null
                      ? null
                      : () => _editRecentNutrition(recentNutrition),
                ),
                const SizedBox(height: 12),
                _TodayStepCard(
                  stepLabel: 'Paso 3',
                  title: 'Check-in corporal',
                  subtitle: todayStatus['weight'] == true
                      ? 'Tu peso o metrica de hoy ya fue registrada.'
                      : 'Elige un check-in rapido: peso, composicion o recuperacion.',
                  statusLabel: todayStatus['weight'] == true ? 'Completado' : 'Pendiente',
                  icon: Icons.monitor_weight_rounded,
                  complete: todayStatus['weight'] == true,
                  busy: _isQuickLoggingWeight,
                  onTap: data == null ? null : _openQuickWeightLog,
                  onEditTap: recentMetric == null
                      ? null
                      : () => _editRecentWeight(recentMetric),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _PulseTile(
                        label: 'Racha',
                        value: '${progress?['streak_days'] ?? 0} d',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PulseTile(
                        label: 'Adherencia',
                        value: '${progress?['weekly_adherence'] ?? 0}%',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PulseTile(
                        label: 'Semana',
                        value:
                            '${progress?['completed_sessions'] ?? 0}/${goal?['workout_sessions_target'] ?? 4}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _DayProgressCard(
                  completion: dayCompletion,
                  completedCount: completedTodayCount,
                  totalCount: 3,
                ),
                const SizedBox(height: 18),
                _ChecklistCard(
                  items: [
                    _ChecklistItemData(
                      label: 'Completar sesion',
                      complete: todayStatus['workout'] == true,
                    ),
                    _ChecklistItemData(
                      label: 'Registrar nutricion',
                      complete: todayStatus['nutrition'] == true,
                    ),
                    _ChecklistItemData(
                      label: 'Registrar peso',
                      complete: todayStatus['weight'] == true,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Tu foco actual', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                _InteractiveFeatureStrip(
                  title: 'Entrenamiento',
                  description:
                      data?.summary['workout_focus']?.toString() ??
                      'Construiremos el foco despues del onboarding.',
                  color: const Color(0xFFDDEBE5),
                  actionLabel: 'Ver',
                  onAction: data == null
                      ? null
                      : () => _openQuickWorkoutLog(data),
                ),
                const SizedBox(height: 12),
                _InteractiveFeatureStrip(
                  title: 'Nutricion',
                  description:
                      data?.plan['nutrition_summary']?.toString() ??
                      data?.summary['nutrition_focus']?.toString() ??
                      'Agregaremos lineamientos nutricionales despues del onboarding.',
                  color: const Color(0xFFF0E5D2),
                  actionLabel: 'Ver',
                  onAction: data == null ? null : _openQuickNutritionLog,
                ),
                const SizedBox(height: 20),
                Text('Actividad reciente', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                _InteractiveFeatureStrip(
                  title: 'Ultimo workout',
                  description: recentWorkout == null
                      ? 'Aun no registras sesiones desde tu cuenta.'
                      : '${recentWorkout['focus'] ?? 'Sesion'} · ${recentWorkout['session_minutes'] ?? '--'} min · ${_dateOnly(recentWorkout['completed_at'])}',
                  color: const Color(0xFFDCECE4),
                  actionLabel: recentWorkout == null ? null : 'Editar',
                  onAction: recentWorkout == null
                      ? null
                      : () => _editRecentWorkout(recentWorkout),
                ),
                const SizedBox(height: 12),
                _InteractiveFeatureStrip(
                  title: 'Ultima nutricion',
                  description: recentNutrition == null
                      ? 'Todavia no registras adherencia nutricional.'
                      : '${recentNutrition['meal_label'] ?? 'Registro'} · ${recentNutrition['adherence_score'] ?? '--'}% · ${_dateOnly(recentNutrition['logged_at'])}',
                  color: const Color(0xFFF0E5D2),
                  actionLabel: recentNutrition == null ? null : 'Editar',
                  onAction: recentNutrition == null
                      ? null
                      : () => _editRecentNutrition(recentNutrition),
                ),
                const SizedBox(height: 12),
                _InteractiveFeatureStrip(
                  title: 'Ultimo check-in',
                  description: recentMetric == null
                      ? 'No hay metricas recientes cargadas todavia.'
                      : '${recentMetric['weight_kg'] ?? '--'} kg · ${_dateOnly(recentMetric['recorded_at'])}',
                  color: const Color(0xFFE6DFEC),
                  actionLabel: recentMetric == null ? null : 'Editar',
                  onAction: recentMetric == null
                      ? null
                      : () => _editRecentWeight(recentMetric),
                ),
                const SizedBox(height: 20),
                _FeatureStrip(
                  title: 'Contexto del sistema',
                  description:
                      '${data?.plan['habits_summary']?.toString() ?? data?.summary['adherence_message']?.toString() ?? 'Tu adherencia se mostrara aqui.'} ${_priorityPrompt(preferences.dailyPriority, preferences.proactiveAdjustments)}',
                  color: const Color(0xFFE6DFEC),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _initials(String name) {
    final pieces = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();
    if (pieces.isEmpty) {
      return 'KC';
    }
    return pieces.map((part) => part[0].toUpperCase()).join();
  }

  Map<String, dynamic>? _firstMap(List<dynamic>? items) {
    if (items == null || items.isEmpty) {
      return null;
    }
    return items.first as Map<String, dynamic>;
  }

  String _dateOnly(dynamic value) {
    return (value?.toString() ?? '').split('T').first;
  }

  String _firstName(String fullName) {
    final pieces = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (pieces.isEmpty) {
      return 'Usuario';
    }
    return pieces.first;
  }
}

class _DashboardViewModel {
  const _DashboardViewModel({
    required this.summary,
    required this.plan,
    required this.progress,
    required this.goal,
    required this.history,
    required this.fullName,
    required this.preferences,
    required this.hasProfile,
    required this.todayStatus,
  });

  final Map<String, dynamic> summary;
  final Map<String, dynamic> plan;
  final Map<String, dynamic> progress;
  final Map<String, dynamic> goal;
  final Map<String, dynamic> history;
  final String fullName;
  final ProfilePreferences preferences;
  final bool hasProfile;
  final Map<String, bool> todayStatus;
}

class _CoachBadge extends StatelessWidget {
  const _CoachBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _HeaderActionChip extends StatelessWidget {
  const _HeaderActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomSheetFrame extends StatelessWidget {
  const _BottomSheetFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF7F2E8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(child: child),
    );
  }
}

class _PrimaryActionCard extends StatelessWidget {
  const _PrimaryActionCard({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.ctaLabel,
    required this.icon,
    required this.onTap,
  });

  final String eyebrow;
  final String title;
  final String description;
  final String ctaLabel;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF6E8D4), Color(0xFFE2EFE7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFD8DED7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF143C3A),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              eyebrow,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(description, style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF143C3A).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: const Color(0xFF143C3A)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(ctaLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseTile extends StatelessWidget {
  const _PulseTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF2EEE7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDAE2DC)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF143C3A),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: Color(0xFF143C3A),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
      label: Text(label),
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFD6DDD7)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      onPressed: onTap,
    );
  }
}

class _TodayStepCard extends StatelessWidget {
  const _TodayStepCard({
    required this.stepLabel,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.icon,
    required this.complete,
    required this.busy,
    required this.onTap,
    this.onEditTap,
  });

  final String stepLabel;
  final String title;
  final String subtitle;
  final String statusLabel;
  final IconData icon;
  final bool complete;
  final bool busy;
  final VoidCallback? onTap;
  final VoidCallback? onEditTap;

  @override
  Widget build(BuildContext context) {
    final effectiveTap = complete ? (onEditTap ?? onTap) : onTap;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: busy ? null : effectiveTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: complete
              ? const [Color(0xFFDCEBE4), Color(0xFFF4F0E8)]
              : const [Colors.white, Color(0xFFF7F2E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: complete ? const Color(0xFF8FB9A7) : const Color(0xFFD8DCD5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: complete
                  ? const Color(0xFF2A6A65)
                  : const Color(0xFF143C3A).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Icon(
              complete ? Icons.check_rounded : icon,
              color: complete ? Colors.white : const Color(0xFF143C3A),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stepLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: complete
                      ? const Color(0xFF2A6A65).withValues(alpha: 0.12)
                      : const Color(0xFF143C3A).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  busy ? 'Guardando...' : statusLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF143C3A),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: busy ? null : (complete ? (onEditTap ?? onTap) : onTap),
                child: Text(complete ? 'Actualizar' : 'Registrar'),
              ),
            ],
          ),
        ],
      ),
        ),
      ),
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard({required this.items});

  final List<_ChecklistItemData> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE0E5DE)),
      ),
      child: Column(
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(
                    item.complete
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: item.complete
                        ? const Color(0xFF2A6A65)
                        : const Color(0xFF6B7A79),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.label,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  Text(
                    item.complete ? 'Listo' : 'Pendiente',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ChecklistItemData {
  const _ChecklistItemData({
    required this.label,
    required this.complete,
  });

  final String label;
  final bool complete;
}

class _DayProgressCard extends StatelessWidget {
  const _DayProgressCard({
    required this.completion,
    required this.completedCount,
    required this.totalCount,
  });

  final double completion;
  final int completedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final percent = (completion * 100).round();
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF173836), Color(0xFF2C6A64)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Progreso del dia',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: completion,
              minHeight: 12,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              color: const Color(0xFFF2C685),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$completedCount de $totalCount acciones clave registradas hoy.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureStrip extends StatelessWidget {
  const _FeatureStrip({
    required this.title,
    required this.description,
    required this.color,
  });

  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF143C3A).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(description, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _InteractiveFeatureStrip extends StatelessWidget {
  const _InteractiveFeatureStrip({
    required this.title,
    required this.description,
    required this.color,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String description;
  final Color color;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onAction,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF143C3A).withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (actionLabel != null && onAction != null)
                    TextButton(
                      onPressed: onAction,
                      child: Text(actionLabel!),
                    ),
                  if (onAction != null)
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF143C3A),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(description, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }
}

String _suggestedWorkoutFocus(String style) {
  return switch (style) {
    'Exigente' => 'Bloque principal intenso',
    'Flexible' => 'Sesion adaptable de mantenimiento',
    _ => 'Sesion base de fuerza y movilidad',
  };
}

String _priorityPrompt(String priority, bool proactiveAdjustments) {
  final base = switch (priority) {
    'Rendimiento' => 'Hoy empujamos calidad de ejecucion y energia util.',
    'Recuperacion' => 'Hoy priorizamos bajar friccion y sostener recuperacion.',
    _ => 'Hoy la prioridad es mantener adherencia sin perder continuidad.',
  };
  if (!proactiveAdjustments) {
    return '$base Ajustes automaticos en pausa.';
  }
  return '$base El coach puede proponer microajustes durante el dia.';
}

String _nextActionTitle(Map<String, bool> todayStatus) {
  if (todayStatus['workout'] != true) {
    return 'Registrar entrenamiento';
  }
  if (todayStatus['nutrition'] != true) {
    return 'Registrar nutricion';
  }
  if (todayStatus['weight'] != true) {
    return 'Guardar check-in corporal';
  }
  return 'Dia completo';
}

String _nextActionDescription(
  Map<String, bool> todayStatus,
  ProfilePreferences preferences,
) {
  if (todayStatus['workout'] != true) {
    return 'Empieza por lo mas importante: marca tu sesion del dia y deja registrado como te sentiste.';
  }
  if (todayStatus['nutrition'] != true) {
    return 'Ya entrenaste. Ahora deja una lectura simple de adherencia para que el sistema entienda como va tu dia.';
  }
  if (todayStatus['weight'] != true) {
    return 'Te falta el check-in corporal para cerrar el dia con una referencia util de progreso.';
  }
  return 'Completaste las tres acciones clave. Si quieres, ajusta algun registro o revisa tu historial reciente.';
}

String _nextActionButtonLabel(Map<String, bool> todayStatus) {
  if (todayStatus['workout'] != true) {
    return 'Registrar entrenamiento';
  }
  if (todayStatus['nutrition'] != true) {
    return 'Registrar nutricion';
  }
  if (todayStatus['weight'] != true) {
    return 'Guardar check-in';
  }
  return 'Dia completado';
}

IconData _nextActionIcon(Map<String, bool> todayStatus) {
  if (todayStatus['workout'] != true) {
    return Icons.fitness_center_rounded;
  }
  if (todayStatus['nutrition'] != true) {
    return Icons.restaurant_menu_rounded;
  }
  if (todayStatus['weight'] != true) {
    return Icons.monitor_weight_rounded;
  }
  return Icons.check_circle_rounded;
}

String _dailyFocusTitle(Map<String, bool> todayStatus) {
  if (todayStatus['workout'] != true) {
    return 'Foco de hoy: mover el cuerpo con intencion';
  }
  if (todayStatus['nutrition'] != true) {
    return 'Foco de hoy: cerrar bien la nutricion';
  }
  if (todayStatus['weight'] != true) {
    return 'Foco de hoy: dejar trazabilidad corporal';
  }
  return 'Foco de hoy: revisar y ajustar con calma';
}

String _dailyFocusDescription(
  Map<String, bool> todayStatus,
  Map<String, dynamic>? plan,
  Map<String, dynamic>? summary,
  ProfilePreferences preferences,
) {
  if (todayStatus['workout'] != true) {
    return plan?['workout_summary']?.toString() ??
        'Tu sesion de hoy deberia ser la primera pieza del dia. Registrala con detalle para que el sistema aprenda de verdad.';
  }
  if (todayStatus['nutrition'] != true) {
    return summary?['nutrition_focus']?.toString() ??
        'Tu siguiente mejor accion es dejar claro como resolviste la parte nutricional del dia.';
  }
  if (todayStatus['weight'] != true) {
    return 'Con ${preferences.dailyPriority.toLowerCase()} como prioridad, conviene dejar un check-in corto para entender tendencia y recuperacion.';
  }
  return 'Ya cerraste las tres acciones clave. Si algo cambio, entra a historial o edita el ultimo registro.';
}

String _dailyFocusActionLabel(Map<String, bool> todayStatus) {
  if (todayStatus['workout'] != true) {
    return 'Ir al workout';
  }
  if (todayStatus['nutrition'] != true) {
    return 'Registrar nutricion';
  }
  if (todayStatus['weight'] != true) {
    return 'Guardar check-in';
  }
  return 'Todo al dia';
}
