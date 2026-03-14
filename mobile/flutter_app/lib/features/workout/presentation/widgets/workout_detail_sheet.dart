import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_bottom_sheet.dart';

class WorkoutDetailSheet extends StatelessWidget {
  const WorkoutDetailSheet({
    super.key,
    required this.block,
    required this.blockIndex,
    required this.totalBlocks,
    required this.onToggleCompleted,
    required this.onToggleExercise,
  });

  final Map<String, dynamic> block;
  final int blockIndex;
  final int totalBlocks;
  final VoidCallback onToggleCompleted;
  final ValueChanged<String> onToggleExercise;

  @override
  Widget build(BuildContext context) {
    final exercises = _normalizeMapList(block['exercises']);
    final substitutions = _normalizeSubstitutions(block['substitutions']);
    final muscleGroup = block['muscle_group']?.toString();
    final location = block['location']?.toString();
    final goal = block['goal']?.toString() ?? '';
    final isCompleted = block['completed'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                block['title']?.toString() ?? 'Bloque',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Chip(label: Text('Paso ${blockIndex + 1}/$totalBlocks')),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onToggleCompleted,
          icon: Icon(
            isCompleted
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
          ),
          label: Text(
            isCompleted ? 'Bloque realizado' : 'Marcar como realizado',
          ),
        ),
        const SizedBox(height: 12),
        if (muscleGroup != null || location != null)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (muscleGroup != null)
                _InfoChip(
                  label: muscleGroup,
                  icon: Icons.fitness_center_rounded,
                  color: const Color(0xFFDCEEDC),
                ),
              if (location != null)
                _InfoChip(
                  label: location,
                  icon: Icons.place_rounded,
                  color: const Color(0xFFE8E4F4),
                ),
            ],
          ),
        if ((block['description']?.toString() ?? '').isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(block['description']!.toString()),
        ],
        if (block['time_box'] != null) ...[
          const SizedBox(height: 10),
          Text('Duracion sugerida: ${block['time_box']}'),
        ],
        if (goal.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('Objetivo: $goal'),
        ],
        if (exercises.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            'Ejercicios principales',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...exercises.map((exercise) {
            final isSelected = exercise['is_selected'] != false;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFE8F4EE)
                      : const Color(0xFFF6F1E8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF2E7D52)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise['name']?.toString() ?? '',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${exercise['sets']} series · ${exercise['reps']} · Descanso ${exercise['rest']}',
                          ),
                          if ((exercise['notes']?.toString() ?? '')
                              .isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(exercise['notes']?.toString() ?? ''),
                          ],
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF2E7D52),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
        if (substitutions.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'Sustituciones disponibles',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: substitutions.map((item) {
              final name = item['name']?.toString() ?? '';
              final isSelected = item['is_selected'] == true;
              return FilterChip(
                label: Text(name),
                selected: isSelected,
                selectedColor: const Color(0xFFD6EEE6),
                onSelected: (_) => _showReplacementDialog(context, item),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _normalizeMapList(dynamic raw) {
    return (raw as List<dynamic>? ?? const [])
        .map((item) {
          if (item is Map<String, dynamic>) {
            return item;
          }
          if (item is Map) {
            return item.map((key, value) => MapEntry(key.toString(), value));
          }
          if (item is String) {
            return {'name': item};
          }
          return <String, dynamic>{};
        })
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<Map<String, dynamic>> _normalizeSubstitutions(dynamic raw) {
    return _normalizeMapList(raw)
        .map((item) {
          if (item.containsKey('name')) {
            return item;
          }
          final fallback = item.values.isEmpty
              ? ''
              : item.values.first.toString();
          return {'name': fallback};
        })
        .where((item) => (item['name']?.toString() ?? '').isNotEmpty)
        .toList();
  }

  Future<void> _showReplacementDialog(
    BuildContext context,
    Map<String, dynamic> item,
  ) async {
    final name = item['name']?.toString() ?? '';
    final forExercise = item['for_exercise']?.toString() ?? 'este bloque';
    final primaryExercise = _normalizeMapList(block['exercises']).firstWhere(
      (exercise) => exercise['name']?.toString() == forExercise,
      orElse: () => <String, dynamic>{},
    );
    final movementSummary =
        block['description']?.toString() ??
        'Mantén una técnica limpia y controlada durante todo el recorrido.';
    final detailText = item['notes']?.toString().trim().isNotEmpty == true
        ? item['notes']?.toString() ?? ''
        : primaryExercise['notes']?.toString() ?? '';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Alternativa sugerida para $forExercise.'),
              const SizedBox(height: 10),
              Text(
                'Ejercicio original',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(forExercise),
              if ((primaryExercise['sets']?.toString() ?? '').isNotEmpty ||
                  (primaryExercise['reps']?.toString() ?? '').isNotEmpty ||
                  (primaryExercise['rest']?.toString() ?? '').isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if ((primaryExercise['sets']?.toString() ?? '').isNotEmpty)
                      _MetricChip(label: 'Series ${primaryExercise['sets']}'),
                    if ((primaryExercise['reps']?.toString() ?? '').isNotEmpty)
                      _MetricChip(label: 'Reps ${primaryExercise['reps']}'),
                    if ((primaryExercise['rest']?.toString() ?? '').isNotEmpty)
                      _MetricChip(label: 'Descanso ${primaryExercise['rest']}'),
                  ],
                ),
              ],
              if ((item['muscle_group']?.toString() ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Grupo muscular: ${item['muscle_group']}'),
              ],
              if ((item['location']?.toString() ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Lugar ideal: ${item['location']}'),
              ],
              if (detailText.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(detailText),
              ],
              const SizedBox(height: 10),
              Text(
                'Cómo se hace',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(movementSummary),
              const SizedBox(height: 10),
              Text(
                'Cómo usar el reemplazo',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                detailText.isNotEmpty
                    ? detailText
                    : 'Usa el mismo número de series y repeticiones del ejercicio original, priorizando control y rango seguro.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                minimumSize: const Size(0, 36),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(item['is_selected'] == true ? 'Quitar' : 'Usar'),
            ),
          ],
        );
      },
    );
    if (confirm == true) {
      onToggleExercise(name);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1ECE3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

void showWorkoutDetailSheet(
  BuildContext context, {
  required Map<String, dynamic> block,
  required int blockIndex,
  required int totalBlocks,
  required VoidCallback onToggleCompleted,
  required ValueChanged<String> onToggleExercise,
}) {
  showAppBottomSheet(
    context,
    child: WorkoutDetailSheet(
      block: block,
      blockIndex: blockIndex,
      totalBlocks: totalBlocks,
      onToggleCompleted: onToggleCompleted,
      onToggleExercise: onToggleExercise,
    ),
  );
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
