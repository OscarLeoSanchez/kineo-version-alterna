import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../activity/data/services/activity_history_api_service.dart';
import '../../../../shared/widgets/app_section_title.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/loading_button.dart';
import '../../../../shared/widgets/series_bar_chart.dart';
import '../../data/services/body_metric_api_service.dart';
import '../../data/services/progress_api_service.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  late Future<_ProgressViewData> _future;
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _waistController = TextEditingController();
  final TextEditingController _bodyFatController = TextEditingController();
  final TextEditingController _hipController = TextEditingController();
  final TextEditingController _chestController = TextEditingController();
  final TextEditingController _armController = TextEditingController();
  final TextEditingController _thighController = TextEditingController();
  final TextEditingController _muscleMassController = TextEditingController();
  final TextEditingController _sleepController = TextEditingController();
  final TextEditingController _stepsController = TextEditingController();
  final TextEditingController _restingHeartRateController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  // Optional extra body measurements
  final TextEditingController _neckController = TextEditingController();
  final TextEditingController _calfController = TextEditingController();
  final TextEditingController _forearmController = TextEditingController();
  final TextEditingController _backController = TextEditingController();
  // Energy and mood replaced with chip selectors (null = not selected)
  int? _selectedEnergy;
  int? _selectedMood;
  // Which optional measurement fields to show
  bool _showNeck = false;
  bool _showCalf = false;
  bool _showForearm = false;
  bool _showBack = false;
  bool _isSubmitting = false;
  String _selectedPreset = 'Peso';

  @override
  void initState() {
    super.initState();
    _future = _loadProgress();
  }

  Future<_ProgressViewData> _loadProgress() async {
    final results = await Future.wait([
      const ProgressApiService().fetchProgressSummary(),
      const ActivityHistoryApiService().fetchHistory(),
    ]);
    return _ProgressViewData(
      summary: results[0],
      history: results[1],
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _waistController.dispose();
    _bodyFatController.dispose();
    _hipController.dispose();
    _chestController.dispose();
    _armController.dispose();
    _thighController.dispose();
    _muscleMassController.dispose();
    _sleepController.dispose();
    _stepsController.dispose();
    _restingHeartRateController.dispose();
    _notesController.dispose();
    _neckController.dispose();
    _calfController.dispose();
    _forearmController.dispose();
    _backController.dispose();
    super.dispose();
  }

  Future<void> _submitMetric() async {
    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    final waist = double.tryParse(_waistController.text.replaceAll(',', '.'));
    final bodyFat = double.tryParse(_bodyFatController.text.replaceAll(',', '.'));
    final hip = double.tryParse(_hipController.text.replaceAll(',', '.'));
    final chest = double.tryParse(_chestController.text.replaceAll(',', '.'));
    final arm = double.tryParse(_armController.text.replaceAll(',', '.'));
    final thigh = double.tryParse(_thighController.text.replaceAll(',', '.'));
    final muscleMass = double.tryParse(_muscleMassController.text.replaceAll(',', '.'));
    final sleep = double.tryParse(_sleepController.text.replaceAll(',', '.'));
    final energy = _selectedEnergy;
    final mood = _selectedMood;
    final steps = int.tryParse(_stepsController.text);
    final restingHeartRate = int.tryParse(_restingHeartRateController.text);
    final notes = _notesController.text.trim();

    if (weight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un peso valido.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await const BodyMetricApiService().submitMetric(
        weightKg: weight,
        waistCm: waist,
        bodyFatPct: bodyFat,
        hipsCm: hip,
        chestCm: chest,
        armCm: arm,
        thighCm: thigh,
        muscleMassKg: muscleMass,
        sleepHours: sleep,
        energyLevel: energy,
        moodScore: mood,
        steps: steps,
        restingHeartRate: restingHeartRate,
        notes: notes.isNotEmpty ? notes : null,
        neckCm: double.tryParse(_neckController.text.replaceAll(',', '.')),
        calfCm: double.tryParse(_calfController.text.replaceAll(',', '.')),
        forearmCm: double.tryParse(_forearmController.text.replaceAll(',', '.')),
        backCm: double.tryParse(_backController.text.replaceAll(',', '.')),
      );
      _weightController.clear();
      _waistController.clear();
      _bodyFatController.clear();
      _hipController.clear();
      _chestController.clear();
      _armController.clear();
      _thighController.clear();
      _muscleMassController.clear();
      _sleepController.clear();
      _stepsController.clear();
      _restingHeartRateController.clear();
      _notesController.clear();
      _neckController.clear();
      _calfController.clear();
      _forearmController.clear();
      _backController.clear();
      setState(() {
        _selectedEnergy = null;
        _selectedMood = null;
        _future = _loadProgress();
      });
      if (!mounted) return;
      // Build a summary of what was submitted
      final parts = <String>['peso ${weight}kg'];
      if (waist != null) parts.add('cintura ${waist}cm');
      if (hip != null) parts.add('cadera ${hip}cm');
      if (chest != null) parts.add('pecho ${chest}cm');
      if (bodyFat != null) parts.add('grasa ${bodyFat}%');
      if (muscleMass != null) parts.add('musculo ${muscleMass}kg');
      if (sleep != null) parts.add('sueño ${sleep}h');
      if (energy != null) parts.add('energia $energy/10');
      if (mood != null) parts.add('animo $mood/10');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registrado: ${parts.join(', ')}')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos registrar la metrica.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _applyPreset(String preset) {
    setState(() {
      _selectedPreset = preset;
    });
    switch (preset) {
      case 'Peso':
        _waistController.clear();
        _bodyFatController.clear();
        _hipController.clear();
        _chestController.clear();
        _armController.clear();
        _thighController.clear();
        _sleepController.clear();
        _stepsController.clear();
        _restingHeartRateController.clear();
        break;
      case 'Composicion':
        _sleepController.clear();
        _stepsController.clear();
        _restingHeartRateController.clear();
        break;
      case 'Recuperacion':
        _waistController.clear();
        _bodyFatController.clear();
        _hipController.clear();
        _chestController.clear();
        _armController.clear();
        _thighController.clear();
        break;
    }
  }

  Future<void> _editMetric(Map<String, dynamic> item) async {
    final weightController = TextEditingController(
      text: '${item['weight_kg'] ?? ''}',
    );
    final waistController = TextEditingController(
      text: item['waist_cm']?.toString() ?? '',
    );
    final bodyFatController = TextEditingController(
      text: item['body_fat_percentage']?.toString() ?? '',
    );
    final hipController = TextEditingController(
      text: item['hip_cm']?.toString() ?? '',
    );
    final chestController = TextEditingController(
      text: item['chest_cm']?.toString() ?? '',
    );
    final armController = TextEditingController(
      text: item['arm_cm']?.toString() ?? '',
    );
    final thighController = TextEditingController(
      text: item['thigh_cm']?.toString() ?? '',
    );
    final sleepController = TextEditingController(
      text: item['sleep_hours']?.toString() ?? '',
    );
    final stepsController = TextEditingController(
      text: item['steps']?.toString() ?? '',
    );
    final restingHeartRateController = TextEditingController(
      text: item['resting_heart_rate']?.toString() ?? '',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar metrica'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Peso (kg)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: waistController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Cintura (cm)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bodyFatController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Grasa corporal (%)'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: hipController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'Cadera (cm)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: chestController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'Pecho (cm)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: armController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'Brazo (cm)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: thighController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'Muslo (cm)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: sleepController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'Sueño (h)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: stepsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Pasos'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: restingHeartRateController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Frecuencia cardiaca en reposo',
                  ),
                ),
              ],
            ),
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

    try {
      await const ActivityHistoryApiService().updateBodyMetric(
        id: item['id'] as int,
        weightKg:
            double.tryParse(weightController.text.replaceAll(',', '.')) ??
            ((item['weight_kg'] as num?)?.toDouble() ?? 0),
        waistCm: double.tryParse(waistController.text.replaceAll(',', '.')),
        bodyFatPercentage: double.tryParse(bodyFatController.text.replaceAll(',', '.')),
        hipCm: double.tryParse(hipController.text.replaceAll(',', '.')),
        chestCm: double.tryParse(chestController.text.replaceAll(',', '.')),
        armCm: double.tryParse(armController.text.replaceAll(',', '.')),
        thighCm: double.tryParse(thighController.text.replaceAll(',', '.')),
        sleepHours: double.tryParse(sleepController.text.replaceAll(',', '.')),
        steps: int.tryParse(stepsController.text),
        restingHeartRate: int.tryParse(restingHeartRateController.text),
      );
      if (!mounted) return;
      setState(() {
        _future = _loadProgress();
      });
    } finally {
      weightController.dispose();
      waistController.dispose();
      bodyFatController.dispose();
      hipController.dispose();
      chestController.dispose();
      armController.dispose();
      thighController.dispose();
      sleepController.dispose();
      stepsController.dispose();
      restingHeartRateController.dispose();
    }
  }

  Future<void> _deleteMetric(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('¿Eliminar este registro?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    await const ActivityHistoryApiService().deleteBodyMetric(id);
    if (!mounted) return;
    setState(() {
      _future = _loadProgress();
    });
  }

  Widget _buildPresetAwareForm(Map<String, dynamic>? data) {
    switch (_selectedPreset) {
      case 'Composicion':
        return Column(
          children: [
            _MetricGroup(
              title: 'Basicas',
              subtitle: 'Peso, cintura y grasa para seguir cambios de composicion.',
              children: [
                TextField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Peso actual (kg)',
                    hintText: data?['latest_weight_kg']?.toString() ?? '79.8',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _waistController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Cintura (cm)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _bodyFatController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Grasa corporal (%)'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _MetricGroup(
              title: 'Medidas corporales',
              subtitle: 'Ideal si quieres seguir volumen y simetria.',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _hipController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Cadera (cm)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _chestController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Pecho (cm)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _armController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Brazo (cm)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _thighController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Muslo (cm)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // ── Optional extra measurements ──────────────────────────
                Text(
                  'Medidas adicionales',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('+ Cuello'),
                      selected: _showNeck,
                      onSelected: (v) => setState(() {
                        _showNeck = v;
                        if (!v) _neckController.clear();
                      }),
                    ),
                    FilterChip(
                      label: const Text('+ Pantorrilla'),
                      selected: _showCalf,
                      onSelected: (v) => setState(() {
                        _showCalf = v;
                        if (!v) _calfController.clear();
                      }),
                    ),
                    FilterChip(
                      label: const Text('+ Antebrazo'),
                      selected: _showForearm,
                      onSelected: (v) => setState(() {
                        _showForearm = v;
                        if (!v) _forearmController.clear();
                      }),
                    ),
                    FilterChip(
                      label: const Text('+ Espalda'),
                      selected: _showBack,
                      onSelected: (v) => setState(() {
                        _showBack = v;
                        if (!v) _backController.clear();
                      }),
                    ),
                  ],
                ),
                if (_showNeck || _showCalf || _showForearm || _showBack) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      if (_showNeck)
                        SizedBox(
                          width: 140,
                          child: TextField(
                            controller: _neckController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Cuello (cm)'),
                          ),
                        ),
                      if (_showCalf)
                        SizedBox(
                          width: 140,
                          child: TextField(
                            controller: _calfController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Pantorrilla (cm)'),
                          ),
                        ),
                      if (_showForearm)
                        SizedBox(
                          width: 140,
                          child: TextField(
                            controller: _forearmController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Antebrazo (cm)'),
                          ),
                        ),
                      if (_showBack)
                        SizedBox(
                          width: 140,
                          child: TextField(
                            controller: _backController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Espalda (cm)'),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        );
      case 'Recuperacion':
        return _MetricGroup(
          title: 'Recuperacion y bio-senales',
          subtitle: 'Sirve para relacionar progreso con descanso, actividad y carga.',
          children: [
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Peso actual (kg)',
                hintText: data?['latest_weight_kg']?.toString() ?? '79.8',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sleepController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Sueño (h)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _stepsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Pasos'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _restingHeartRateController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Frecuencia cardiaca en reposo',
              ),
            ),
            const SizedBox(height: 16),
            // ── Energy level chips ────────────────────────────────────────
            Text(
              'Nivel de energía',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            _EnergyMoodChips(
              options: const [
                _ChipOption(label: '😔 1–2', value: 1),
                _ChipOption(label: '😐 3–4', value: 3),
                _ChipOption(label: '😊 5–6', value: 5),
                _ChipOption(label: '😄 7–8', value: 7),
                _ChipOption(label: '🤩 9–10', value: 9),
              ],
              selected: _selectedEnergy,
              onSelected: (v) => setState(() => _selectedEnergy = v),
            ),
            const SizedBox(height: 14),
            // ── Mood score chips ──────────────────────────────────────────
            Text(
              'Estado de ánimo',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            _EnergyMoodChips(
              options: const [
                _ChipOption(label: '😔 1–2', value: 1),
                _ChipOption(label: '😐 3–4', value: 3),
                _ChipOption(label: '😊 5–6', value: 5),
                _ChipOption(label: '😄 7–8', value: 7),
                _ChipOption(label: '🤩 9–10', value: 9),
              ],
              selected: _selectedMood,
              onSelected: (v) => setState(() => _selectedMood = v),
            ),
          ],
        );
      default:
        return _MetricGroup(
          title: 'Basicas',
          subtitle: 'Lo minimo para seguir tendencia general.',
          children: [
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Peso actual (kg)',
                hintText: data?['latest_weight_kg']?.toString() ?? '79.8',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _waistController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Cintura (cm)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _bodyFatController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Grasa corporal (%)'),
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ProgressViewData>(
      future: _future,
      builder: (context, snapshot) {
        final viewData = snapshot.data;
        final data = viewData?.summary;
        final history = viewData?.history;
        final insights = data?['insights'] as List<dynamic>? ?? [];
        final weightSeries = data?['weight_series'] as List<dynamic>? ?? [];
        final adherenceSeries = data?['adherence_series'] as List<dynamic>? ?? [];
        final bodyMetrics = history?['body_metrics'] as List<dynamic>? ?? [];
        final latestMetric = bodyMetrics.isNotEmpty
            ? bodyMetrics.first as Map<String, dynamic>
            : null;
        final previousMetric = bodyMetrics.length > 1
            ? bodyMetrics[1] as Map<String, dynamic>
            : null;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
          children: [
            const AppSectionTitle(
              title: 'Progreso',
              subtitle: 'Señales de adherencia, tendencia y consistencia.',
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A34),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Racha activa',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${data?['streak_days'] ?? 0} dias siguiendo tu sistema',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _MetricStat(
                    value: '${data?['weekly_adherence'] ?? 0}%',
                    label: 'Adherencia',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricStat(
                    value: '${data?['workout_completion_rate'] ?? 0}%',
                    label: 'Cumplimiento',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _MetricStat(
              value: data?['weight_trend']?.toString() ?? '--',
              label: 'Tendencia',
            ),
            const SizedBox(height: 12),
            _MetricStat(
              value:
                  '${data?['completed_sessions'] ?? 0}/${data?['weekly_workout_target'] ?? 0}',
              label: 'Sesiones / meta',
            ),
            const SizedBox(height: 20),
            // ── T-17 — Tendencias semanales ─────────────────────────────────
            const AppSectionTitle(
              title: 'Mis Tendencias',
              subtitle: 'Ultimos 7 dias — adherencia, sesiones y peso.',
            ),
            const SizedBox(height: 12),
            _WeeklyTrendsSection(history: history),
            const SizedBox(height: 20),
            AppSurfaceCard(
              backgroundColor: const Color(0xFFF5ECDD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Check-in rapido',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Elige el tipo de registro que quieres hacer hoy y te dejamos solo lo necesario.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _PresetChip(
                        label: 'Peso',
                        selected: _selectedPreset == 'Peso',
                        onTap: () => _applyPreset('Peso'),
                      ),
                      _PresetChip(
                        label: 'Composicion',
                        selected: _selectedPreset == 'Composicion',
                        onTap: () => _applyPreset('Composicion'),
                      ),
                      _PresetChip(
                        label: 'Recuperacion',
                        selected: _selectedPreset == 'Recuperacion',
                        onTap: () => _applyPreset('Recuperacion'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Registrar check-in corporal',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No necesitas llenar todo. Elige las senales que quieras seguir hoy.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  _buildPresetAwareForm(data),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: LoadingButton(
                      label: 'Guardar check-in',
                      isLoading: _isSubmitting,
                      onPressed: _isSubmitting ? null : _submitMetric,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (latestMetric != null) ...[
              const AppSectionTitle(title: 'Comparativa rapida'),
              const SizedBox(height: 12),
              AppSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ultimo check-in vs anterior',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    ..._comparisonRows(latestMetric, previousMetric).map(
                      (row) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(row),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            const AppSectionTitle(title: 'Serie de peso'),
            const SizedBox(height: 12),
            AppSurfaceCard(
              child: SeriesBarChart(points: weightSeries.cast<Map<String, dynamic>>(), suffix: ' kg'),
            ),
            const SizedBox(height: 20),
            const AppSectionTitle(title: 'Adherencia semanal'),
            const SizedBox(height: 12),
            AppSurfaceCard(
              child: SeriesBarChart(points: adherenceSeries.cast<Map<String, dynamic>>(), suffix: '%'),
            ),
            const SizedBox(height: 20),
            const AppSectionTitle(title: 'Historial corporal'),
            const SizedBox(height: 12),
            ...(bodyMetrics.isEmpty
                ? [
                    const AppSurfaceCard(
                      child: EmptyStateWidget(
                        icon: Icons.show_chart_rounded,
                        title: 'Sin datos de progreso',
                        subtitle:
                            'Registra tu peso y métricas para ver tu evolución aquí.',
                        compact: true,
                      ),
                    ),
                  ]
                : bodyMetrics.take(4).map((entry) {
                    final item = entry as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppSurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${item['weight_kg']} kg',
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _metricSummary(item),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _editMetric(item);
                                    } else if (value == 'delete') {
                                      _deleteMetric(item['id'] as int);
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
                                  (item['recorded_at']?.toString() ?? '').split('T').first,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _metricTags(item)
                                  .map((entry) => Chip(label: Text(entry)))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    );
                  })),
            const SizedBox(height: 8),
            ...insights.map((entry) {
              final item = entry as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title']?.toString() ?? '',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(item['note']?.toString() ?? ''),
                    ],
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
  }
}

class _ProgressViewData {
  const _ProgressViewData({
    required this.summary,
    required this.history,
  });

  final Map<String, dynamic> summary;
  final Map<String, dynamic> history;
}

class _MetricStat extends StatelessWidget {
  const _MetricStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _MetricGroup extends StatelessWidget {
  const _MetricGroup({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F1E8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

String _metricSummary(Map<String, dynamic> item) {
  final fragments = <String>[];
  if (item['waist_cm'] != null) {
    fragments.add('Cintura ${item['waist_cm']} cm');
  }
  if (item['body_fat_percentage'] != null) {
    fragments.add('Grasa ${item['body_fat_percentage']}%');
  }
  if (fragments.isEmpty) {
    return 'Check-in basico guardado';
  }
  return fragments.join(' · ');
}

List<String> _metricTags(Map<String, dynamic> item) {
  final tags = <String>[];
  if (item['hip_cm'] != null) {
    tags.add('Cadera ${item['hip_cm']} cm');
  }
  if (item['chest_cm'] != null) {
    tags.add('Pecho ${item['chest_cm']} cm');
  }
  if (item['arm_cm'] != null) {
    tags.add('Brazo ${item['arm_cm']} cm');
  }
  if (item['thigh_cm'] != null) {
    tags.add('Muslo ${item['thigh_cm']} cm');
  }
  if (item['sleep_hours'] != null) {
    tags.add('Sueno ${item['sleep_hours']} h');
  }
  if (item['steps'] != null) {
    tags.add('Pasos ${item['steps']}');
  }
  if (item['resting_heart_rate'] != null) {
    tags.add('FCR ${item['resting_heart_rate']}');
  }
  return tags;
}

List<String> _comparisonRows(
  Map<String, dynamic> latest,
  Map<String, dynamic>? previous,
) {
  if (previous == null) {
    return ['Este es tu primer check-in completo. A partir del siguiente veras comparativas.'];
  }

  final rows = <String>[];
  rows.add(_comparisonText('Peso', latest['weight_kg'], previous['weight_kg'], 'kg'));
  if (latest['waist_cm'] != null && previous['waist_cm'] != null) {
    rows.add(_comparisonText('Cintura', latest['waist_cm'], previous['waist_cm'], 'cm'));
  }
  if (latest['body_fat_percentage'] != null && previous['body_fat_percentage'] != null) {
    rows.add(
      _comparisonText(
        'Grasa corporal',
        latest['body_fat_percentage'],
        previous['body_fat_percentage'],
        '%',
      ),
    );
  }
  if (latest['sleep_hours'] != null && previous['sleep_hours'] != null) {
    rows.add(_comparisonText('Sueno', latest['sleep_hours'], previous['sleep_hours'], 'h'));
  }
  if (latest['resting_heart_rate'] != null && previous['resting_heart_rate'] != null) {
    rows.add(
      _comparisonText(
        'FCR',
        latest['resting_heart_rate'],
        previous['resting_heart_rate'],
        'ppm',
      ),
    );
  }
  return rows;
}

String _comparisonText(String label, dynamic latest, dynamic previous, String suffix) {
  final latestValue = (latest as num).toDouble();
  final previousValue = (previous as num).toDouble();
  final delta = latestValue - previousValue;
  final direction = delta == 0
      ? 'sin cambio'
      : delta > 0
          ? '+${delta.toStringAsFixed(1)}'
          : delta.toStringAsFixed(1);
  if (delta == 0) {
    return '$label: estable en ${latestValue.toStringAsFixed(1)} $suffix';
  }
  return '$label: ${latestValue.toStringAsFixed(1)} $suffix ($direction $suffix vs registro anterior)';
}

// ─── T-17 — Sección de tendencias semanales ───────────────────────────────────

class _WeeklyTrendsSection extends StatelessWidget {
  const _WeeklyTrendsSection({required this.history});

  final Map<String, dynamic>? history;

  static const _dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  List<Map<String, dynamic>> _buildNutritionPoints() {
    final logs = (history?['nutrition_logs'] as List<dynamic>? ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList();
    final today = DateTime.now();
    final points = <Map<String, dynamic>>[];
    for (var i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final iso = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final dayLogs = logs.where((e) {
        final loggedAt = e['logged_at']?.toString() ?? '';
        return loggedAt.startsWith(iso);
      }).toList();
      double adherence = 0;
      if (dayLogs.isNotEmpty) {
        final sum = dayLogs.fold<double>(
          0,
          (acc, log) => acc + ((log['adherence_score'] as num?)?.toDouble() ?? 0),
        );
        adherence = sum / dayLogs.length;
      }
      final weekdayIndex = day.weekday - 1; // Mon=0 .. Sun=6
      points.add({'label': _dayLabels[weekdayIndex], 'value': adherence});
    }
    return points;
  }

  List<Map<String, dynamic>> _buildWorkoutPoints() {
    final workouts = (history?['workouts'] as List<dynamic>? ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList();
    final today = DateTime.now();
    final points = <Map<String, dynamic>>[];
    for (var i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final iso = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final hasSession = workouts.any((e) {
        final completedAt = e['completed_at']?.toString() ?? '';
        return completedAt.startsWith(iso);
      });
      final weekdayIndex = day.weekday - 1;
      points.add({'label': _dayLabels[weekdayIndex], 'value': hasSession ? 1.0 : 0.0});
    }
    return points;
  }

  List<Map<String, dynamic>> _buildWeightPoints() {
    final metrics = (history?['body_metrics'] as List<dynamic>? ?? [])
        .map((e) => e as Map<String, dynamic>)
        .where((e) => e['weight_kg'] != null)
        .toList();
    final today = DateTime.now();
    final points = <Map<String, dynamic>>[];
    for (var i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final iso = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final dayMetric = metrics.firstWhere(
        (e) => (e['recorded_at']?.toString() ?? '').startsWith(iso),
        orElse: () => const <String, dynamic>{},
      );
      if (dayMetric.isNotEmpty) {
        final weekdayIndex = day.weekday - 1;
        points.add({
          'label': _dayLabels[weekdayIndex],
          'value': (dayMetric['weight_kg'] as num).toDouble(),
        });
      }
    }
    return points;
  }

  Color _adherenceBarColor(double value) {
    if (value >= 80) return const Color(0xFF2E7D52);
    if (value >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFDC2626);
  }

  @override
  Widget build(BuildContext context) {
    final nutritionPoints = _buildNutritionPoints();
    final workoutPoints = _buildWorkoutPoints();
    final weightPoints = _buildWeightPoints();
    final hasWeightData = weightPoints.length >= 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Adherencia nutricional ──
        AppSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Adherencia nutricional — 7 dias',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Verde ≥80 · Ambar 50–79 · Rojo <50',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: nutritionPoints.map((entry) {
                    final value = (entry['value'] as num?)?.toDouble() ?? 0;
                    final label = entry['label']?.toString() ?? '';
                    final factor = value <= 0 ? 0.05 : (value / 100).clamp(0.05, 1.0);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              value > 0 ? '${value.round()}%' : '',
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 84 * factor,
                              decoration: BoxDecoration(
                                color: _adherenceBarColor(value),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              label,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Sesiones de workout ──
        AppSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sesiones completadas',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 100,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: workoutPoints.map((entry) {
                    final value = (entry['value'] as num?)?.toDouble() ?? 0;
                    final label = entry['label']?.toString() ?? '';
                    final hasSession = value >= 1;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              height: hasSession ? 64 : 10,
                              decoration: BoxDecoration(
                                color: hasSession
                                    ? const Color(0xFF0D9488)
                                    : const Color(0xFFD1D5DB),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              label,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Peso ──
        AppSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Registro de peso (kg)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (!hasWeightData)
                Text(
                  'Registra tu peso diariamente para ver la tendencia.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                  ),
                )
              else
                SizedBox(
                  height: 120,
                  child: CustomPaint(
                    painter: _WeightLinePainter(points: weightPoints),
                    size: Size.infinite,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeightLinePainter extends CustomPainter {
  const _WeightLinePainter({required this.points});

  final List<Map<String, dynamic>> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final values = points
        .map((e) => (e['value'] as num).toDouble())
        .toList();
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final range = (maxVal - minVal).clamp(0.5, double.infinity);

    final linePaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.fill;

    final textStyle = const TextStyle(
      color: Color(0xFF374151),
      fontSize: 10,
    );

    final path = Path();
    final n = points.length;
    for (var i = 0; i < n; i++) {
      final x = size.width * i / (n - 1);
      final normalized = (values[i] - minVal) / range;
      final y = size.height * 0.85 - normalized * size.height * 0.7;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 4, dotPaint);

      // Label
      final tp = TextPainter(
        text: TextSpan(text: values[i].toStringAsFixed(1), style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - 18));

      // Day label
      final label = points[i]['label']?.toString() ?? '';
      final tp2 = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp2.paint(canvas, Offset(x - tp2.width / 2, size.height - tp2.height));
    }

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _WeightLinePainter oldDelegate) =>
      oldDelegate.points != points;
}

// ─── Energy / Mood chip selector helpers ──────────────────────────────────────

class _ChipOption {
  final String label;
  final int value;

  const _ChipOption({required this.label, required this.value});
}

class _EnergyMoodChips extends StatelessWidget {
  const _EnergyMoodChips({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<_ChipOption> options;
  final int? selected;
  final void Function(int?) onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = selected == opt.value;
        return GestureDetector(
          onTap: () => onSelected(isSelected ? null : opt.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.neutral,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              opt.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
