import 'package:flutter/material.dart';

import '../../../activity/data/services/activity_history_api_service.dart';
import '../../../profile/data/services/profile_preferences_store.dart';
import '../../../profile/domain/models/profile_preferences.dart';
import '../../../../shared/widgets/app_section_title.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../../shared/widgets/metric_pill.dart';
import '../../data/services/nutrition_api_service.dart';
import '../../data/services/nutrition_log_api_service.dart';

class NutritionPage extends StatefulWidget {
  const NutritionPage({super.key});

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  late Future<_NutritionViewData> _future;
  double _adherenceScore = 85;
  bool _isSubmitting = false;
  String _dayType = 'Desayuno';
  final TextEditingController _proteinController = TextEditingController(
    text: '140',
  );
  final TextEditingController _hydrationController = TextEditingController(
    text: '3',
  );
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = _loadNutrition();
  }

  @override
  void dispose() {
    _proteinController.dispose();
    _hydrationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<_NutritionViewData> _loadNutrition() async {
    final results = await Future.wait([
      const NutritionApiService().fetchNutritionSummary(),
      const ActivityHistoryApiService().fetchHistory(),
    ]);
    return _NutritionViewData(
      summary: results[0],
      history: results[1],
      preferences: await ProfilePreferencesStore().load(),
    );
  }

  Future<void> _submitNutrition() async {
    final noteController = TextEditingController(text: _notesController.text);
    var adherenceScore = _adherenceScore;
    var hungerLevel = 'Media';
    var satiety = 'Buena';
    var usedSwap = false;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _NutritionSheet(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cerrar registro nutricional',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Deja claro que comida resolviste, como te fue y si hiciste algun ajuste.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _dayType,
                    decoration: const InputDecoration(
                      labelText: 'Comida o momento',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Desayuno', child: Text('Desayuno')),
                      DropdownMenuItem(value: 'Almuerzo', child: Text('Almuerzo')),
                      DropdownMenuItem(value: 'Cena', child: Text('Cena')),
                      DropdownMenuItem(value: 'Snack', child: Text('Snack')),
                      DropdownMenuItem(
                        value: 'Dia completo',
                        child: Text('Dia completo'),
                      ),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        _dayType = value ?? 'Desayuno';
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cumplimiento: ${adherenceScore.round()}%',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Slider(
                    value: adherenceScore,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: adherenceScore.round().toString(),
                    onChanged: (value) {
                      setModalState(() {
                        adherenceScore = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: hungerLevel,
                    decoration: const InputDecoration(
                      labelText: 'Llegaste con hambre',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Alta', child: Text('Alta')),
                      DropdownMenuItem(value: 'Media', child: Text('Media')),
                      DropdownMenuItem(value: 'Baja', child: Text('Baja')),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        hungerLevel = value ?? 'Media';
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: satiety,
                    decoration: const InputDecoration(
                      labelText: 'Como quedaste despues',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Excelente', child: Text('Excelente')),
                      DropdownMenuItem(value: 'Buena', child: Text('Buena')),
                      DropdownMenuItem(value: 'Insuficiente', child: Text('Insuficiente')),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        satiety = value ?? 'Buena';
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: usedSwap,
                    title: const Text('Use una alternativa o sustitucion'),
                    subtitle: const Text('Activalo si no comiste exactamente la opcion sugerida.'),
                    onChanged: (value) {
                      setModalState(() {
                        usedSwap = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Observacion del registro',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Guardar registro'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    final notes = [
      'Hambre: $hungerLevel',
      'Saciedad: $satiety',
      'Sustitucion: ${usedSwap ? 'Si' : 'No'}',
      if (noteController.text.trim().isNotEmpty) noteController.text.trim(),
    ].join(' | ');
    noteController.dispose();

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await const NutritionLogApiService().submitNutrition(
        mealLabel: _dayType,
        adherenceScore: adherenceScore.round(),
        proteinGrams: int.tryParse(_proteinController.text) ?? 140,
        hydrationLiters: int.tryParse(_hydrationController.text) ?? 3,
        notes: notes,
      );
      _notesController.clear();
      setState(() {
        _adherenceScore = adherenceScore;
        _future = _loadNutrition();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nutricion registrada correctamente.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos guardar tu registro.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _editNutrition(Map<String, dynamic> item) async {
    final mealController = TextEditingController(
      text: item['meal_label']?.toString() ?? '',
    );
    final proteinController = TextEditingController(
      text: '${item['protein_grams'] ?? 140}',
    );
    final hydrationController = TextEditingController(
      text: '${item['hydration_liters'] ?? 3}',
    );
    final notesController = TextEditingController(
      text: item['notes']?.toString() ?? '',
    );
    double adherence = (item['adherence_score'] as num?)?.toDouble() ?? 80;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar registro'),
          content: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: mealController,
                    decoration: const InputDecoration(labelText: 'Etiqueta'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: proteinController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Proteina (g)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: hydrationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Hidratacion'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Notas'),
                  ),
                  const SizedBox(height: 12),
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
      mealController.dispose();
      proteinController.dispose();
      hydrationController.dispose();
      notesController.dispose();
      return;
    }

    try {
      await const ActivityHistoryApiService().updateNutrition(
        id: item['id'] as int,
        mealLabel: mealController.text,
        adherenceScore: adherence.round(),
        proteinGrams: int.tryParse(proteinController.text) ?? 140,
        hydrationLiters: int.tryParse(hydrationController.text) ?? 3,
        notes: notesController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _future = _loadNutrition();
      });
    } finally {
      mealController.dispose();
      proteinController.dispose();
      hydrationController.dispose();
      notesController.dispose();
    }
  }

  Future<void> _deleteNutrition(int id) async {
    await const ActivityHistoryApiService().deleteNutrition(id);
    if (!mounted) return;
    setState(() {
      _future = _loadNutrition();
    });
  }

  void _showMealDetail(Map<String, dynamic> item) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(item['title']?.toString() ?? 'Comida'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['meal']?.toString() ?? ''),
                  const SizedBox(height: 12),
                  Text(
                    item['macros']?.toString() ?? '',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (item['objective'] != null) ...[
                    const SizedBox(height: 12),
                    Text('Objetivo: ${item['objective']}'),
                  ],
                  if (item['detail'] != null) ...[
                    const SizedBox(height: 8),
                    Text(item['detail']?.toString() ?? ''),
                  ],
                  if ((item['components'] as List<dynamic>? ?? []).isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Componentes sugeridos',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    ...((item['components'] as List<dynamic>).map(
                      (component) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• ${component.toString()}'),
                      ),
                    )),
                  ],
                  const SizedBox(height: 12),
                  Text(_mealIntent(item['title']?.toString() ?? '')),
                  const SizedBox(height: 8),
                  Text(_mealSwap(item['title']?.toString() ?? '')),
                  if ((item['swap_options'] as List<dynamic>? ?? []).isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Alternativas rapidas',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    ...((item['swap_options'] as List<dynamic>).map(
                      (option) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• ${option.toString()}'),
                      ),
                    )),
                  ],
                  if ((item['weekly_plan'] as List<dynamic>? ?? []).isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Semana para esta comida',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...((item['weekly_plan'] as List<dynamic>).map((entry) {
                      final weekItem = entry as Map<String, dynamic>;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F0E6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${weekItem['day_label']}: ${weekItem['meal_name']}',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(weekItem['detail']?.toString() ?? ''),
                            const SizedBox(height: 4),
                            Text(weekItem['macros']?.toString() ?? ''),
                          ],
                        ),
                      );
                    })),
                  ],
                  if ((item['option_bank'] as List<dynamic>? ?? []).isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Banco de opciones',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...((item['option_bank'] as List<dynamic>).map((entry) {
                      final option = entry as Map<String, dynamic>;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EFE8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option['name']?.toString() ?? '',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(option['summary']?.toString() ?? ''),
                            const SizedBox(height: 4),
                            Text(option['macros']?.toString() ?? ''),
                            const SizedBox(height: 4),
                            Text('Preparacion: ${option['preparation']}'),
                          ],
                        ),
                      );
                    })),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _dayType = item['title']?.toString() ?? 'Desayuno';
                });
                Navigator.of(context).pop();
              },
              child: const Text('Usar para mi registro'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_NutritionViewData>(
      future: _future,
      builder: (context, snapshot) {
        final viewData = snapshot.data;
        final data = viewData?.summary;
        final history = viewData?.history;
        final macros = data?['macro_focus'] as List<dynamic>? ?? [];
        final meals = data?['meals'] as List<dynamic>? ?? [];
        final logs = history?['nutrition_logs'] as List<dynamic>? ?? [];
        final preferences =
            viewData?.preferences ?? ProfilePreferences.defaults();
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
          children: [
            const AppSectionTitle(
              title: 'Nutricion',
              subtitle:
                  'Una estructura simple, flexible y alineada a tu objetivo.',
            ),
            const SizedBox(height: 18),
            AppSurfaceCard(
              backgroundColor: const Color(0xFFE9E2D6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data?['title']?.toString() ?? 'Marco del dia',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    data?['calorie_target']?.toString() ?? '--',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _nutritionCoachPrompt(preferences.coachingStyle),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: macros
                  .map((item) => MetricPill(label: item.toString()))
                  .toList(),
            ),
            const SizedBox(height: 20),
            AppSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Adherencia reciente',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${data?['adherence_score'] ?? 0}%',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hidratacion sugerida: ${_formatHydration(3, preferences.units)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Que vas a registrar ahora?',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _dayType,
                    decoration: const InputDecoration(
                      labelText: 'Comida o momento',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Desayuno',
                        child: Text('Desayuno'),
                      ),
                      DropdownMenuItem(
                        value: 'Almuerzo',
                        child: Text('Almuerzo'),
                      ),
                      DropdownMenuItem(
                        value: 'Cena',
                        child: Text('Cena'),
                      ),
                      DropdownMenuItem(
                        value: 'Snack',
                        child: Text('Snack'),
                      ),
                      DropdownMenuItem(
                        value: 'Dia completo',
                        child: Text('Dia completo'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _dayType = value ?? 'Dia estructurado';
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5ECDD),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      _mealLoggingHint(_dayType),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: _adherenceScore,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: _adherenceScore.round().toString(),
                    onChanged: (value) {
                      setState(() {
                        _adherenceScore = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _proteinController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Proteina (g)',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _hydrationController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Hidratacion (L)',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notas del registro',
                    ),
                    maxLines: 2,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _submitNutrition,
                      child: Text(
                        _isSubmitting
                            ? 'Guardando...'
                            : 'Guardar este registro',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppSurfaceCard(
              backgroundColor: const Color(0xFFE8EFE8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Insight del dia',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(_advancedNutritionInsight(preferences.coachingStyle)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const AppSectionTitle(title: 'Historial nutricional'),
            const SizedBox(height: 12),
            ...(logs.isEmpty
                ? [
                    const AppSurfaceCard(
                      child: Text('Todavia no has registrado dias nutricionales.'),
                    ),
                  ]
                : logs.take(4).map((entry) {
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
                                    item['meal_label']?.toString() ?? '',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${item['adherence_score']}% · ${item['protein_grams']} g proteina',
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
                                  _editNutrition(item);
                                } else if (value == 'delete') {
                                  _deleteNutrition(item['id'] as int);
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
                              (item['logged_at']?.toString() ?? '').split('T').first,
                            ),
                          ],
                        ),
                      ),
                    );
                  })),
            const SizedBox(height: 20),
            const AppSectionTitle(title: 'Comidas sugeridas para hoy'),
            const SizedBox(height: 4),
            Text(
              'Toca una comida para ver el detalle.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ...meals.map((meal) {
              final item = meal as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => _showMealDetail(item),
                  borderRadius: BorderRadius.circular(28),
                  child: AppSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item['title']?.toString() ?? '',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            const Icon(Icons.open_in_full_rounded, size: 18),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatMealDescription(
                            item['meal']?.toString() ?? '',
                            preferences.coachingStyle,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item['macros']?.toString() ?? '',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (item['objective'] != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            item['objective']?.toString() ?? '',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
            AppSurfaceCard(
              backgroundColor: const Color(0xFFF5ECDD),
              child: Text(data?['swap_tip']?.toString() ?? ''),
            ),
          ],
        );
      },
    );
  }
}

class _NutritionViewData {
  const _NutritionViewData({
    required this.summary,
    required this.history,
    required this.preferences,
  });

  final Map<String, dynamic> summary;
  final Map<String, dynamic> history;
  final ProfilePreferences preferences;
}

class _NutritionSheet extends StatelessWidget {
  const _NutritionSheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: child,
        ),
      ),
    );
  }
}

String _formatHydration(int liters, String units) {
  if (units == 'Imperiales') {
    final ounces = liters * 33.8;
    return '${ounces.round()} oz';
  }
  return '$liters L';
}

String _nutritionCoachPrompt(String style) {
  return switch (style) {
    'Exigente' => 'Hoy buscamos estructura limpia, proteina alta y cero improvisacion innecesaria.',
    'Flexible' => 'Prioriza adherencia y equivalencias faciles si tu dia se mueve.',
    _ => 'Mantente en una estructura simple que puedas repetir sin friccion.',
  };
}

String _advancedNutritionInsight(String style) {
  return switch (style) {
    'Exigente' => 'Haz que la primera comida marque el tono del dia: proteina clara, hidratacion y decision rapida.',
    'Flexible' => 'El objetivo no es perfeccion: usa reemplazos simples y conserva la proteina base.',
    _ => 'Mantener regularidad en proteina e hidratacion hoy vale mas que una comida perfecta.',
  };
}

String _formatMealDescription(String meal, String style) {
  return switch (style) {
    'Exigente' => '$meal Mantiene la estructura y evita picoteos reactivos.',
    'Flexible' => '$meal Si no llegas, usa una version equivalente y sigue.',
    _ => '$meal Busca facilidad, saciedad y continuidad.',
  };
}

String _mealLoggingHint(String mealLabel) {
  return switch (mealLabel) {
    'Desayuno' => 'Usa este registro para dejar claro como arrancaste el dia: proteina, hidratacion y sensacion general.',
    'Almuerzo' => 'Registra si esta comida sostuvo bien tu energia y si cumpliste la base de proteina.',
    'Cena' => 'Usa este registro para cerrar el dia sin improvisar demasiado y dejar trazabilidad.',
    'Snack' => 'Ideal para colaciones, puentes de proteina o ajustes cuando el dia se movio.',
    _ => 'Este registro resume tu adherencia global del dia, proteina total e hidratacion.',
  };
}

String _mealIntent(String mealLabel) {
  return switch (mealLabel) {
    'Desayuno' => 'Objetivo: abrir el dia con una comida facil, saciante y con proteina clara.',
    'Almuerzo' => 'Objetivo: sostener energia y evitar decisiones reactivas a media tarde.',
    'Cena' => 'Objetivo: cerrar el dia con calma, saciedad y una digestion simple.',
    _ => 'Objetivo: resolver una comida util sin romper la estructura general.',
  };
}

String _mealSwap(String mealLabel) {
  return switch (mealLabel) {
    'Desayuno' => 'Si no puedes cocinar, usa yogurt griego + fruta + avena o un batido con proteina.',
    'Almuerzo' => 'Si comes fuera, prioriza proteina magra + carbohidrato simple + vegetales.',
    'Cena' => 'Si llegas tarde, usa una cena corta: wrap, huevos o atun con un carbohidrato facil.',
    _ => 'Si la opcion ideal no existe, busca equivalencia en proteina y saciedad.',
  };
}
