import 'package:flutter/material.dart';

import '../../../../shared/widgets/shimmer_box.dart';
import '../../data/services/exercise_catalog_api_service.dart';
import '../../domain/models/exercise_catalog_item.dart';
import 'exercise_substitute_sheet.dart';
import 'plan_modification_sheet.dart';

// ---------------------------------------------------------------------------
// Public helper
// ---------------------------------------------------------------------------

void showExerciseDetailSheet(
  BuildContext context, {
  int? exerciseId,
  Map<String, dynamic>? exerciseData,
  List<String> userEquipment = const [],
  String? dayLabel,
  String? blockTitle,
  String? dayIsoDate,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ExerciseDetailSheet(
      exerciseId: exerciseId,
      exerciseData: exerciseData,
      userEquipment: userEquipment,
      dayLabel: dayLabel,
      blockTitle: blockTitle,
      dayIsoDate: dayIsoDate,
    ),
  );
}

// ---------------------------------------------------------------------------
// Sheet widget
// ---------------------------------------------------------------------------

class ExerciseDetailSheet extends StatefulWidget {
  const ExerciseDetailSheet({
    super.key,
    this.exerciseId,
    this.exerciseData,
    this.userEquipment = const [],
    this.dayLabel,
    this.blockTitle,
    this.dayIsoDate,
  });

  final int? exerciseId;
  final Map<String, dynamic>? exerciseData;
  final List<String> userEquipment;
  final String? dayLabel;
  final String? blockTitle;
  final String? dayIsoDate;

  @override
  State<ExerciseDetailSheet> createState() => _ExerciseDetailSheetState();
}

class _ExerciseDetailSheetState extends State<ExerciseDetailSheet> {
  ExerciseCatalogItem? _item;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // If exerciseData already provided, parse it directly — no API call needed.
    if (widget.exerciseData != null) {
      try {
        final parsed =
            ExerciseCatalogItem.fromJson(widget.exerciseData!);
        if (mounted) setState(() { _item = parsed; _loading = false; });
      } catch (_) {
        if (mounted) setState(() { _error = 'No se pudo cargar el ejercicio'; _loading = false; });
      }
      return;
    }

    if (widget.exerciseId == null) {
      if (mounted) setState(() { _error = 'ID de ejercicio no especificado'; _loading = false; });
      return;
    }

    try {
      final item = await const ExerciseCatalogApiService()
          .getExercise(widget.exerciseId!);
      if (mounted) setState(() { _item = item; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Material(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: _loading
                    ? _buildLoading()
                    : _error != null
                        ? _buildError()
                        : _buildContent(scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoading() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          ShimmerBox(width: double.infinity, height: 180, borderRadius: 16),
          SizedBox(height: 16),
          ShimmerBox(width: 220, height: 28, borderRadius: 8),
          SizedBox(height: 10),
          ShimmerBox(width: double.infinity, height: 80, borderRadius: 12),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 52, color: Color(0xFFDC2626)),
            const SizedBox(height: 16),
            Text(
              'No se pudo cargar el ejercicio',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                setState(() { _loading = true; _error = null; });
                _load();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ScrollController scrollController) {
    final item = _item!;
    final theme = Theme.of(context);
    final displayName = item.nameEs?.isNotEmpty == true ? item.nameEs! : item.name;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        // Image / placeholder
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: const Color(0xFFEEEEEE),
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: item.hasImage && item.firstImageUrl != null
              ? Image.network(
                  item.firstImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _imagePlaceholder(),
                )
              : _imagePlaceholder(),
        ),
        const SizedBox(height: 16),

        // Name
        Text(
          displayName,
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),

        // Primary · Secondary muscle
        if (item.displayMuscle.isNotEmpty)
          Text(
            [
              item.displayMuscle,
              if (item.secondaryMuscles.isNotEmpty) item.secondaryMuscles.first,
            ].join(' · '),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        const SizedBox(height: 12),

        // Info chips row
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            if (item.difficulty != null)
              _InfoChip(
                label: item.difficulty!,
                icon: Icons.trending_up_rounded,
                color: const Color(0xFFE8F4EE),
              ),
            if (item.category != null)
              _InfoChip(
                label: item.category!,
                icon: Icons.category_rounded,
                color: const Color(0xFFE8E4F4),
              ),
            if (item.estimatedDurationSeconds != null)
              _InfoChip(
                label: '${item.estimatedDurationSeconds}s',
                icon: Icons.timer_rounded,
                color: const Color(0xFFFFF3CD),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Equipment required
        if (item.equipmentRequired.isNotEmpty) ...[
          Text(
            'Equipamiento necesario:',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: item.equipmentRequired
                .map((e) => _EquipChip(label: e))
                .toList(),
          ),
          const SizedBox(height: 14),
        ],

        // Equipment alternatives
        if (item.equipmentAlternatives.isNotEmpty) ...[
          Text(
            'Alternativas de equipo:',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: item.equipmentAlternatives
                .map((e) => _EquipChip(label: e, muted: true))
                .toList(),
          ),
          const SizedBox(height: 14),
        ],

        // Instructions
        if (item.instructionsEs.isNotEmpty) ...[
          Text(
            'Instrucciones:',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ...item.instructionsEs.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(top: 1, right: 8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF143C3A),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
        ],

        // Action buttons
        _ActionButton(
          icon: Icons.edit_rounded,
          label: 'Modificar ejercicio',
          onTap: () => showPlanModificationSheet(
            context,
            exerciseName: displayName,
            dayLabel: widget.dayLabel,
            blockTitle: widget.blockTitle,
          ),
        ),
        const SizedBox(height: 8),
        _ActionButton(
          icon: Icons.swap_horiz_rounded,
          label: 'Cambiar ejercicio',
          onTap: () {
            final id = item.id;
            showExerciseSubstituteSheet(
              context,
              exerciseId: id,
              exerciseName: displayName,
              userEquipment: widget.userEquipment,
              onSubstituteSelected: (_) => Navigator.of(context).pop(),
            );
          },
        ),
        const SizedBox(height: 8),
        _ActionButton(
          icon: Icons.list_alt_rounded,
          label: 'Registrar series',
          filled: true,
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushNamed(
              '/workout-mode',
              arguments: {
                'exerciseName': displayName,
                'dayIsoDate': widget.dayIsoDate ??
                    DateTime.now().toIso8601String().substring(0, 10),
                'blockTitle': widget.blockTitle,
              },
            );
          },
        ),
      ],
    );
  }

  Widget _imagePlaceholder() {
    return const Center(
      child: Icon(
        Icons.fitness_center_rounded,
        size: 64,
        color: Color(0xFFBBBBBB),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

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
          Icon(icon, size: 13),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _EquipChip extends StatelessWidget {
  const _EquipChip({required this.label, this.muted = false});

  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: muted
            ? Theme.of(context).colorScheme.surfaceVariant
            : const Color(0xFFDCEEDC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: muted ? Colors.transparent : const Color(0xFF2E7D52),
        ),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onTap,
          icon: Icon(icon),
          label: Text(label),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}
