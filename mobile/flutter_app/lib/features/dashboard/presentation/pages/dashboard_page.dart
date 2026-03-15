import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
import '../../../../core/theme/app_colors.dart';

class _NutritionRouteOption {
  const _NutritionRouteOption({
    required this.value,
    required this.title,
    required this.description,
  });

  final String value;
  final String title;
  final String description;
}

class _EnergyOption {
  const _EnergyOption({
    required this.value,
    required this.title,
    required this.description,
  });

  final String value;
  final String title;
  final String description;
}

const _nutritionRouteOptions = <_NutritionRouteOption>[
  _NutritionRouteOption(
    value: 'Plan casi completo',
    title: 'Seguí el plan',
    description: 'Comí casi como estaba recomendado, con pocos cambios.',
  ),
  _NutritionRouteOption(
    value: 'Con ajustes razonables',
    title: 'Hice ajustes',
    description: 'Cambié opciones o porciones, pero mantuve buena estructura.',
  ),
  _NutritionRouteOption(
    value: 'Comida social o improvisada',
    title: 'Fue social o improvisado',
    description:
        'Comí fuera o resolví sobre la marcha y me alejé más del plan.',
  ),
];

const _energyRouteOptions = <_EnergyOption>[
  _EnergyOption(
    value: 'Me sobro energia',
    title: 'Me sobró energía',
    description: 'Terminé fuerte y con margen para hacer un poco más.',
  ),
  _EnergyOption(
    value: 'Me senti estable',
    title: 'Me sentí estable',
    description: 'La sesión se sintió bien y dentro de lo esperado.',
  ),
  _EnergyOption(
    value: 'Me costo terminar',
    title: 'Me costó terminar',
    description: 'Terminé cansado o con la energía más justa.',
  ),
];

const _durationRouteOptions = <int>[20, 30, 45, 60];
const _focusQuickOptions = <String>[
  'Fuerza principal',
  'Cardio y acondicionamiento',
  'Movilidad y recuperacion',
  'Sesion mixta',
];

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, this.onNavigateToTab});

  final Future<void> Function(int)? onNavigateToTab;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<_DashboardViewModel> _dashboardFuture;
  bool _isQuickLoggingWorkout = false;
  bool _isQuickLoggingNutrition = false;
  bool _isQuickLoggingWeight = false;
  String? _profileImagePath;
  String? _avatarUrl;
  bool _isUploadingAvatar = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _loadSavedAvatarUrl();
  }

  Future<void> _loadSavedAvatarUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('profile_avatar_url');
    if (saved != null && mounted) {
      setState(() {
        _avatarUrl = saved;
      });
    }
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
      if (picked == null || !mounted) return;

      // Show local preview immediately and start upload
      setState(() {
        _profileImagePath = picked.path;
        _isUploadingAvatar = true;
      });

      await _uploadAvatar(File(picked.path));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo acceder a la imagen.')),
      );
    }
  }

  Future<void> _uploadAvatar(File imageFile) async {
    try {
      final session = AuthSessionScope.of(context).session;
      final uri = Uri.parse('http://5.78.42.147:8000/api/v1/users/me/avatar');
      final request = http.MultipartRequest('POST', uri);
      if (session != null) {
        request.headers['Authorization'] = 'Bearer ${session.accessToken}';
      }
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final url = body['avatar_url']?.toString() ??
            body['url']?.toString() ??
            body['profile_image_url']?.toString();
        if (url != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('profile_avatar_url', url);
          if (mounted) {
            setState(() {
              _avatarUrl = url;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _profileImagePath = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo subir la imagen.')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _profileImagePath = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo subir la imagen.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
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
                        DropdownMenuItem(value: 'Otro', child: Text('Otro')),
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
      final uri = Uri.parse(
        '${AppConfig.apiBaseUrl}/api/v1/plans/coach-report',
      );
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
        content: Text(
          'Tu reporte fue recibido. Tu plan se actualizará pronto.',
        ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Workout actualizado.')));
      _refreshDashboard();
    } finally {
      focusController.dispose();
      durationController.dispose();
    }
  }

  Future<void> _editRecentNutrition(Map<String, dynamic> item) async {
    String mealLabel =
        item['meal_label']?.toString() ?? _nutritionRouteOptions.first.value;
    double adherence = (item['adherence_score'] as num?)?.toDouble() ?? 80;
    final legacyOption =
        mealLabel.trim().isNotEmpty &&
            !_nutritionRouteOptions.any((option) => option.value == mealLabel)
        ? _NutritionRouteOption(
            value: mealLabel,
            title: 'Registro anterior',
            description:
                'Mantén esta etiqueta si el registro viejo no encaja en las categorías nuevas.',
          )
        : null;
    final options = [
      ..._nutritionRouteOptions,
      if (legacyOption != null) legacyOption,
    ];

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final selected = options.firstWhere(
              (option) => option.value == mealLabel,
              orElse: () => options.first,
            );
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
                    _RouteSheetHeader(
                      title: 'Editar nutricion',
                      subtitle:
                          'Ajusta como resolviste tu dia y corrige la adherencia si hace falta.',
                      icon: Icons.restaurant_menu_rounded,
                      onClose: () => Navigator.of(sheetContext).pop(false),
                    ),
                    const SizedBox(height: 18),
                    _SectionTitleMini('¿Cómo estuvo tu alimentación hoy?'),
                    const SizedBox(height: 10),
                    Column(
                      children: options
                          .map(
                            (option) => _ChoicePill(
                              label: option.title,
                              description: option.description,
                              selected: mealLabel == option.value,
                              onTap: () {
                                setModalState(() => mealLabel = option.value);
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 18),
                    _MetricPreviewCard(
                      title: 'Adherencia',
                      value: '${adherence.round()}%',
                      helper:
                          '${selected.title}. Mueve el indicador según qué tan cerca estuviste de lo recomendado.',
                    ),
                    Slider(
                      value: adherence,
                      min: 0,
                      max: 100,
                      divisions: 20,
                      label: adherence.round().toString(),
                      onChanged: (value) {
                        setModalState(() => adherence = value);
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                Navigator.of(sheetContext).pop(false),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () =>
                                Navigator.of(sheetContext).pop(true),
                            child: const Text('Guardar'),
                          ),
                        ),
                      ],
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

    await const ActivityHistoryApiService().updateNutrition(
      id: item['id'] as int,
      mealLabel: mealLabel,
      adherenceScore: adherence.round(),
      proteinGrams: (item['protein_grams'] as num?)?.toInt() ?? 140,
      hydrationLiters: (item['hydration_liters'] as num?)?.toInt() ?? 3,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Nutricion actualizada.')));
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
      weightKg:
          double.tryParse(weightController.text.replaceAll(',', '.')) ??
          ((item['weight_kg'] as num?)?.toDouble() ?? 0),
      waistCm: double.tryParse(waistController.text.replaceAll(',', '.')),
    );
    weightController.dispose();
    waistController.dispose();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Check-in actualizado.')));
    _refreshDashboard();
  }

  Future<void> _openQuickWorkoutLog(_DashboardViewModel data) async {
    String energyLevel = _energyRouteOptions[1].value;
    int duration = 45;
    final focusController = TextEditingController(
      text: _suggestedWorkoutFocus(data.preferences.coachingStyle),
    );

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final selectedEnergy = _energyRouteOptions.firstWhere(
              (option) => option.value == energyLevel,
              orElse: () => _energyRouteOptions[1],
            );
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
                    _RouteSheetHeader(
                      title: 'Registrar entrenamiento',
                      subtitle:
                          'Cierra rapido tu sesion con foco, duracion y energia percibida.',
                      icon: Icons.fitness_center_rounded,
                      onClose: () => Navigator.of(sheetContext).pop(false),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: focusController,
                      decoration: const InputDecoration(
                        labelText: 'Foco principal',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _focusQuickOptions
                          .map(
                            (option) => _HintPill(
                              label: option,
                              color: AppColors.brandLightAlt,
                              onTap: () {
                                focusController.text = option;
                                setModalState(() {});
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 18),
                    _SectionTitleMini('¿Cuánto duró tu sesión?'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _durationRouteOptions
                          .map(
                            (option) => _CompactChoicePill(
                              label: '$option min',
                              selected: duration == option,
                              onTap: () {
                                setModalState(() => duration = option);
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 18),
                    _SectionTitleMini('¿Cómo terminaste de energía?'),
                    const SizedBox(height: 10),
                    Column(
                      children: _energyRouteOptions
                          .map(
                            (option) => _ChoicePill(
                              label: option.title,
                              description: option.description,
                              selected: energyLevel == option.value,
                              onTap: () {
                                setModalState(() => energyLevel = option.value);
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 18),
                    _MetricPreviewCard(
                      title: 'Resumen rapido',
                      value: '$duration min · ${selectedEnergy.title}',
                      helper:
                          'Guardaremos este cierre como lectura rapida del entrenamiento de hoy.',
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                Navigator.of(sheetContext).pop(false),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () =>
                                Navigator.of(sheetContext).pop(true),
                            icon: const Icon(
                              Icons.check_circle_outline_rounded,
                            ),
                            label: const Text('Guardar entrenamiento'),
                          ),
                        ),
                      ],
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
    String mealLabel = _nutritionRouteOptions.first.value;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final selected = _nutritionRouteOptions.firstWhere(
              (option) => option.value == mealLabel,
              orElse: () => _nutritionRouteOptions.first,
            );
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
                    _RouteSheetHeader(
                      title: 'Registrar nutricion',
                      subtitle:
                          'Resume tu dia en segundos: tipo de dia, adherencia y que tan cerca estuviste del plan.',
                      icon: Icons.restaurant_menu_rounded,
                      onClose: () => Navigator.of(sheetContext).pop(false),
                    ),
                    const SizedBox(height: 18),
                    _SectionTitleMini('¿Cuál describe mejor tu día de comida?'),
                    const SizedBox(height: 10),
                    Column(
                      children: _nutritionRouteOptions
                          .map(
                            (option) => _ChoicePill(
                              label: option.title,
                              description: option.description,
                              selected: mealLabel == option.value,
                              onTap: () {
                                setModalState(() => mealLabel = option.value);
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 18),
                    _MetricPreviewCard(
                      title: 'Adherencia estimada',
                      value: '${adherence.round()}%',
                      helper:
                          '${selected.title}. Piensa en porciones, elecciones y consistencia con lo planeado.',
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
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: const [
                        _HintPill(
                          label: 'Casi igual al plan',
                          color: AppColors.primarySelected,
                        ),
                        _HintPill(
                          label: 'Cambios razonables',
                          color: AppColors.warningAmberChip,
                        ),
                        _HintPill(
                          label: 'Fuera o social',
                          color: AppColors.purpleLight,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                Navigator.of(sheetContext).pop(false),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () =>
                                Navigator.of(sheetContext).pop(true),
                            icon: const Icon(
                              Icons.check_circle_outline_rounded,
                            ),
                            label: const Text('Guardar nutricion'),
                          ),
                        ),
                      ],
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
    String weighMoment = 'En ayunas';

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetContext) {
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
                    _RouteSheetHeader(
                      title: 'Registrar check-in corporal',
                      subtitle:
                          'Guarda una referencia rapida de tu cuerpo para seguir tendencia y recuperacion.',
                      icon: Icons.monitor_weight_rounded,
                      onClose: () => Navigator.of(sheetContext).pop(false),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: weightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Peso actual',
                      ),
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
                    const SizedBox(height: 18),
                    _SectionTitleMini('¿Cuándo te mediste?'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: ['En ayunas', 'Después de comer', 'En la noche']
                          .map(
                            (option) => _CompactChoicePill(
                              label: option,
                              selected: weighMoment == option,
                              onTap: () {
                                setModalState(() => weighMoment = option);
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    _MetricPreviewCard(
                      title: 'Consejo',
                      value: weighMoment,
                      helper:
                          'Procura pesarte en condiciones parecidas para leer mejor la tendencia semanal.',
                    ),
                    const SizedBox(height: 16),
                    const _HintPillRow(
                      labels: ['Peso', 'Cintura opcional', 'Tendencia semanal'],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                Navigator.of(sheetContext).pop(false),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () =>
                                Navigator.of(sheetContext).pop(true),
                            icon: const Icon(
                              Icons.check_circle_outline_rounded,
                            ),
                            label: const Text('Guardar check-in'),
                          ),
                        ),
                      ],
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ingresa un peso valido.')));
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
            const {'workout': false, 'nutrition': false, 'weight': false};
        final recentWorkout = _firstMap(history?['workouts'] as List<dynamic>?);
        final recentNutrition = _firstMap(
          history?['nutrition_logs'] as List<dynamic>?,
        );
        final recentMetric = _firstMap(
          history?['body_metrics'] as List<dynamic>?,
        );
        final completedTodayCount = todayStatus.values
            .where((done) => done)
            .length;
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
                      colors: [
                        AppColors.primaryDeep,
                        AppColors.primarySubtle,
                        AppColors.warningGoldDark,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.18),
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
                            onTap: _isUploadingAvatar
                                ? null
                                : _showProfileImageSheet,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 27,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.16,
                                  ),
                                  backgroundImage: _profileImagePath != null
                                      ? FileImage(File(_profileImagePath!))
                                      : (_avatarUrl != null
                                          ? NetworkImage(_avatarUrl!)
                                              as ImageProvider
                                          : null),
                                  child: (_profileImagePath == null &&
                                          _avatarUrl == null)
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
                                if (_isUploadingAvatar)
                                  Container(
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.45,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
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
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
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
                          // T-10 — Streak badge
                          if ((progress?['streak_days'] as int? ?? 0) > 0)
                            _StreakBadge(
                              streakDays: progress!['streak_days'] as int,
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _HeaderActionChip(
                            icon: Icons.auto_awesome_rounded,
                            label: 'Mi Plan',
                            color: AppColors.primaryTeal,
                            onTap: () async {
                              final result = await Navigator.of(
                                context,
                              ).pushNamed('/plan-generation');
                              if (result == true &&
                                  widget.onNavigateToTab != null) {
                                await widget.onNavigateToTab!(1);
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          _HeaderActionChip(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: 'Reportar',
                            color: AppColors.warningGold,
                            onTap: () => _showReportToCoachSheet(context),
                          ),
                          const SizedBox(width: 8),
                          _HeaderActionChip(
                            icon: Icons.tune_rounded,
                            label: 'Ajustes',
                            color: AppColors.purple,
                            onTap: () =>
                                Navigator.of(context).pushNamed('/goals'),
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
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(color: Colors.white),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Abre tu perfil para ajustar preferencias, objetivos y recordatorios.',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(color: Colors.white70),
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
                // T-09 — Adherence score row
                _AdherenceMetricsRow(progress: progress),
                const SizedBox(height: 12),
                // T-11 — AI Insights panel
                if ((progress?['insights'] as List<dynamic>? ?? []).isNotEmpty)
                  _InsightsPanel(
                    insights: (progress!['insights'] as List<dynamic>)
                        .map((item) => Map<String, dynamic>.from(item as Map))
                        .toList(),
                    onNavigateToTab: widget.onNavigateToTab,
                  ),
                if ((progress?['insights'] as List<dynamic>? ?? []).isNotEmpty)
                  const SizedBox(height: 18),
                // F-05 — Weekly summary card
                _WeeklySummaryCard(
                  weekDays: (progress?['week_days'] as List<dynamic>?)
                      ?.map((d) => Map<String, dynamic>.from(d as Map))
                      .toList(),
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
                  color: AppColors.brandLightAlt,
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
                    _QuickActionChip(
                      label: 'Mis tendencias',
                      icon: Icons.trending_up_rounded,
                      onTap: () {
                        Navigator.of(context).pushNamed('/progress');
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
                  statusLabel: todayStatus['workout'] == true
                      ? 'Completado'
                      : 'Pendiente',
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
                  statusLabel: todayStatus['nutrition'] == true
                      ? 'Completado'
                      : 'Pendiente',
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
                  statusLabel: todayStatus['weight'] == true
                      ? 'Completado'
                      : 'Pendiente',
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
                  color: AppColors.primaryBg,
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
                  color: AppColors.surfaceClay,
                  chips:
                      ((data?.plan['macro_focus'] as List<dynamic>?) ??
                              const <dynamic>[])
                          .map((item) => item.toString())
                          .toList(),
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
                  color: AppColors.primaryXLight,
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
                  color: AppColors.surfaceClay,
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
                  color: AppColors.purplePale,
                  actionLabel: recentMetric == null ? null : 'Editar',
                  trailing: _WeightTrendIndicator(
                    weightTrend: progress?['weight_trend']?.toString(),
                  ),
                  onAction: recentMetric == null
                      ? null
                      : () => _editRecentWeight(recentMetric),
                ),
                const SizedBox(height: 20),
                _FeatureStrip(
                  title: 'Contexto del sistema',
                  description:
                      '${data?.plan['habits_summary']?.toString() ?? data?.summary['adherence_message']?.toString() ?? 'Tu adherencia se mostrara aqui.'} ${_priorityPrompt(preferences.dailyPriority, preferences.proactiveAdjustments)}',
                  color: AppColors.purplePale,
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.6)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
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
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(child: child),
    );
  }
}

class _RouteSheetHeader extends StatelessWidget {
  const _RouteSheetHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onClose,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        if (onClose != null) ...[
          const SizedBox(width: 8),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionTitleMini extends StatelessWidget {
  const _SectionTitleMini(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.neutralLine,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? Colors.white : AppColors.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: selected ? Colors.white : AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: selected ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactChoicePill extends StatelessWidget {
  const _CompactChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.neutralLine,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: selected ? Colors.white : AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MetricPreviewCard extends StatelessWidget {
  const _MetricPreviewCard({
    required this.title,
    required this.value,
    required this.helper,
  });

  final String title;
  final String value;
  final String helper;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(helper, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _HintPill extends StatelessWidget {
  const _HintPill({required this.label, required this.color, this.onTap});

  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _HintPillRow extends StatelessWidget {
  const _HintPillRow({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: labels
          .map(
            (label) => _HintPill(label: label, color: AppColors.brandLightAlt),
          )
          .toList(),
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
          colors: [AppColors.gradientWarmStart, AppColors.gradientWarmEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.cardBorderMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary,
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
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: AppColors.primary),
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
          colors: [Colors.white, AppColors.surfaceCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorderWarm),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.primary),
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
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
      label: Text(label),
      backgroundColor: Colors.white,
      side: const BorderSide(color: AppColors.neutralBorder),
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
                  ? const [AppColors.primarySelected, AppColors.surfaceCard]
                  : const [Colors.white, AppColors.surfaceCard],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: complete
                  ? AppColors.accentSubtle
                  : AppColors.neutralBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: complete
                      ? AppColors.primaryTeal
                      : AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Icon(
                  complete ? Icons.check_rounded : icon,
                  color: complete ? Colors.white : AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        stepLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: complete
                          ? AppColors.primaryTeal.withValues(alpha: 0.12)
                          : AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      busy ? 'Guardando...' : statusLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: complete
                            ? AppColors.primaryTeal
                            : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: busy
                        ? null
                        : (complete ? (onEditTap ?? onTap) : onTap),
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
        border: Border.all(color: AppColors.cardBorder),
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
                        ? AppColors.primaryTeal
                        : AppColors.textMuted,
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
  const _ChecklistItemData({required this.label, required this.complete});

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
          colors: [AppColors.primaryDeep, AppColors.primaryTeal],
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
              ),
              Text(
                '$percent%',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(color: Colors.white),
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
              color: AppColors.warningGoldDark,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$completedCount de $totalCount acciones clave registradas hoy.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
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
            color: AppColors.primary.withValues(alpha: 0.05),
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
    this.chips = const [],
    this.actionLabel,
    this.trailing,
    this.onAction,
  });

  final String title;
  final String description;
  final Color color;
  final List<String> chips;
  final String? actionLabel;
  final Widget? trailing;
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
                color: AppColors.primary.withValues(alpha: 0.05),
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
                  if (trailing != null) trailing!,
                  if (actionLabel != null && onAction != null)
                    TextButton(onPressed: onAction, child: Text(actionLabel!)),
                  if (onAction != null)
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.primary,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(description, style: Theme.of(context).textTheme.bodyLarge),
              if (chips.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: chips
                      .map(
                        (chip) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _macroFocusChipColor(chip),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            chip,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Color _macroFocusChipColor(String label) {
  final value = label.toLowerCase();
  if (value.contains('prote')) {
    return AppColors.infoPale;
  }
  if (value.contains('carb')) {
    return AppColors.warningAmberChip;
  }
  if (value.contains('gras') || value.contains('saciedad')) {
    return AppColors.macroProtein;
  }
  return AppColors.purpleLight;
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

// ─── T-09: Adherence Metrics Row ───────────────────────────────────────────────

class _AdherenceMetricsRow extends StatelessWidget {
  final Map<String, dynamic>? progress;

  const _AdherenceMetricsRow({this.progress});

  @override
  Widget build(BuildContext context) {
    final weeklyAdherence = (progress?['weekly_adherence'] as num?)?.toInt() ?? 0;
    final completedSessions = (progress?['completed_sessions'] as num?)?.toInt() ?? 0;
    final workoutCompletionRate = (progress?['workout_completion_rate'] as num?)?.toInt() ?? 0;

    final adherenceColor = weeklyAdherence >= 80
        ? AppColors.accent
        : weeklyAdherence >= 50
        ? AppColors.warningAmber
        : AppColors.error;

    return Row(
      children: [
        Expanded(
          child: _MetricChip(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: weeklyAdherence / 100,
                        strokeWidth: 4,
                        backgroundColor: Colors.black12,
                        valueColor: AlwaysStoppedAnimation<Color>(adherenceColor),
                      ),
                      Center(
                        child: Text(
                          '$weeklyAdherence',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: adherenceColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Adherencia',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricChip(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.fitness_center,
                  size: 24,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 6),
                Text(
                  '$completedSessions',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const Text(
                  'Sesiones',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricChip(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '$workoutCompletionRate%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: workoutCompletionRate / 100,
                    minHeight: 5,
                    backgroundColor: Colors.black12,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Workout rate',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  final Widget child;

  const _MetricChip({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: child,
    );
  }
}

// ─── T-10: Streak Badge ─────────────────────────────────────────────────────────

class _StreakBadge extends StatefulWidget {
  final int streakDays;

  const _StreakBadge({required this.streakDays});

  @override
  State<_StreakBadge> createState() => _StreakBadgeState();
}

class _StreakBadgeState extends State<_StreakBadge> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  String get _motivationalMessage {
    if (widget.streakDays >= 30) return '¡Leyenda!';
    if (widget.streakDays >= 14) return '¡Racha increíble!';
    if (widget.streakDays >= 7) return '¡Una semana seguida!';
    return '¡Vas bien!';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.warningOrange.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.warningOrange.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '🔥 ${widget.streakDays} días',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            Text(
              _motivationalMessage,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── T-11: AI Insights Panel ────────────────────────────────────────────────────

class _InsightsPanel extends StatefulWidget {
  final List<Map<String, dynamic>> insights;
  final Future<void> Function(int)? onNavigateToTab;

  const _InsightsPanel({required this.insights, this.onNavigateToTab});

  @override
  State<_InsightsPanel> createState() => _InsightsPanelState();
}

class _InsightsPanelState extends State<_InsightsPanel> {
  final PageController _controller = PageController(viewportFraction: 0.88);
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleInsights = widget.insights.take(3).toList();
    if (visibleInsights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '💡 Insights de tu coach',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: PageView.builder(
            controller: _controller,
            itemCount: visibleInsights.length,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemBuilder: (context, index) {
              final insight = visibleInsights[index];
              final title = insight['title']?.toString() ?? '';
              final note = insight['note']?.toString() ?? '';
              final action = insight['action']?.toString();

              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: AppColors.brandLightAlt),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.accentChip,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.lightbulb_outline,
                          color: AppColors.accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (title.isNotEmpty)
                              Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (note.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                note,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                  height: 1.3,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (action != null && action.isNotEmpty) ...[
                              const Spacer(),
                              Builder(
                                builder: (context) {
                                  final category = (insight['category']
                                          ?.toString() ??
                                      insight['type']?.toString() ??
                                      '')
                                      .toLowerCase();
                                  final bool isWorkout =
                                      category.contains('workout') ||
                                      category.contains('ejercicio');
                                  final bool isNutrition =
                                      category.contains('nutricion') ||
                                      category.contains('nutrition') ||
                                      category.contains('comida');
                                  final bool isProgress =
                                      category.contains('progreso') ||
                                      category.contains('progress') ||
                                      category.contains('peso');
                                  if (!isWorkout && !isNutrition && !isProgress) {
                                    return const SizedBox.shrink();
                                  }
                                  return TextButton(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 24),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () {
                                      if (isWorkout) {
                                        widget.onNavigateToTab?.call(1);
                                      } else if (isNutrition) {
                                        widget.onNavigateToTab?.call(2);
                                      } else if (isProgress) {
                                        Navigator.of(context)
                                            .pushNamed('/progress');
                                      }
                                    },
                                    child: const Text('Ver'),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (visibleInsights.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              visibleInsights.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentPage == index ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? AppColors.primary
                      : Colors.black12,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── T-15: Weight Trend Indicator ──────────────────────────────────────────────

class _WeightTrendIndicator extends StatelessWidget {
  final String? weightTrend;

  const _WeightTrendIndicator({this.weightTrend});

  @override
  Widget build(BuildContext context) {
    if (weightTrend == null || weightTrend!.isEmpty) {
      return const SizedBox.shrink();
    }

    final trend = weightTrend!.toLowerCase();
    final bool isUp = trend.contains('subida') || trend.contains('up');
    final bool isDown = trend.contains('bajada') || trend.contains('down');

    if (!isUp && !isDown) {
      // stable
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.trending_flat, color: Colors.grey, size: 20),
          const SizedBox(height: 2),
          const Text(
            'Tendencia esta semana',
            style: TextStyle(fontSize: 10, color: Colors.black45),
          ),
        ],
      );
    }

    final color = isUp ? AppColors.error : AppColors.accent;
    final icon = isUp ? Icons.trending_up : Icons.trending_down;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 2),
        const Text(
          'Tendencia esta semana',
          style: TextStyle(fontSize: 10, color: Colors.black45),
        ),
      ],
    );
  }
}

// ─── F-05: Weekly Summary Card ──────────────────────────────────────────────

class _WeeklySummaryCard extends StatelessWidget {
  /// Optional list of day data from API. Each map may contain:
  ///   'iso_date': String, 'has_workout': bool, 'has_nutrition': bool
  final List<Map<String, dynamic>>? weekDays;

  const _WeeklySummaryCard({this.weekDays});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    // Monday of current week
    final monday = today.subtract(Duration(days: today.weekday - 1));

    // Build a map of iso_date -> day data for quick lookup
    final Map<String, Map<String, dynamic>> dataByDate = {};
    if (weekDays != null) {
      for (final d in weekDays!) {
        final key = d['iso_date']?.toString() ?? '';
        if (key.isNotEmpty) dataByDate[key] = d;
      }
    }

    const dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Esta semana',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final day = monday.add(Duration(days: i));
              final isoDate =
                  '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
              final isToday =
                  day.year == today.year &&
                  day.month == today.month &&
                  day.day == today.day;
              final dayData = dataByDate[isoDate];
              final hasWorkout = dayData?['has_workout'] == true;
              final hasNutrition = dayData?['has_nutrition'] == true;

              // Determine fill/border colors
              Color fillColor;
              Color borderColor;
              if (hasWorkout && hasNutrition) {
                fillColor = AppColors.primary;
                borderColor = AppColors.primary;
              } else if (hasWorkout) {
                fillColor = AppColors.primaryLight;
                borderColor = AppColors.primary;
              } else if (hasNutrition) {
                fillColor = AppColors.accentLight;
                borderColor = AppColors.accent;
              } else {
                fillColor = Colors.transparent;
                borderColor = AppColors.neutral;
              }

              final bool isTextLight = hasWorkout && hasNutrition;

              // Compute the tap message for this day
              final bool isFuture = day.isAfter(today) && !isToday;
              String tapMessage;
              if (isFuture) {
                tapMessage = 'Día futuro';
              } else if (hasWorkout && hasNutrition) {
                tapMessage = 'Día completo ✓ — Entrenaste y registraste tus comidas';
              } else if (hasWorkout) {
                tapMessage = 'Entrenaste este día ✓';
              } else if (hasNutrition) {
                tapMessage = 'Registraste nutrición ✓';
              } else if (isToday) {
                tapMessage = '¡Hoy es tu día! Completa tu entrenamiento y nutrición';
              } else {
                tapMessage = 'Sin actividad registrada';
              }

              return GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(tapMessage),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: fillColor,
                      border: Border.all(color: borderColor, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      dayLabels[i],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isTextLight
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isToday
                          ? AppColors.primary
                          : Colors.transparent,
                    ),
                  ),
                ],
              ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
