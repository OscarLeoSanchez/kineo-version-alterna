import 'package:flutter/material.dart';

import '../../../exercises/data/services/exercise_log_api_service.dart';
import '../../../exercises/domain/models/exercise_log.dart';
import '../../../exercises/presentation/sheets/exercise_detail_sheet.dart';

// ---------------------------------------------------------------------------
// Internal set-row model
// ---------------------------------------------------------------------------

class _SetRow {
  _SetRow({required this.setNumber})
      : repsCtrl = TextEditingController(),
        weightCtrl = TextEditingController(),
        notesCtrl = TextEditingController();

  _SetRow.fromLog(ExerciseLog log)
      : setNumber = log.setNumber,
        repsCtrl =
            TextEditingController(text: log.reps?.toString() ?? ''),
        weightCtrl =
            TextEditingController(text: log.weightKg?.toString() ?? ''),
        notesCtrl = TextEditingController(text: log.notes ?? '');

  final int setNumber;
  final TextEditingController repsCtrl;
  final TextEditingController weightCtrl;
  final TextEditingController notesCtrl;

  void dispose() {
    repsCtrl.dispose();
    weightCtrl.dispose();
    notesCtrl.dispose();
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class WorkoutModeScreen extends StatefulWidget {
  const WorkoutModeScreen({
    super.key,
    required this.exerciseName,
    required this.dayIsoDate,
    this.blockTitle,
  });

  final String exerciseName;
  final String dayIsoDate;
  final String? blockTitle;

  @override
  State<WorkoutModeScreen> createState() => _WorkoutModeScreenState();
}

class _WorkoutModeScreenState extends State<WorkoutModeScreen> {
  final List<_SetRow> _rows = [];
  final _sessionNotesCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  static const int _maxSets = 20;

  @override
  void initState() {
    super.initState();
    _loadExistingLogs();
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    _sessionNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExistingLogs() async {
    try {
      final logs = await const ExerciseLogApiService().getDayLogs(
        widget.dayIsoDate,
        exerciseName: widget.exerciseName,
      );
      if (mounted) {
        setState(() {
          _rows.clear();
          if (logs.isNotEmpty) {
            _rows.addAll(logs.map(_SetRow.fromLog));
          } else {
            _rows.add(_SetRow(setNumber: 1));
          }
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _rows.add(_SetRow(setNumber: 1));
          _loading = false;
        });
      }
    }
  }

  void _addRow() {
    if (_rows.length >= _maxSets) return;
    setState(() {
      _rows.add(_SetRow(setNumber: _rows.length + 1));
    });
  }

  void _removeRow(int index) {
    setState(() {
      _rows[index].dispose();
      _rows.removeAt(index);
      // setNumber is final; row position in list determines display number
    });
  }

  bool _validate() {
    for (final row in _rows) {
      final reps = int.tryParse(row.repsCtrl.text.trim()) ?? 0;
      if (reps <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Las repeticiones deben ser mayores a 0'),
            backgroundColor: Colors.orange,
          ),
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    setState(() => _saving = true);

    int saved = 0;
    String? lastError;

    for (var i = 0; i < _rows.length; i++) {
      final row = _rows[i];
      final reps = int.tryParse(row.repsCtrl.text.trim());
      final weight = double.tryParse(row.weightCtrl.text.trim());
      final notes = row.notesCtrl.text.trim();

      final log = ExerciseLog(
        dayIsoDate: widget.dayIsoDate,
        exerciseName: widget.exerciseName,
        blockTitle: widget.blockTitle,
        setNumber: i + 1,
        reps: reps,
        weightKg: weight,
        notes: notes.isEmpty ? null : notes,
      );

      try {
        await const ExerciseLogApiService().logSet(log);
        saved++;
      } catch (e) {
        lastError = e.toString();
      }
    }

    setState(() => _saving = false);

    if (!mounted) return;

    if (lastError != null && saved == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $lastError'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$saved series registradas'),
          backgroundColor: const Color(0xFF2E7D52),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      const months = [
        '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
      ];
      const days = [
        '', 'Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes',
        'Sabado', 'Domingo',
      ];
      final dow = days[dt.weekday];
      return '$dow ${dt.day} ${months[dt.month]}';
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = [
      _formatDate(widget.dayIsoDate),
      if (widget.blockTitle != null) widget.blockTitle,
    ].join(' · ');

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Registrar: ${widget.exerciseName}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.small(
        tooltip: 'Ver ejercicio',
        onPressed: () => showExerciseDetailSheet(
          context,
          exerciseData: {
            'id': 0,
            'name': widget.exerciseName,
            'is_unilateral': false,
            'secondary_muscles': <String>[],
            'equipment_required': <String>[],
            'equipment_alternatives': <String>[],
            'instructions_es': <String>[],
            'image_urls': <String>[],
            'tags': <String>[],
          },
          dayIsoDate: widget.dayIsoDate,
          blockTitle: widget.blockTitle,
        ),
        child: const Icon(Icons.info_outline_rounded),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    // Table header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: _buildTableHeader(theme),
                      ),
                    ),

                    // Set rows
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: _buildSetRow(context, index, theme),
                        ),
                        childCount: _rows.length,
                      ),
                    ),

                    // Add serie button
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: OutlinedButton.icon(
                          onPressed: _rows.length < _maxSets ? _addRow : null,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Agregar serie'),
                        ),
                      ),
                    ),

                    // Session notes
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: Text(
                          'Notas de la sesion:',
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _sessionNotesCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Escribe notas sobre la sesion...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),

                    // Save button
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 48),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _saving ? null : _save,
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('Guardar sesion'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Saving overlay
                if (_saving)
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

  Widget _buildTableHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              'Serie',
              style: theme.textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Reps',
              style: theme.textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Peso (kg)',
              style: theme.textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          const SizedBox(width: 32), // delete button space
        ],
      ),
    );
  }

  Widget _buildSetRow(BuildContext context, int index, ThemeData theme) {
    final row = _rows[index];
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Set number badge
          Container(
            width: 40,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF143C3A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Reps
          Expanded(
            child: TextField(
              controller: row.repsCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: '—',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Weight
          Expanded(
            child: TextField(
              controller: row.weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: '—',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Delete button
          SizedBox(
            width: 32,
            child: _rows.length > 1
                ? IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Color(0xFFBBBBBB),
                    ),
                    onPressed: () => _removeRow(index),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
