import 'package:flutter/material.dart';

import '../../../../shared/widgets/pressable_card.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../../data/services/exercise_catalog_api_service.dart';
import '../../data/services/plan_modification_api_service.dart';
import '../../domain/models/exercise_catalog_item.dart';

// ---------------------------------------------------------------------------
// Public helper
// ---------------------------------------------------------------------------

void showExerciseSubstituteSheet(
  BuildContext context, {
  required int exerciseId,
  required String exerciseName,
  List<String> userEquipment = const [],
  required Function(String exerciseName) onSubstituteSelected,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ExerciseSubstituteSheet(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      userEquipment: userEquipment,
      onSubstituteSelected: onSubstituteSelected,
    ),
  );
}

// ---------------------------------------------------------------------------
// Sheet widget
// ---------------------------------------------------------------------------

class ExerciseSubstituteSheet extends StatefulWidget {
  const ExerciseSubstituteSheet({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
    this.userEquipment = const [],
    required this.onSubstituteSelected,
  });

  final int exerciseId;
  final String exerciseName;
  final List<String> userEquipment;
  final Function(String exerciseName) onSubstituteSelected;

  @override
  State<ExerciseSubstituteSheet> createState() =>
      _ExerciseSubstituteSheetState();
}

class _ExerciseSubstituteSheetState extends State<ExerciseSubstituteSheet> {
  List<ExerciseCatalogItem> _substitutes = [];
  bool _loading = true;
  String? _error;
  bool _filterByEquipment = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await const ExerciseCatalogApiService().getSubstitutes(
        widget.exerciseId,
        availableEquipment:
            _filterByEquipment ? widget.userEquipment : const [],
      );
      if (mounted) setState(() { _substitutes = results; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _selectSubstitute(ExerciseCatalogItem sub) async {
    final selectedName =
        sub.nameEs?.isNotEmpty == true ? sub.nameEs! : sub.name;
    setState(() => _saving = true);
    try {
      await const PlanModificationApiService().createModification({
        'modification_type': 'swap',
        'target_type': 'exercise',
        'target_item_name': widget.exerciseName,
        'replacement_item_name': selectedName,
        'override_json': '{}',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ejercicio cambiado'),
            backgroundColor: Color(0xFF2E7D52),
          ),
        );
        widget.onSubstituteSelected(selectedName);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar ejercicio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.35,
      expand: false,
      builder: (context, scrollController) {
        return Material(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          color: theme.colorScheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cambiar ejercicio',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sustitutos para: ${widget.exerciseName}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Equipment filter chip
              if (widget.userEquipment.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: FilterChip(
                    label: const Text('Filtrar por mi equipo'),
                    selected: _filterByEquipment,
                    onSelected: (val) {
                      setState(() => _filterByEquipment = val);
                      _load();
                    },
                    selectedColor: const Color(0xFFD6EEE6),
                  ),
                ),
              const SizedBox(height: 12),

              // Body
              Expanded(
                child: _loading
                    ? _buildLoading()
                    : _error != null
                        ? _buildError()
                        : _substitutes.isEmpty
                            ? _buildEmpty()
                            : _buildList(scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoading() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        children: [
          ShimmerBox(
              width: double.infinity, height: 80, borderRadius: 16),
          const SizedBox(height: 10),
          ShimmerBox(
              width: double.infinity, height: 80, borderRadius: 16),
          const SizedBox(height: 10),
          ShimmerBox(
              width: double.infinity, height: 80, borderRadius: 16),
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
                size: 48, color: Color(0xFFDC2626)),
            const SizedBox(height: 16),
            const Text(
              'No se pudieron cargar los sustitutos',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swap_horiz_rounded,
                size: 48, color: Color(0xFFBBBBBB)),
            const SizedBox(height: 16),
            Text(
              _filterByEquipment
                  ? 'No hay sustitutos con tu equipo'
                  : 'No hay sustitutos disponibles',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(ScrollController scrollController) {
    return Stack(
      children: [
        ListView.separated(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          itemCount: _substitutes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final sub = _substitutes[index];
            final name = sub.nameEs?.isNotEmpty == true ? sub.nameEs! : sub.name;
            final muscles = [
              if (sub.primaryMuscle != null) sub.primaryMuscle!,
              if (sub.secondaryMuscles.isNotEmpty)
                sub.secondaryMuscles.first,
            ].join(' · ');
            final equipment = sub.equipmentRequired.isEmpty
                ? 'Sin equipo'
                : sub.equipmentRequired.join(', ');

            return PressableCard(
              color: const Color(0xFFF5F5F5),
              borderRadius: 16,
              onTap: () => _selectSubstitute(sub),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (muscles.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        muscles,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [equipment]
                          .map(
                            (e) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCEEDC),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                e,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (_saving)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x66FFFFFF),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}
