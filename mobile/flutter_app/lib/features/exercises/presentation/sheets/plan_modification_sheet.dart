import 'package:flutter/material.dart';

import '../../data/services/plan_modification_api_service.dart';
import 'exercise_substitute_sheet.dart';

// ---------------------------------------------------------------------------
// Public helper
// ---------------------------------------------------------------------------

void showPlanModificationSheet(
  BuildContext context, {
  required String exerciseName,
  String? dayLabel,
  String? blockTitle,
  VoidCallback? onModified,
  List<String> userEquipment = const [],
  int? exerciseId,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PlanModificationSheet(
      exerciseName: exerciseName,
      dayLabel: dayLabel,
      blockTitle: blockTitle,
      onModified: onModified,
      userEquipment: userEquipment,
      exerciseId: exerciseId,
    ),
  );
}

// ---------------------------------------------------------------------------
// Sheet widget
// ---------------------------------------------------------------------------

class PlanModificationSheet extends StatefulWidget {
  const PlanModificationSheet({
    super.key,
    required this.exerciseName,
    this.dayLabel,
    this.blockTitle,
    this.onModified,
    this.userEquipment = const [],
    this.exerciseId,
  });

  final String exerciseName;
  final String? dayLabel;
  final String? blockTitle;
  final VoidCallback? onModified;
  final List<String> userEquipment;
  final int? exerciseId;

  @override
  State<PlanModificationSheet> createState() => _PlanModificationSheetState();
}

class _PlanModificationSheetState extends State<PlanModificationSheet> {
  bool _editParamsExpanded = false;
  bool _saving = false;

  final _setsCtrl = TextEditingController(text: '3');
  final _repsCtrl = TextEditingController(text: '10');
  final _restCtrl = TextEditingController(text: '60');

  @override
  void dispose() {
    _setsCtrl.dispose();
    _repsCtrl.dispose();
    _restCtrl.dispose();
    super.dispose();
  }

  Future<void> _postModification(Map<String, dynamic> data) async {
    setState(() => _saving = true);
    try {
      await const PlanModificationApiService().createModification(data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _saving = false);
      return;
    }
    setState(() => _saving = false);
  }

  Future<void> _saveEditParams() async {
    final sets = _setsCtrl.text.trim();
    final reps = _repsCtrl.text.trim();
    final rest = _restCtrl.text.trim();
    await _postModification({
      'modification_type': 'edit_params',
      'target_type': 'exercise',
      if (widget.dayLabel != null) 'target_day_label': widget.dayLabel,
      if (widget.blockTitle != null) 'target_block_title': widget.blockTitle,
      'target_item_name': widget.exerciseName,
      'override_json': '{"sets": "$sets series", "reps": "$reps", "rest": "$rest seg"}',
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cambios guardados'),
          backgroundColor: Color(0xFF2E7D52),
        ),
      );
      widget.onModified?.call();
      Navigator.of(context).pop();
    }
  }

  Future<void> _exclude() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir ejercicio'),
        content: Text(
          '¿Seguro que quieres excluir ${widget.exerciseName} de tu plan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await _postModification({
      'modification_type': 'exclude',
      'target_type': 'exercise',
      if (widget.dayLabel != null) 'target_day_label': widget.dayLabel,
      if (widget.blockTitle != null) 'target_block_title': widget.blockTitle,
      'target_item_name': widget.exerciseName,
      'override_json': '{}',
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ejercicio excluido'),
          backgroundColor: Color(0xFF2E7D52),
        ),
      );
      widget.onModified?.call();
      Navigator.of(context).pop();
    }
  }

  Future<void> _addNote() async {
    final ctrl = TextEditingController();
    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nota para el coach'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Escribe una nota sobre este ejercicio...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (saved == null || saved.isEmpty || !mounted) return;

    await _postModification({
      'modification_type': 'add_note',
      'target_type': 'exercise',
      if (widget.dayLabel != null) 'target_day_label': widget.dayLabel,
      if (widget.blockTitle != null) 'target_block_title': widget.blockTitle,
      'target_item_name': widget.exerciseName,
      'override_json': '{}',
      'note_text': saved,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nota guardada'),
          backgroundColor: Color(0xFF2E7D52),
        ),
      );
      widget.onModified?.call();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      color: theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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

              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: Text(
                  'Modificar ejercicio',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Text(
                  widget.exerciseName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),

              // Options
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        // 1 — Cambiar por otro
                        _OptionTile(
                          icon: Icons.swap_horiz_rounded,
                          label: 'Cambiar por otro',
                          onTap: () {
                            Navigator.of(context).pop();
                            if (widget.exerciseId != null) {
                              showExerciseSubstituteSheet(
                                context,
                                exerciseId: widget.exerciseId!,
                                exerciseName: widget.exerciseName,
                                userEquipment: widget.userEquipment,
                                onSubstituteSelected: (_) =>
                                    widget.onModified?.call(),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 8),

                        // 2 — Editar series/reps (expandable)
                        _OptionTile(
                          icon: Icons.edit_rounded,
                          label: 'Editar series/reps',
                          trailing: Icon(
                            _editParamsExpanded
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                          ),
                          onTap: () => setState(
                              () => _editParamsExpanded = !_editParamsExpanded),
                        ),
                        if (_editParamsExpanded) ...[
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _ParamField(
                                        controller: _setsCtrl,
                                        label: 'Series',
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _ParamField(
                                        controller: _repsCtrl,
                                        label: 'Reps',
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _ParamField(
                                        controller: _restCtrl,
                                        label: 'Descanso (s)',
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: _saving ? null : _saveEditParams,
                                    child: const Text('Guardar cambios'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),

                        // 3 — Excluir
                        _OptionTile(
                          icon: Icons.block_rounded,
                          label: 'Excluir de mi plan',
                          destructive: true,
                          onTap: _saving ? null : _exclude,
                        ),
                        const SizedBox(height: 8),

                        // 4 — Agregar nota
                        _OptionTile(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: 'Agregar nota al coach',
                          onTap: _saving ? null : _addNote,
                        ),
                      ],
                    ),
                    if (_saving)
                      const Positioned.fill(
                        child: ColoredBox(
                          color: Color(0x55FFFFFF),
                          child: Center(child: CircularProgressIndicator()),
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
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.destructive = false,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool destructive;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final color =
        destructive ? const Color(0xFFDC2626) : Theme.of(context).colorScheme.onSurface;
    return Material(
      color: const Color(0xFFF5F5F5),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class _ParamField extends StatelessWidget {
  const _ParamField({
    required this.controller,
    required this.label,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        isDense: true,
      ),
    );
  }
}
