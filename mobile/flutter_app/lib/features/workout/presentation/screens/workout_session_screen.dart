import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/services/workout_block_api_service.dart';
import '../../data/services/workout_log_api_service.dart';
import '../widgets/workout_log_confirmation_sheet.dart';

class WorkoutSessionScreen extends StatefulWidget {
  const WorkoutSessionScreen({super.key, required this.workoutDay});

  final Map<String, dynamic> workoutDay;

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  late final List<_GuidedStep> _steps;
  int _stepIndex = 0;
  int _remainingSeconds = 0;
  Timer? _timer;
  bool _isRunning = false;
  bool _isSaving = false;
  final _sessionNotesController = TextEditingController();
  final Set<String> _completedBlocks = <String>{};

  @override
  void initState() {
    super.initState();
    _steps = _buildSteps();
    _remainingSeconds = _steps.isNotEmpty ? _steps.first.suggestedSeconds : 0;
    for (final block in _blocks) {
      if (block['completed'] == true) {
        _completedBlocks.add(block['title']?.toString() ?? '');
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sessionNotesController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _blocks =>
      (widget.workoutDay['blocks'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();

  List<String> get _warmup =>
      (widget.workoutDay['warmup'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList();

  List<String> get _cooldown =>
      (widget.workoutDay['cooldown'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList();

  List<_GuidedStep> _buildSteps() {
    final steps = <_GuidedStep>[];
    if (_warmup.isNotEmpty) {
      steps.add(
        _GuidedStep(
          title: 'Calentamiento',
          subtitle: 'Prepara el cuerpo antes de entrar a los bloques.',
          items: _warmup,
          type: _GuidedStepType.warmup,
          suggestedSeconds: 5 * 60,
        ),
      );
    }
    for (final block in _blocks) {
      steps.add(
        _GuidedStep(
          title: block['title']?.toString() ?? 'Bloque',
          subtitle:
              block['description']?.toString() ??
              block['goal']?.toString() ??
              '',
          items: (block['exercises'] as List<dynamic>? ?? []).map((exercise) {
            final item = Map<String, dynamic>.from(exercise as Map);
            final base = item['name']?.toString() ?? 'Ejercicio';
            final sets = item['sets']?.toString() ?? '';
            final reps = item['reps']?.toString() ?? '';
            final rest = item['rest']?.toString() ?? '';
            return '$base · $sets · $reps · Descanso $rest';
          }).toList(),
          type: _GuidedStepType.block,
          blockTitle: block['title']?.toString(),
          suggestedSeconds: _parseTimeBoxSeconds(block['time_box']?.toString()),
        ),
      );
    }
    if (_cooldown.isNotEmpty) {
      steps.add(
        _GuidedStep(
          title: 'Vuelta a la calma',
          subtitle: 'Baja pulsaciones y cierra la sesión con control.',
          items: _cooldown,
          type: _GuidedStepType.cooldown,
          suggestedSeconds: 4 * 60,
        ),
      );
    }
    return steps;
  }

  _GuidedStep get _currentStep => _steps[_stepIndex];

  int get _completedCount => _steps.where((step) => _isStepDone(step)).length;

  bool _isStepDone(_GuidedStep step) {
    if (step.type != _GuidedStepType.block) {
      return _stepIndex > _steps.indexOf(step);
    }
    return _completedBlocks.contains(step.blockTitle ?? '');
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) return;
      if (_remainingSeconds <= 1) {
        timer.cancel();
        await HapticFeedback.mediumImpact();
        setState(() {
          _remainingSeconds = 0;
          _isRunning = false;
        });
        return;
      }
      setState(() {
        _remainingSeconds -= 1;
      });
    });
    setState(() => _isRunning = true);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _currentStep.suggestedSeconds;
      _isRunning = false;
    });
  }

  Future<void> _markCurrentBlockDone() async {
    if (_currentStep.type != _GuidedStepType.block ||
        _currentStep.blockTitle == null) {
      return;
    }
    final blockTitle = _currentStep.blockTitle!;
    final currentBlock = _blocks.firstWhere(
      (block) => block['title']?.toString() == blockTitle,
      orElse: () => <String, dynamic>{},
    );
    await const WorkoutBlockApiService().saveBlockState(
      dayIsoDate: widget.workoutDay['iso_date']?.toString() ?? '',
      blockTitle: blockTitle,
      completed: true,
      selectedExercises:
          (currentBlock['selected_exercises'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList(),
      planId: widget.workoutDay['plan_id'] as int?,
    );
    if (!mounted) return;
    setState(() {
      _completedBlocks.add(blockTitle);
    });
  }

  Future<void> _nextStep() async {
    if (_currentStep.type == _GuidedStepType.block) {
      await _markCurrentBlockDone();
    }
    if (!mounted) return;
    if (_stepIndex >= _steps.length - 1) {
      await _finishSession();
      return;
    }
    setState(() {
      _stepIndex += 1;
      _remainingSeconds = _currentStep.suggestedSeconds;
      _isRunning = false;
    });
    _timer?.cancel();
  }

  void _previousStep() {
    if (_stepIndex == 0) return;
    _timer?.cancel();
    setState(() {
      _stepIndex -= 1;
      _remainingSeconds = _currentStep.suggestedSeconds;
      _isRunning = false;
    });
  }

  Future<void> _finishSession() async {
    setState(() => _isSaving = true);
    try {
      final notes = [
        'Modo guiado completado',
        if (_completedBlocks.isNotEmpty)
          'Bloques: ${_completedBlocks.join(', ')}',
        if (_sessionNotesController.text.trim().isNotEmpty)
          _sessionNotesController.text.trim(),
      ].join(' | ');
      final blockStates = _blocks.map((block) {
        final title = block['title']?.toString() ?? 'Bloque';
        final selectedExercises =
            (block['selected_exercises'] as List<dynamic>? ?? const [])
                .map((item) => item.toString())
                .toList();
        return {
          'block_title': title,
          'completed': _completedBlocks.contains(title),
          'selected_exercises': selectedExercises,
        };
      }).toList();
      await const WorkoutLogApiService().submitWorkout(
        sessionMinutes: widget.workoutDay['duration_minutes'] as int? ?? 45,
        focus: widget.workoutDay['focus']?.toString() ?? 'Sesión guiada',
        energyLevel: widget.workoutDay['intensity']?.toString() ?? 'Media',
        dayIsoDate: widget.workoutDay['iso_date']?.toString(),
        planId: widget.workoutDay['plan_id'] as int?,
        blockStates: blockStates,
        notes: notes,
      );
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _GuidedSessionSummarySheet(
          workoutDay: widget.workoutDay,
          completedBlocks: _completedBlocks.length,
          totalBlocks: _blocks.length,
        ),
      );
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => WorkoutLogConfirmationSheet(
          focus: widget.workoutDay['focus']?.toString() ?? 'Sesión guiada',
          energyLevel: widget.workoutDay['intensity']?.toString() ?? 'Media',
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _steps.isEmpty ? 0.0 : (_stepIndex + 1) / _steps.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Sesión guiada')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            children: [
              Text(
                widget.workoutDay['session_title']?.toString() ??
                    'Sesión del día',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.workoutDay['day_label'] ?? 'Hoy'} · ${widget.workoutDay['date'] ?? ''}',
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(value: progress, minHeight: 10),
              ),
              const SizedBox(height: 10),
              Text(
                'Paso ${_stepIndex + 1} de ${_steps.length} · Completados $_completedCount/${_steps.length}',
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F0E6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _StepChip(label: _currentStep.typeLabel),
                        _StepChip(label: _formatTime(_remainingSeconds)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _currentStep.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(_currentStep.subtitle),
                    const SizedBox(height: 14),
                    ..._currentStep.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Icon(
                                Icons.circle,
                                size: 8,
                                color: Color(0xFF143C3A),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppBarTimerCard(
                isRunning: _isRunning,
                onToggle: _toggleTimer,
                onReset: _resetTimer,
              ),
              const SizedBox(height: 16),
              if (_currentStep.type == _GuidedStepType.block)
                FilledButton.icon(
                  onPressed:
                      _completedBlocks.contains(_currentStep.blockTitle ?? '')
                      ? null
                      : _markCurrentBlockDone,
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: Text(
                    _completedBlocks.contains(_currentStep.blockTitle ?? '')
                        ? 'Bloque realizado'
                        : 'Marcar bloque realizado',
                  ),
                ),
              const SizedBox(height: 20),
              TextField(
                controller: _sessionNotesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notas rápidas de la sesión',
                  hintText: 'Cómo te sentiste, ajustes, dolor, energía...',
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _stepIndex == 0 ? null : _previousStep,
                      child: const Text('Anterior'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _nextStep,
                      child: Text(
                        _stepIndex == _steps.length - 1
                            ? 'Finalizar'
                            : 'Siguiente',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_isSaving)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x55FFFFFF),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

class AppBarTimerCard extends StatelessWidget {
  const AppBarTimerCard({
    super.key,
    required this.isRunning,
    required this.onToggle,
    required this.onReset,
  });

  final bool isRunning;
  final VoidCallback onToggle;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD8D1C4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: onToggle,
              icon: Icon(isRunning ? Icons.pause_rounded : Icons.play_arrow),
              label: Text(isRunning ? 'Pausar timer' : 'Iniciar timer'),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(onPressed: onReset, child: const Text('Reset')),
        ],
      ),
    );
  }
}

class _GuidedSessionSummarySheet extends StatelessWidget {
  const _GuidedSessionSummarySheet({
    required this.workoutDay,
    required this.completedBlocks,
    required this.totalBlocks,
  });

  final Map<String, dynamic> workoutDay;
  final int completedBlocks;
  final int totalBlocks;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.celebration_rounded,
              size: 44,
              color: Color(0xFF2E7D52),
            ),
            const SizedBox(height: 12),
            Text(
              'Sesión completada',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${workoutDay['session_title'] ?? 'Sesión'} · $completedBlocks/$totalBlocks bloques',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Continuar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label),
    );
  }
}

enum _GuidedStepType { warmup, block, cooldown }

class _GuidedStep {
  const _GuidedStep({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.type,
    required this.suggestedSeconds,
    this.blockTitle,
  });

  final String title;
  final String subtitle;
  final List<String> items;
  final _GuidedStepType type;
  final int suggestedSeconds;
  final String? blockTitle;

  String get typeLabel => switch (type) {
    _GuidedStepType.warmup => 'Calentamiento',
    _GuidedStepType.block => 'Bloque',
    _GuidedStepType.cooldown => 'Enfriamiento',
  };
}

int _parseTimeBoxSeconds(String? raw) {
  if (raw == null || raw.trim().isEmpty) return 6 * 60;
  final match = RegExp(r'(\d+)').firstMatch(raw);
  final minutes = int.tryParse(match?.group(1) ?? '') ?? 6;
  return minutes * 60;
}

String _formatTime(int totalSeconds) {
  final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
