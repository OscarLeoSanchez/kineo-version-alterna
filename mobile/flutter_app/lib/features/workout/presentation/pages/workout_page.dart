import 'package:flutter/material.dart';

import '../../../activity/data/services/activity_history_api_service.dart';
import '../../../profile/data/services/profile_preferences_store.dart';
import '../../../profile/domain/models/profile_preferences.dart';
import '../../../../shared/widgets/app_section_title.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../data/services/workout_api_service.dart';
import '../../data/services/workout_log_api_service.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  late Future<_WorkoutViewData> _future;
  bool _isSubmitting = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _future = _loadWorkout();
  }

  Future<_WorkoutViewData> _loadWorkout() async {
    final results = await Future.wait([
      const WorkoutApiService().fetchWorkoutSummary(),
      const ActivityHistoryApiService().fetchHistory(),
    ]);
    return _WorkoutViewData(
      summary: results[0],
      history: results[1],
      preferences: await ProfilePreferencesStore().load(),
    );
  }

  Future<void> _refreshWorkoutPlan() async {
    setState(() {
      _isRefreshing = true;
      _future = _loadWorkout();
    });
    try {
      await _future;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plan actualizado con la informacion mas reciente.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
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
      if (completedTitles.isNotEmpty) 'Bloques completados: ${completedTitles.join(', ')}',
      'RPE: ${result.effort.round()}/10',
      'Tecnica: ${result.technique}',
      if (result.note.isNotEmpty) result.note,
    ].join(' | ');

    try {
      await const WorkoutLogApiService().submitWorkout(
        sessionMinutes: data['duration_minutes'] as int? ?? 45,
        focus: focusLabel,
        energyLevel: result.energyLevel,
        notes: notes,
      );
      setState(() {
        _future = _loadWorkout();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesion registrada en tu progreso.')),
      );
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
      setState(() {
        _future = _loadWorkout();
      });
    } finally {
      durationController.dispose();
      focusController.dispose();
      notesController.dispose();
    }
  }

  Future<void> _deleteWorkout(int id) async {
    await const ActivityHistoryApiService().deleteWorkout(id);
    if (!mounted) return;
    setState(() {
      _future = _loadWorkout();
    });
  }

  void _showBlockDetail(
    Map<String, dynamic> item,
    ProfilePreferences preferences,
    int index,
    int totalBlocks,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _WorkoutSheet(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item['title']?.toString() ?? 'Bloque',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  Chip(label: Text('Paso ${index + 1}/$totalBlocks')),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _formatWorkoutBlockDescription(
                  item['description']?.toString() ?? '',
                  preferences.coachingStyle,
                ),
              ),
              if (item['time_box'] != null) ...[
                const SizedBox(height: 8),
                Text('Duracion sugerida: ${item['time_box']}'),
              ],
              if (item['goal'] != null) ...[
                const SizedBox(height: 8),
                Text('Objetivo: ${item['goal']}'),
              ],
              const SizedBox(height: 16),
              if ((item['exercises'] as List<dynamic>? ?? []).isNotEmpty) ...[
                Text(
                  'Ejercicios del bloque',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...((item['exercises'] as List<dynamic>).map((exercise) {
                  final detail = exercise as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F1E8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detail['name']?.toString() ?? '',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${detail['sets']} · ${detail['reps']} · Descanso ${detail['rest']}',
                          ),
                        ],
                      ),
                    ),
                  );
                })),
                const SizedBox(height: 8),
              ],
              _DetailText(
                title: 'Que hacer',
                text: _actionForBlock(item['title']?.toString() ?? ''),
              ),
              _DetailText(
                title: 'En que fijarte',
                text: _cueForBlock(
                  item['title']?.toString() ?? '',
                  preferences.coachingStyle,
                ),
              ),
              _DetailText(
                title: 'Si vas justo de tiempo',
                text: _fallbackForBlock(item['title']?.toString() ?? ''),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_WorkoutViewData>(
      future: _future,
      builder: (context, snapshot) {
        final viewData = snapshot.data;
        final data = viewData?.summary;
        final workouts = viewData?.history['workouts'] as List<dynamic>? ?? [];
        final weeklyCalendar =
            data?['weekly_calendar'] as List<dynamic>? ?? [];
        final preferences =
            viewData?.preferences ?? ProfilePreferences.defaults();
        final blocks = (data?['blocks'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
          children: [
            const AppSectionTitle(
              title: 'Workout',
              subtitle: 'Entiende la sesion, abre cada bloque y registra lo que si hiciste.',
            ),
            const SizedBox(height: 18),
            _buildHero(context, data, preferences),
            const SizedBox(height: 20),
            _buildRouteCard(context, blocks, preferences),
            const SizedBox(height: 20),
            _buildStats(context, data, preferences),
            const SizedBox(height: 20),
            _buildCalendar(context, weeklyCalendar),
            const SizedBox(height: 20),
            _buildHistory(context, workouts),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: data == null || _isSubmitting
                        ? null
                        : () => _registerWorkout(data),
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: Text(
                      _isSubmitting ? 'Guardando...' : 'Registrar sesion',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isRefreshing ? null : _refreshWorkoutPlan,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(
                      _isRefreshing ? 'Actualizando...' : 'Actualizar plan',
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildHero(
    BuildContext context,
    Map<String, dynamic>? data,
    ProfilePreferences preferences,
  ) {
    final completedToday = data?['completed_today'] == true;
    final durationMinutes = data?['duration_minutes'] as int? ?? 45;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF143C3A), Color(0xFF2B6A66)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data?['title']?.toString() ?? 'Sesion del dia',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data?['focus']?.toString() ?? 'Foco adaptativo',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroChip(label: _formatWorkoutDuration(durationMinutes, preferences.units)),
              _HeroChip(label: 'Energia ${data?['energy_level']?.toString() ?? '--'}'),
              _HeroChip(
                label: completedToday ? 'Hoy ya registrada' : 'Lista para ejecutar',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
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
  ) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ruta de hoy', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'La sesion esta dividida en pasos. Toca cualquier bloque para ver que hacer y como adaptarlo.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ...List.generate(blocks.length, (index) {
            final block = blocks[index];
            return Padding(
              padding: EdgeInsets.only(bottom: index == blocks.length - 1 ? 0 : 12),
              child: InkWell(
                onTap: () => _showBlockDetail(block, preferences, index, blocks.length),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F0E6),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFF143C3A),
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
                            Text(_shortBlockSupport(block['description']?.toString() ?? '')),
                            const SizedBox(height: 8),
                            Text(
                              'Ver detalle del bloque',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
            );
          }),
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
          backgroundColor: const Color(0xFFE8EFE8),
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

  Widget _buildCalendar(BuildContext context, List<dynamic> weeklyCalendar) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionTitle(title: 'Calendario semanal'),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: weeklyCalendar.map((entry) {
              final item = entry as Map<String, dynamic>;
              final goalHit = item['goal_hit'] == true;
              return Container(
                width: 94,
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                decoration: BoxDecoration(
                  color: goalHit
                      ? const Color(0xFFD6EEE6)
                      : const Color(0xFFF1ECE3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(item['label']?.toString() ?? ''),
                    const SizedBox(height: 6),
                    Text(
                      '${item['completed_sessions'] ?? 0}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(item['date']?.toString() ?? ''),
                  ],
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
                  child: AppSurfaceCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['focus']?.toString() ?? '',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${item['session_minutes']} min · ${item['energy_level']}',
                              ),
                              if ((item['notes']?.toString() ?? '').isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  item['notes']?.toString() ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
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
                            PopupMenuItem(value: 'edit', child: Text('Editar')),
                            PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                          ],
                        ),
                        Text((item['completed_at']?.toString() ?? '').split('T').first),
                      ],
                    ),
                  ),
                );
              })),
      ],
    );
  }
}

class _WorkoutViewData {
  const _WorkoutViewData({
    required this.summary,
    required this.history,
    required this.preferences,
  });

  final Map<String, dynamic> summary;
  final Map<String, dynamic> history;
  final ProfilePreferences preferences;
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
  late final TextEditingController _sessionNameController;
  late final TextEditingController _noteController;
  late final List<bool> _completedBlocks;
  late String _energyLevel;
  double _effort = 7;
  String _technique = 'Solida';

  @override
  void initState() {
    super.initState();
    _sessionNameController = TextEditingController(
      text: widget.initialSessionName,
    );
    _noteController = TextEditingController();
    _completedBlocks = List<bool>.filled(widget.blocks.length, true);
    _energyLevel = widget.initialEnergyLevel;
  }

  @override
  void dispose() {
    _sessionNameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(
      _WorkoutRegistrationResult(
        sessionName: _sessionNameController.text.trim(),
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
      appBar: AppBar(
        title: const Text('Cerrar sesion'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            Text(
              'Deja trazabilidad clara de que hiciste, como te sentiste y si hay algo que ajustar.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _sessionNameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de esta sesion',
              ),
            ),
            if (widget.blocks.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Bloques completados',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...List.generate(widget.blocks.length, (index) {
                final block = widget.blocks[index];
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _completedBlocks[index],
                  title: Text(block['title']?.toString() ?? 'Bloque'),
                  subtitle: Text(
                    block['goal']?.toString() ??
                        _shortBlockSupport(
                          block['description']?.toString() ?? '',
                        ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _completedBlocks[index] = value ?? false;
                    });
                  },
                );
              }),
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _energyLevel,
              decoration: const InputDecoration(
                labelText: 'Energia al terminar',
              ),
              items: const [
                DropdownMenuItem(value: 'Alta', child: Text('Alta')),
                DropdownMenuItem(value: 'Media', child: Text('Media')),
                DropdownMenuItem(value: 'Baja', child: Text('Baja')),
              ],
              onChanged: (value) {
                setState(() {
                  _energyLevel = value ?? 'Media';
                });
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Esfuerzo percibido: ${_effort.round()}/10',
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
            DropdownButtonFormField<String>(
              initialValue: _technique,
              decoration: const InputDecoration(
                labelText: 'Como estuvo la tecnica',
              ),
              items: const [
                DropdownMenuItem(value: 'Solida', child: Text('Solida')),
                DropdownMenuItem(value: 'Aceptable', child: Text('Aceptable')),
                DropdownMenuItem(value: 'Inestable', child: Text('Inestable')),
              ],
              onChanged: (value) {
                setState(() {
                  _technique = value ?? 'Solida';
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observacion final',
                hintText:
                    'Ejemplo: recorte el finisher por tiempo o me senti fuerte en sentadilla.',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Guardar sesion'),
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
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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

String _formatWorkoutBlockDescription(String base, String style) {
  return switch (style) {
    'Exigente' => '$base Prioriza una ejecucion precisa y descansos cortos.',
    'Flexible' => '$base Si tu energia baja, conserva tecnica y continuidad.',
    _ => '$base Avanza con ritmo sostenible.',
  };
}

String _advancedWorkoutAlternative(String style) {
  return switch (style) {
    'Exigente' => 'Si el tiempo se corta, conserva el bloque principal y elimina el accesorio final.',
    'Flexible' => 'Si no tienes energia, convierte la sesion en una version de mantenimiento de 20 minutos.',
    _ => 'Si el dia se complica, mantente con movilidad, bloque principal y una salida corta.',
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
    'Activacion' => 'Entra en calor, mueve articulaciones clave y prepara respiracion antes de cargar.',
    'Bloque principal' => 'Aqui va tu trabajo mas importante. Busca concentracion, buena tecnica y ritmo estable.',
    'Bloque de rendimiento' => 'Usa este bloque para perseguir calidad real: una serie buena vale mas que volumen desordenado.',
    'Finisher' => 'Cierra con intensidad corta. Debe sentirse exigente pero controlable.',
    'Salida de recuperacion' => 'Baja pulsaciones, recupera movilidad y termina mejor de lo que empezaste.',
    'Checklist tecnico' => 'Revisa postura, respiracion y el patron tecnico que quieres repetir mejor.',
    _ => 'Ejecuta este bloque con atencion y usa la consigna tecnica principal como guia.',
  };
}

String _cueForBlock(String title, String style) {
  final base = switch (title) {
    'Activacion' => 'Movilidad limpia, respiracion y control de postura.',
    'Bloque principal' => 'Rango estable, tecnica consistente y descansos medidos.',
    'Bloque de rendimiento' => 'Que no se rompa la tecnica cuando sube el esfuerzo.',
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
    'Bloque de rendimiento' => 'Haz menos repeticiones o una sola serie de calidad.',
    'Finisher' => 'Cortalo a la mitad o cambialo por una caminata rapida.',
    'Salida de recuperacion' => 'Haz al menos 2 minutos de respiracion y movilidad.',
    _ => 'Mantente con una version corta pero coherente del bloque.',
  };
}
