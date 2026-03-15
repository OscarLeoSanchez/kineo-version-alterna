import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../activity/data/services/activity_history_api_service.dart';
import '../../../nutrition/data/services/nutrition_api_service.dart';
import '../../../plans/data/services/plan_api_service.dart';
import '../../../plans/presentation/pages/plan_generation_page.dart';
import '../../../profile/data/services/profile_preferences_store.dart';
import '../../../profile/domain/models/profile_preferences.dart';
import '../../../../core/services/session_data_cache.dart';
import '../../../../shared/widgets/app_section_title.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../../shared/widgets/activity_record_detail_sheet.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/loading_button.dart';
import '../../../../shared/widgets/pressable_card.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../../data/services/workout_api_service.dart';
import '../../data/services/workout_block_api_service.dart';
import '../../data/services/workout_log_api_service.dart';
import '../../../../core/router/app_router.dart';
import '../widgets/workout_detail_sheet.dart';
import '../widgets/workout_log_confirmation_sheet.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage>
    with AutomaticKeepAliveClientMixin {
  _WorkoutViewData? _viewData;
  bool _isInitialLoading = true;
  bool _isSubmitting = false;
  int? _selectedDayIndex;
  int? _selectedPlanId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final cache = SessionDataCache.instance;
    if (cache.hasWorkoutBundle) {
      _viewData = _WorkoutViewData(
        summary: _sanitizeWorkoutSummary(cache.workoutSummary!),
        nutritionSummary: cache.nutritionSummary!,
        planHistory: cache.planHistory!,
        history: cache.history!,
        preferences: ProfilePreferences.defaults(),
      );
      _isInitialLoading = false;
      ProfilePreferencesStore().load().then((preferences) {
        if (!mounted || _viewData == null) return;
        setState(() {
          _viewData = _viewData!.copyWith(preferences: preferences);
        });
      });
      _refreshSilently();
    } else {
      _bootstrap();
    }
  }

  Future<void> _bootstrap() async {
    try {
      final data = await _loadWorkout();
      if (!mounted) return;
      setState(() {
        _viewData = data;
        _isInitialLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _refreshSilently() async {
    try {
      final data = await _loadWorkout();
      if (!mounted) return;
      setState(() {
        _viewData = data;
      });
    } catch (_) {
      // keep stale UI when silent refresh fails
    }
  }

  Future<_WorkoutViewData> _loadWorkout() async {
    final results = await Future.wait([
      WorkoutApiService().fetchWorkoutSummary(planId: _selectedPlanId),
      NutritionApiService().fetchNutritionSummary(planId: _selectedPlanId),
      const PlanApiService().fetchPlanHistory(),
      const ActivityHistoryApiService().fetchHistory(),
    ]);
    final summary = _sanitizeWorkoutSummary(results[0] as Map<String, dynamic>);
    final nutritionSummary = results[1] as Map<String, dynamic>;
    final planHistory = results[2] as List<Map<String, dynamic>>;
    final history = results[3] as Map<String, dynamic>;
    SessionDataCache.instance
      ..workoutSummary = summary
      ..nutritionSummary = nutritionSummary
      ..planHistory = planHistory
      ..history = history;
    return _WorkoutViewData(
      summary: summary,
      nutritionSummary: nutritionSummary,
      planHistory: planHistory,
      history: history,
      preferences: await ProfilePreferencesStore().load(),
    );
  }

  Map<String, dynamic> _sanitizeWorkoutSummary(Map<String, dynamic> summary) {
    final copy = Map<String, dynamic>.from(summary);
    copy['weekly_days'] = (copy['weekly_days'] as List<dynamic>? ?? []).map((
      rawDay,
    ) {
      final day = Map<String, dynamic>.from(rawDay as Map);
      day['blocks'] = (day['blocks'] as List<dynamic>? ?? []).map((rawBlock) {
        final block = Map<String, dynamic>.from(rawBlock as Map);
        block['exercises'] = (block['exercises'] as List<dynamic>? ?? const [])
            .map((item) {
              if (item is Map<String, dynamic>) return item;
              if (item is Map) {
                return item.map(
                  (key, value) => MapEntry(key.toString(), value),
                );
              }
              if (item is String) return {'name': item};
              return <String, dynamic>{};
            })
            .where((item) => item.isNotEmpty)
            .toList();
        block['substitutions'] =
            (block['substitutions'] as List<dynamic>? ?? const [])
                .map((item) {
                  if (item is Map<String, dynamic>) return item;
                  if (item is Map) {
                    return item.map(
                      (key, value) => MapEntry(key.toString(), value),
                    );
                  }
                  if (item is String) return {'name': item};
                  return <String, dynamic>{};
                })
                .where((item) => item.isNotEmpty)
                .toList();
        block['selected_exercises'] =
            (block['selected_exercises'] as List<dynamic>? ?? const [])
                .map((item) => item.toString())
                .toList();
        return block;
      }).toList();
      return day;
    }).toList();
    return copy;
  }

  Future<void> _refreshWorkoutPlan() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      PageRouteBuilder<Map<String, dynamic>>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const PlanGenerationPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curve = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(curve),
            child: FadeTransition(opacity: curve, child: child),
          );
        },
      ),
    );

    // Whether the user generated a new plan or cancelled, refresh the data
    await _refreshSilently();

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plan actualizado con la informacion mas reciente.'),
        ),
      );
    }
  }

  Future<void> _registerWorkout(Map<String, dynamic> data) async {
    final blocks = (data['blocks'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final result = await Navigator.of(context).push<_WorkoutRegistrationResult>(
      PageRouteBuilder<_WorkoutRegistrationResult>(
        pageBuilder: (context, animation, secondaryAnimation) {
          return _WorkoutRegistrationPage(
            blocks: blocks,
            initialSessionName:
                data['focus']?.toString() ?? 'Sesion adaptativa',
            initialEnergyLevel: data['energy_level']?.toString() ?? 'Media',
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curve = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(curve),
            child: FadeTransition(opacity: curve, child: child),
          );
        },
      ),
    );

    if (result == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final completedTitles = <String>[];
    for (var i = 0; i < blocks.length; i++) {
      if (result.completedBlocks[i]) {
        completedTitles.add(blocks[i]['title']?.toString() ?? 'Bloque');
      }
    }
    final focusLabel = result.sessionName.isEmpty
        ? (data['focus']?.toString() ?? 'Sesion adaptativa')
        : result.sessionName;
    final notes = [
      if (completedTitles.isNotEmpty)
        'Bloques completados: ${completedTitles.join(', ')}',
      'RPE: ${result.effort.round()}/10',
      'Tecnica: ${result.technique}',
      if (result.note.isNotEmpty) result.note,
    ].join(' | ');

    try {
      final submitResult = await const WorkoutLogApiService().submitWorkout(
        sessionMinutes: data['duration_minutes'] as int? ?? 45,
        focus: focusLabel,
        energyLevel: result.energyLevel,
        dayIsoDate: data['iso_date']?.toString(),
        planId: data['plan_id'] as int?,
        blockStates: List.generate(blocks.length, (index) {
          final block = blocks[index];
          final selectedExercises =
              (block['selected_exercises'] as List<dynamic>? ?? const [])
                  .map((item) => item.toString())
                  .toList();
          return {
            'block_title': block['title']?.toString() ?? 'Bloque',
            'completed': result.completedBlocks[index],
            'selected_exercises': selectedExercises,
          };
        }),
        notes: notes,
      );
      await _refreshSilently();
      if (!mounted) return;
      if (submitResult.queuedOffline) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sin internet: la sesión quedó guardada localmente y se enviará cuando vuelva la conexión.',
            ),
          ),
        );
      } else {
        showWorkoutLogConfirmationSheet(
          context,
          focus: focusLabel,
          energyLevel: result.energyLevel,
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos registrar la sesion.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _openGuidedSession(Map<String, dynamic>? selectedDay) async {
    if (selectedDay == null) return;
    final result = await Navigator.of(context).pushNamed<bool>(
      AppRouter.workoutSession,
      arguments: selectedDay,
    );
    if (result == true) {
      await _refreshSilently();
    }
  }

  Future<void> _editWorkout(Map<String, dynamic> item) async {
    final durationController = TextEditingController(
      text: '${item['session_minutes'] ?? 45}',
    );
    final focusController = TextEditingController(
      text: item['focus']?.toString() ?? '',
    );
    final notesController = TextEditingController(
      text: item['notes']?.toString() ?? '',
    );
    String energyLevel = item['energy_level']?.toString() ?? 'Media';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar sesion'),
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
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Notas'),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Alta', 'Media', 'Baja']
                        .map(
                          (value) => ChoiceChip(
                            label: Text(value),
                            selected: energyLevel == value,
                            selectedColor: AppColors.primaryLight,
                            onSelected: (_) {
                              setModalState(() {
                                energyLevel = value;
                              });
                            },
                          ),
                        )
                        .toList(),
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
      durationController.dispose();
      focusController.dispose();
      notesController.dispose();
      return;
    }

    try {
      await const ActivityHistoryApiService().updateWorkout(
        id: item['id'] as int,
        sessionMinutes: int.tryParse(durationController.text) ?? 45,
        focus: focusController.text,
        energyLevel: energyLevel,
        notes: notesController.text.trim(),
      );
      if (!mounted) return;
      await _refreshSilently();
    } finally {
      durationController.dispose();
      focusController.dispose();
      notesController.dispose();
    }
  }

  Future<void> _deleteWorkout(int id) async {
    await const ActivityHistoryApiService().deleteWorkout(id);
    if (!mounted) return;
    final current = _viewData;
    if (current != null) {
      final updatedHistory = Map<String, dynamic>.from(current.history);
      final workouts = (updatedHistory['workouts'] as List<dynamic>? ?? [])
          .where((entry) {
            return (entry as Map<String, dynamic>)['id'] != id;
          })
          .toList();
      updatedHistory['workouts'] = workouts;
      setState(() {
        _viewData = current.copyWith(history: updatedHistory);
      });
    }
    await _refreshSilently();
  }

  void _updateLocalBlockState({
    required String blockTitle,
    required Map<String, dynamic>? selectedDay,
    bool? completed,
    String? toggledExercise,
  }) {
    final current = _viewData;
    if (current == null || selectedDay == null) {
      return;
    }
    final summary = Map<String, dynamic>.from(current.summary);
    final weeklyDays = (summary['weekly_days'] as List<dynamic>? ?? [])
        .toList();
    final selectedIndex = _resolveSelectedDayIndex(
      weeklyDays,
      summary['selected_day_index'] as int? ?? 0,
    );
    if (selectedIndex >= weeklyDays.length) {
      return;
    }
    final day = Map<String, dynamic>.from(weeklyDays[selectedIndex] as Map);
    final blocks = (day['blocks'] as List<dynamic>? ?? []).map((item) {
      final block = Map<String, dynamic>.from(item as Map);
      if (block['title']?.toString() != blockTitle) {
        return block;
      }
      if (completed != null) {
        block['completed'] = completed;
      }
      if (toggledExercise != null) {
        final selectedExercises =
            (block['selected_exercises'] as List<dynamic>? ?? const [])
                .map((item) => item.toString())
                .toSet();
        if (selectedExercises.contains(toggledExercise)) {
          selectedExercises.remove(toggledExercise);
        } else {
          selectedExercises.add(toggledExercise);
        }
        block['selected_exercises'] = selectedExercises.toList();
        final exercises = (block['exercises'] as List<dynamic>? ?? []).map((
          raw,
        ) {
          final exercise = Map<String, dynamic>.from(raw as Map);
          final name = exercise['name']?.toString() ?? '';
          exercise['is_selected'] = selectedExercises.isEmpty
              ? true
              : selectedExercises.contains(name);
          return exercise;
        }).toList();
        block['exercises'] = exercises;
        final substitutions = (block['substitutions'] as List<dynamic>? ?? [])
            .map((raw) {
              final substitution = Map<String, dynamic>.from(raw as Map);
              final name = substitution['name']?.toString() ?? '';
              substitution['is_selected'] = selectedExercises.contains(name);
              return substitution;
            })
            .toList();
        block['substitutions'] = substitutions;
      }
      return block;
    }).toList();
    day['blocks'] = blocks;
    weeklyDays[selectedIndex] = day;
    summary['weekly_days'] = weeklyDays;
    setState(() {
      _viewData = current.copyWith(summary: summary);
    });
  }

  Future<void> _persistBlockState({
    required String blockTitle,
    required Map<String, dynamic>? selectedDay,
  }) async {
    final current = _viewData;
    final targetDay =
        ((current?.summary['weekly_days'] as List<dynamic>? ?? const [])
                .cast<Map<String, dynamic>>())
            .firstWhere(
              (item) =>
                  item['iso_date']?.toString() ==
                  selectedDay?['iso_date']?.toString(),
              orElse: () => selectedDay ?? <String, dynamic>{},
            );
    final block =
        ((targetDay['blocks'] as List<dynamic>? ?? const [])
                .cast<Map<String, dynamic>>())
            .firstWhere(
              (item) => item['title']?.toString() == blockTitle,
              orElse: () => <String, dynamic>{},
            );
    if (block.isEmpty) {
      return;
    }
    try {
      await const WorkoutBlockApiService().saveBlockState(
        dayIsoDate: targetDay['iso_date']?.toString() ?? '',
        planId: targetDay['plan_id'] as int?,
        blockTitle: blockTitle,
        completed: block['completed'] == true,
        selectedExercises:
            (block['selected_exercises'] as List<dynamic>? ?? const [])
                .map((item) => item.toString())
                .toList(),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pudimos guardar el estado del bloque.'),
        ),
      );
    }
  }

  Future<void> _toggleBlockCompletion({
    required String blockTitle,
    required Map<String, dynamic>? selectedDay,
  }) async {
    if (selectedDay == null || selectedDay['is_today'] != true) {
      return;
    }
    final currentBlock =
        ((selectedDay?['blocks'] as List<dynamic>? ?? const [])
                .cast<Map<String, dynamic>>())
            .firstWhere(
              (item) => item['title']?.toString() == blockTitle,
              orElse: () => <String, dynamic>{},
            );
    if (currentBlock['completed'] == true) {
      return;
    }
    final nextCompleted = true;
    _updateLocalBlockState(
      blockTitle: blockTitle,
      selectedDay: selectedDay,
      completed: nextCompleted,
    );
    await _persistBlockState(blockTitle: blockTitle, selectedDay: selectedDay);
  }

  Future<void> _toggleExerciseSelection({
    required String blockTitle,
    required String exerciseName,
    required Map<String, dynamic>? selectedDay,
  }) async {
    if (selectedDay == null || selectedDay['is_today'] != true) {
      return;
    }
    _updateLocalBlockState(
      blockTitle: blockTitle,
      selectedDay: selectedDay,
      toggledExercise: exerciseName,
    );
    await _persistBlockState(blockTitle: blockTitle, selectedDay: selectedDay);
  }

  void _showBlockDetail(
    Map<String, dynamic> item,
    ProfilePreferences preferences,
    int index,
    int totalBlocks,
    Map<String, dynamic>? selectedDay,
  ) {
    showWorkoutDetailSheet(
      context,
      block: item,
      blockIndex: index,
      totalBlocks: totalBlocks,
      onToggleCompleted: () => _toggleBlockCompletion(
        blockTitle: item['title']?.toString() ?? 'Bloque',
        selectedDay: selectedDay,
      ),
      onToggleExercise: (exerciseName) => _toggleExerciseSelection(
        blockTitle: item['title']?.toString() ?? 'Bloque',
        exerciseName: exerciseName,
        selectedDay: selectedDay,
      ),
    );
  }

  int _resolveSelectedDayIndex(List<dynamic> weeklyDays, int fallbackIndex) {
    if (weeklyDays.isEmpty) {
      return 0;
    }
    final safeFallback = fallbackIndex.clamp(0, weeklyDays.length - 1);
    final stored = _selectedDayIndex;
    if (stored != null && stored >= 0 && stored < weeklyDays.length) {
      return stored;
    }
    return safeFallback;
  }

  void _showDayPlanDetail(
    Map<String, dynamic> workoutDay,
    Map<String, dynamic>? nutritionDay,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DayPlanDetailSheet(
        workoutDay: workoutDay,
        nutritionDay: nutritionDay,
      ),
    );
  }

  Future<void> _showWeekPicker(List<Map<String, dynamic>> planHistory) async {
    if (planHistory.isEmpty) {
      return;
    }
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Material(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          color: Theme.of(context).colorScheme.surface,
          child: SafeArea(
            top: false,
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                Text(
                  'Seleccionar semana',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Puedes abrir semanas históricas si existen planes guardados.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ...planHistory.map((item) {
                  final isSelected =
                      item['id'] == _selectedPlanId ||
                      (_selectedPlanId == null && item['is_current'] == true);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: PressableCard(
                      borderRadius: 20,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceAlt,
                      onTap: () => Navigator.of(context).pop(item),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['week_label']?.toString() ?? 'Semana',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: isSelected
                                              ? Colors.white
                                              : null,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['workout_focus']?.toString() ?? '',
                                    style: TextStyle(
                                      color: isSelected ? Colors.white70 : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _selectedPlanId = selected['is_current'] == true
          ? null
          : selected['id'] as int?;
      _selectedDayIndex = null;
    });
    await _refreshSilently();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isInitialLoading) {
      return _buildShimmerLoading();
    }
    final viewData = _viewData;
    if (viewData == null) {
      return _buildErrorView(context);
    }
    final data = viewData?.summary;
    final planHistory = viewData?.planHistory ?? const <Map<String, dynamic>>[];
    final workouts = viewData?.history['workouts'] as List<dynamic>? ?? [];
    final weeklyCalendar = data?['weekly_calendar'] as List<dynamic>? ?? [];
    final weeklyDays = data?['weekly_days'] as List<dynamic>? ?? [];
    final nutritionData = viewData?.nutritionSummary;
    final nutritionWeeklyDays =
        nutritionData?['weekly_days'] as List<dynamic>? ?? [];
    final preferences = viewData?.preferences ?? ProfilePreferences.defaults();
    final selectedDayIndex = _resolveSelectedDayIndex(
      weeklyDays,
      data?['selected_day_index'] as int? ??
          (weeklyDays.isEmpty ? 0 : weeklyDays.length - 1),
    );
    final selectedDay = weeklyDays.isNotEmpty
        ? weeklyDays[selectedDayIndex] as Map<String, dynamic>
        : null;
    final blocks =
        ((selectedDay?['blocks'] ?? data?['blocks']) as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
      children: [
        const AppSectionTitle(
          title: 'Workout',
          subtitle:
              'Entiende la sesion, abre cada bloque y registra lo que si hiciste.',
        ),
        const SizedBox(height: 18),
        _buildHero(context, data, preferences, selectedDay),
        const SizedBox(height: 20),
        _buildRouteCard(context, blocks, preferences, selectedDay),
        const SizedBox(height: 20),
        _buildStats(context, data, preferences),
        const SizedBox(height: 20),
        _buildCalendar(
          context,
          weeklyCalendar,
          selectedDayIndex,
          weeklyDays,
          nutritionWeeklyDays,
          planHistory,
        ),
        const SizedBox(height: 20),
        _buildHistory(context, workouts),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: LoadingButton(
                label: 'Cerrar sesión',
                icon: Icons.check_circle_outline_rounded,
                isLoading: _isSubmitting,
                onPressed:
                    selectedDay == null ||
                        selectedDay['is_today'] != true ||
                        (data?['completed_today'] == true)
                    ? null
                    : () => _registerWorkout(selectedDay),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _refreshWorkoutPlan,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Actualizar plan'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShimmerLoading() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
      children: const [
        ShimmerBox(width: double.infinity, height: 180, borderRadius: 32),
        SizedBox(height: 20),
        ShimmerBox(width: double.infinity, height: 220, borderRadius: 28),
        SizedBox(height: 20),
        ShimmerBox(width: double.infinity, height: 120, borderRadius: 24),
      ],
    );
  }

  Widget _buildErrorView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'No pudimos cargar tu sesion de hoy.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => _bootstrap(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(
    BuildContext context,
    Map<String, dynamic>? data,
    ProfilePreferences preferences,
    Map<String, dynamic>? selectedDay,
  ) {
    final completedToday =
        selectedDay?['goal_hit'] == true || data?['completed_today'] == true;
    final durationMinutes =
        selectedDay?['duration_minutes'] as int? ??
        data?['duration_minutes'] as int? ??
        45;
    final isPast = selectedDay?['is_past'] == true;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryAlt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedDay?['session_title']?.toString() ??
                data?['title']?.toString() ??
                'Sesion del dia',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            selectedDay?['focus']?.toString() ??
                data?['focus']?.toString() ??
                'Foco adaptativo',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroChip(
                label: _formatWorkoutDuration(
                  durationMinutes,
                  preferences.units,
                ),
              ),
              // T-07 — intensity chip with color coding
              if ((selectedDay?['intensity']?.toString() ?? data?['intensity']?.toString() ?? '').isNotEmpty)
                _IntensityChip(
                  intensity: selectedDay?['intensity']?.toString() ??
                      data?['intensity']?.toString() ??
                      '',
                ),
              _HeroChip(
                label: completedToday
                    ? 'Dia con registro'
                    : (isPast ? 'Dia anterior visible' : 'Lista para ejecutar'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            selectedDay?['adaptation_hint']?.toString() ??
                data?['sos_hint']?.toString() ??
                'Si algo falla, reestructura sin abandonar la sesion.',
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(
    BuildContext context,
    List<Map<String, dynamic>> blocks,
    ProfilePreferences preferences,
    Map<String, dynamic>? selectedDay,
  ) {
    // T-05 — parse warmup and cooldown
    final warmup = (selectedDay?['warmup'] as List?)
        ?.map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList() ?? const <String>[];
    final cooldown = (selectedDay?['cooldown'] as List?)
        ?.map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList() ?? const <String>[];

    // T-06 — parse adaptation_hint
    final adaptationHint = selectedDay?['adaptation_hint']?.toString() ?? '';

    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ruta de ${selectedDay?['day_label']?.toString() ?? 'hoy'}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'La sesion del dia seleccionado esta dividida en pasos. Toca cualquier bloque para ver que hacer y como adaptarlo.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: selectedDay == null || selectedDay['is_today'] != true
                  ? null
                  : () => _openGuidedSession(selectedDay),
              icon: const Icon(Icons.timer_outlined),
              label: const Text('Iniciar modo guiado'),
            ),
          ),
          const SizedBox(height: 16),

          // T-06 — Coach adaptation hint card
          if (adaptationHint.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [AppColors.primaryMid, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.psychology_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Coach del día',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    adaptationHint,
                    style: const TextStyle(
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // T-05 — Warmup expandable section
          if (warmup.isNotEmpty) ...[
            Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
              ),
              child: Container(
                decoration: BoxDecoration(
                  border: const Border(
                    left: BorderSide(color: Colors.orange, width: 3),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                  childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  title: const Text(
                    '🔥 Calentamiento',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  initiallyExpanded: false,
                  children: warmup
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 5, right: 8),
                                child: Icon(
                                  Icons.fiber_manual_record,
                                  size: 8,
                                  color: Colors.orange,
                                ),
                              ),
                              Expanded(child: Text(item)),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (blocks.isEmpty)
            EmptyStateWidget(
              icon: Icons.fitness_center_rounded,
              title: 'Sin entrenamiento hoy',
              subtitle: selectedDay?['objective']?.toString() ??
                  'No hay sesión programada. Genera un plan para empezar.',
              actionLabel: 'Crear mi plan',
              onAction: _refreshWorkoutPlan,
              compact: true,
            ),
          ...List.generate(blocks.length, (index) {
            final block = blocks[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == blocks.length - 1 ? 0 : 12,
              ),
              child: PressableCard(
                color: AppColors.surface,
                borderRadius: 24,
                onTap: () => _showBlockDetail(
                  block,
                  preferences,
                  index,
                  blocks.length,
                  selectedDay,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              block['title']?.toString() ?? '',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _shortBlockSupport(
                                block['description']?.toString() ?? '',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: block['completed'] == true
                                        ? AppColors.primaryLight
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    block['completed'] == true
                                        ? 'Bloque realizado'
                                        : 'Pendiente',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                                Text(
                                  'Ver detalle del bloque',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          IconButton.filledTonal(
                            onPressed: () => _toggleBlockCompletion(
                              blockTitle:
                                  block['title']?.toString() ?? 'Bloque',
                              selectedDay: selectedDay,
                            ),
                            icon: Icon(
                              block['completed'] == true
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // T-05 — Cooldown expandable section
          if (cooldown.isNotEmpty) ...[
            const SizedBox(height: 12),
            Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Colors.lightBlue, width: 3),
                  ),
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                  childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  title: const Text(
                    '💧 Vuelta a la calma',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  initiallyExpanded: false,
                  children: cooldown
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 5, right: 8),
                                child: Icon(
                                  Icons.fiber_manual_record,
                                  size: 8,
                                  color: Colors.lightBlue,
                                ),
                              ),
                              Expanded(child: Text(item)),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStats(
    BuildContext context,
    Map<String, dynamic>? data,
    ProfilePreferences preferences,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'Sesiones esta semana',
                value: '${data?['completed_sessions'] ?? 0}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                label: 'Modo coach',
                value: preferences.coachingStyle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppSurfaceCard(
          backgroundColor: AppColors.brandLightAlt,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Si hoy no puedes hacerla completa',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(_advancedWorkoutAlternative(preferences.coachingStyle)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar(
    BuildContext context,
    List<dynamic> weeklyCalendar,
    int selectedDayIndex,
    List<dynamic> weeklyDays,
    List<dynamic> nutritionWeeklyDays,
    List<Map<String, dynamic>> planHistory,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: AppSectionTitle(
                title: 'Calendario semanal',
                subtitle: 'Por defecto se muestra el día actual.',
              ),
            ),
            IconButton(
              tooltip: 'Seleccionar semana',
              onPressed: planHistory.isEmpty
                  ? null
                  : () => _showWeekPicker(planHistory),
              icon: const Icon(Icons.calendar_month_rounded),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: weeklyCalendar.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value as Map<String, dynamic>;
              final goalHit = item['goal_hit'] == true;
              final isSelected = index == selectedDayIndex;
              final isAvailable = item['is_available'] != false;
              return PressableCard(
                onTap: !isAvailable
                    ? null
                    : () {
                        setState(() {
                          _selectedDayIndex = index;
                        });
                        final workoutDay =
                            weeklyDays.isNotEmpty && index < weeklyDays.length
                            ? weeklyDays[index] as Map<String, dynamic>
                            : null;
                        final nutritionDay =
                            nutritionWeeklyDays.isNotEmpty &&
                                index < nutritionWeeklyDays.length
                            ? nutritionWeeklyDays[index] as Map<String, dynamic>
                            : null;
                        if (workoutDay != null) {
                          _showDayPlanDetail(workoutDay, nutritionDay);
                        }
                      },
                borderRadius: 20,
                color: isSelected
                    ? AppColors.primary
                    : (!isAvailable
                          ? AppColors.surfaceClay
                          : (goalHit
                                ? AppColors.primaryLight
                                : AppColors.surfaceAlt)),
                child: Container(
                  width: 94,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 10,
                  ),
                  child: Column(
                    children: [
                      Text(
                        item['label']?.toString() ?? '',
                        style: TextStyle(
                          color: isSelected ? Colors.white : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${item['completed_sessions'] ?? 0}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: isSelected ? Colors.white : null),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['date']?.toString() ?? '',
                        style: TextStyle(
                          color: isSelected ? Colors.white70 : null,
                        ),
                      ),
                      if (!isAvailable) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Aún no',
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildHistory(BuildContext context, List<dynamic> workouts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionTitle(title: 'Historial reciente'),
        const SizedBox(height: 12),
        ...(workouts.isEmpty
            ? [
                const AppSurfaceCard(
                  child: Text('Aun no tienes sesiones registradas.'),
                ),
              ]
            : workouts.take(4).map((entry) {
                final item = entry as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PressableCard(
                    onTap: () => _showWorkoutHistoryDetail(item),
                    borderRadius: 8,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.neutral),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['focus']?.toString() ?? '',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${item['session_minutes']} min · ${item['energy_level']}',
                                ),
                                if ((item['notes']?.toString() ?? '')
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    item['notes']?.toString() ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _editWorkout(item);
                              } else if (value == 'delete') {
                                _deleteWorkout(item['id'] as int);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Editar'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Eliminar'),
                              ),
                            ],
                          ),
                          Text(
                            (item['completed_at']?.toString() ?? '')
                                .split('T')
                                .first,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              })),
      ],
    );
  }

  void _showWorkoutHistoryDetail(Map<String, dynamic> item) {
    final noteText = item['notes']?.toString() ?? '';
    final noteParts = noteText
        .split('|')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    showActivityRecordDetailSheet(
      context,
      title: item['focus']?.toString() ?? 'Sesion',
      subtitle: (item['completed_at']?.toString() ?? '').split('T').first,
      details: [
        MapEntry('Duracion', '${item['session_minutes'] ?? 0} min'),
        MapEntry('Energia final', item['energy_level']?.toString() ?? '-'),
        if (item['day_iso_date'] != null)
          MapEntry('Dia del plan', item['day_iso_date']?.toString() ?? ''),
        ...noteParts
            .take(3)
            .toList()
            .asMap()
            .entries
            .map((entry) => MapEntry('Detalle ${entry.key + 1}', entry.value)),
      ],
      notes: noteParts.length > 3 ? noteParts.skip(3).join('\n') : null,
      radius: 10,
    );
  }
}

class _WorkoutViewData {
  const _WorkoutViewData({
    required this.summary,
    required this.nutritionSummary,
    required this.planHistory,
    required this.history,
    required this.preferences,
  });

  final Map<String, dynamic> summary;
  final Map<String, dynamic> nutritionSummary;
  final List<Map<String, dynamic>> planHistory;
  final Map<String, dynamic> history;
  final ProfilePreferences preferences;

  _WorkoutViewData copyWith({
    Map<String, dynamic>? summary,
    Map<String, dynamic>? nutritionSummary,
    List<Map<String, dynamic>>? planHistory,
    Map<String, dynamic>? history,
    ProfilePreferences? preferences,
  }) {
    return _WorkoutViewData(
      summary: summary ?? this.summary,
      nutritionSummary: nutritionSummary ?? this.nutritionSummary,
      planHistory: planHistory ?? this.planHistory,
      history: history ?? this.history,
      preferences: preferences ?? this.preferences,
    );
  }
}

class _WorkoutRegistrationResult {
  const _WorkoutRegistrationResult({
    required this.sessionName,
    required this.completedBlocks,
    required this.energyLevel,
    required this.effort,
    required this.technique,
    required this.note,
  });

  final String sessionName;
  final List<bool> completedBlocks;
  final String energyLevel;
  final double effort;
  final String technique;
  final String note;
}

class _WorkoutRegistrationPage extends StatefulWidget {
  const _WorkoutRegistrationPage({
    required this.blocks,
    required this.initialSessionName,
    required this.initialEnergyLevel,
  });

  final List<Map<String, dynamic>> blocks;
  final String initialSessionName;
  final String initialEnergyLevel;

  @override
  State<_WorkoutRegistrationPage> createState() =>
      _WorkoutRegistrationPageState();
}

class _WorkoutRegistrationPageState extends State<_WorkoutRegistrationPage> {
  late final TextEditingController _noteController;
  late final List<bool> _completedBlocks;
  late String _energyLevel;
  double _effort = 7;
  String _technique = 'Muy bien';

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    _completedBlocks = widget.blocks
        .map((block) => block['completed'] == true)
        .toList();
    _energyLevel = widget.initialEnergyLevel;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(
      _WorkoutRegistrationResult(
        sessionName: widget.initialSessionName,
        completedBlocks: List<bool>.from(_completedBlocks),
        energyLevel: _energyLevel,
        effort: _effort,
        technique: _technique,
        note: _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Cerrar sesión')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            Text(
              'Marca los bloques que sí completaste. Al final puedes dejar una nota opcional.',
              style: theme.textTheme.bodyLarge,
            ),
            if (widget.blocks.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Bloques completados', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              ...List.generate(widget.blocks.length, (index) {
                final block = widget.blocks[index];
                final isDone = _completedBlocks[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: PressableCard(
                    borderRadius: 20,
                    color: isDone
                        ? AppColors.primaryLight
                        : AppColors.surface,
                    onTap: () {
                      setState(() {
                        _completedBlocks[index] = !_completedBlocks[index];
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            isDone
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: isDone
                                ? AppColors.accent
                                : AppColors.neutralLight,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  block['title']?.toString() ?? 'Bloque',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  block['goal']?.toString() ??
                                      _shortBlockSupport(
                                        block['description']?.toString() ?? '',
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
            const SizedBox(height: 12),
            Text('¿Cómo terminaste?', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Con mucha energía', 'Bien', 'Cansado']
                  .map(
                    (label) => ChoiceChip(
                      label: Text(label),
                      selected: _energyLevel == _mapEnergyLabel(label),
                      selectedColor: AppColors.primaryLight,
                      onSelected: (_) {
                        setState(() {
                          _energyLevel = _mapEnergyLabel(label);
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            Text(
              'Esfuerzo: ${_effort.round()}/10',
              style: theme.textTheme.titleMedium,
            ),
            Slider(
              value: _effort,
              min: 1,
              max: 10,
              divisions: 9,
              label: _effort.round().toString(),
              onChanged: (value) {
                setState(() {
                  _effort = value;
                });
              },
            ),
            const SizedBox(height: 8),
            Text(
              '¿Cómo te sentiste con la ejecución?',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Muy bien', 'Bien', 'Regular']
                  .map(
                    (label) => ChoiceChip(
                      label: Text(label),
                      selected: _technique == label,
                      selectedColor: label == 'Muy bien'
                          ? AppColors.primaryLight
                          : label == 'Bien'
                          ? AppColors.warningLight
                          : AppColors.errorPale,
                      onSelected: (_) {
                        setState(() {
                          _technique = label;
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Nota opcional',
                hintText:
                    'Ejemplo: recorté el final por tiempo o me sentí fuerte en pierna.',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Guardar cierre'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutSheet extends StatelessWidget {
  const _WorkoutSheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.82;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.fromLTRB(16, 24, 16, 16 + bottomInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _DayPlanDetailSheet extends StatelessWidget {
  const _DayPlanDetailSheet({
    required this.workoutDay,
    required this.nutritionDay,
  });

  final Map<String, dynamic> workoutDay;
  final Map<String, dynamic>? nutritionDay;

  @override
  Widget build(BuildContext context) {
    final blocks = (workoutDay['blocks'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final meals = (nutritionDay?['meals'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Material(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          color: Theme.of(context).colorScheme.surface,
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${workoutDay['day_label'] ?? 'Dia'} · ${workoutDay['date'] ?? ''}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                workoutDay['session_title']?.toString() ?? 'Plan del dia',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(workoutDay['focus']?.toString() ?? ''),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _DayChip(
                    label: '${workoutDay['duration_minutes'] ?? 45} min',
                  ),
                  _DayChip(
                    label: 'Intensidad ${workoutDay['intensity'] ?? 'Media'}',
                  ),
                  _DayChip(
                    label: workoutDay['is_past'] == true
                        ? 'Dia pasado'
                        : 'Dia activo',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Rutina', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              if (blocks.isEmpty)
                const Text('No hay bloques de entrenamiento para este dia.')
              else
                ...blocks.map(
                  (block) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppSurfaceCard(
                      backgroundColor: AppColors.surface,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            block['title']?.toString() ?? 'Bloque',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(block['description']?.toString() ?? ''),
                          if ((block['time_box']?.toString() ?? '')
                              .isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text('Tiempo: ${block['time_box']}'),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                'Alimentacion',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              if (meals.isEmpty)
                const Text('No hay comidas cargadas para este dia.')
              else
                ...meals.map(
                  (meal) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppSurfaceCard(
                      backgroundColor: AppColors.surfaceClay,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meal['title']?.toString() ?? 'Comida',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(meal['meal']?.toString() ?? ''),
                          if ((meal['macros']?.toString() ?? '')
                              .isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(meal['macros']?.toString() ?? ''),
                          ],
                          if ((meal['detail']?.toString() ?? '')
                              .isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(meal['detail']?.toString() ?? ''),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// T-07 — Intensity chip with color coding
class _IntensityChip extends StatelessWidget {
  const _IntensityChip({required this.intensity});

  final String intensity;

  @override
  Widget build(BuildContext context) {
    final Color textColor;
    final Color bgColor;
    final lower = intensity.toLowerCase();
    if (lower == 'alta' || lower == 'high') {
      textColor = Colors.red.shade700;
      bgColor = Colors.red.shade50;
    } else if (lower == 'moderada' || lower == 'moderate' || lower == 'media') {
      textColor = Colors.amber.shade700;
      bgColor = Colors.amber.shade50;
    } else if (lower == 'baja' || lower == 'low') {
      textColor = Colors.green.shade700;
      bgColor = Colors.green.shade50;
    } else {
      textColor = Colors.grey.shade700;
      bgColor = Colors.grey.shade100;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        intensity,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _DetailText extends StatelessWidget {
  const _DetailText({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(text),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

String _formatWorkoutDuration(int minutes, String units) {
  return '$minutes min';
}

String _mapEnergyLabel(String label) {
  switch (label) {
    case 'Con mucha energía':
      return 'Alta';
    case 'Cansado':
      return 'Baja';
    default:
      return 'Media';
  }
}

String _formatWorkoutBlockDescription(String base, String style) {
  return switch (style) {
    'Exigente' => '$base Prioriza una ejecucion precisa y descansos cortos.',
    'Flexible' => '$base Si tu energia baja, conserva tecnica y continuidad.',
    _ => '$base Avanza con ritmo sostenible.',
  };
}

String _advancedWorkoutAlternative(String style) {
  return switch (style) {
    'Exigente' =>
      'Si el tiempo se corta, conserva el bloque principal y elimina el accesorio final.',
    'Flexible' =>
      'Si no tienes energia, convierte la sesion en una version de mantenimiento de 20 minutos.',
    _ =>
      'Si el dia se complica, mantente con movilidad, bloque principal y una salida corta.',
  };
}

String _shortBlockSupport(String description) {
  if (description.length <= 84) {
    return description;
  }
  return '${description.substring(0, 84)}...';
}

String _actionForBlock(String title) {
  return switch (title) {
    'Activacion' =>
      'Entra en calor, mueve articulaciones clave y prepara respiracion antes de cargar.',
    'Bloque principal' =>
      'Aqui va tu trabajo mas importante. Busca concentracion, buena tecnica y ritmo estable.',
    'Bloque de rendimiento' =>
      'Usa este bloque para perseguir calidad real: una serie buena vale mas que volumen desordenado.',
    'Finisher' =>
      'Cierra con intensidad corta. Debe sentirse exigente pero controlable.',
    'Salida de recuperacion' =>
      'Baja pulsaciones, recupera movilidad y termina mejor de lo que empezaste.',
    'Checklist tecnico' =>
      'Revisa postura, respiracion y el patron tecnico que quieres repetir mejor.',
    _ =>
      'Ejecuta este bloque con atencion y usa la consigna tecnica principal como guia.',
  };
}

String _cueForBlock(String title, String style) {
  final base = switch (title) {
    'Activacion' => 'Movilidad limpia, respiracion y control de postura.',
    'Bloque principal' =>
      'Rango estable, tecnica consistente y descansos medidos.',
    'Bloque de rendimiento' =>
      'Que no se rompa la tecnica cuando sube el esfuerzo.',
    'Finisher' => 'Respira y manten tension sin perder forma.',
    'Salida de recuperacion' => 'Baja intensidad y recupera control.',
    _ => 'Usa una sola consigna tecnica y repitela durante todo el bloque.',
  };
  return switch (style) {
    'Exigente' => '$base Busca precision y no regales repeticiones flojas.',
    'Flexible' => '$base Recorta volumen antes que tecnica si baja la energia.',
    _ => '$base Mantente consistente y sostenible.',
  };
}

String _fallbackForBlock(String title) {
  return switch (title) {
    'Activacion' => 'Haz una version de 3 minutos y entra al bloque principal.',
    'Bloque principal' => 'Reduce una serie o una variante, pero no lo saltes.',
    'Bloque de rendimiento' =>
      'Haz menos repeticiones o una sola serie de calidad.',
    'Finisher' => 'Cortalo a la mitad o cambialo por una caminata rapida.',
    'Salida de recuperacion' =>
      'Haz al menos 2 minutos de respiracion y movilidad.',
    _ => 'Mantente con una version corta pero coherente del bloque.',
  };
}
