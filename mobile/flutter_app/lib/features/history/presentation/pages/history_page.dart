import 'package:flutter/material.dart';

import '../../../activity/data/services/activity_history_api_service.dart';
import '../../../../shared/widgets/activity_record_detail_sheet.dart';
import '../../../../shared/widgets/app_section_title.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _filter = 'all';
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() {
    return const ActivityHistoryApiService().fetchFilteredHistory(
      filterType: 'all',
    );
  }

  Future<void> _changeFilter(String filter) async {
    setState(() {
      _filter = filter;
      _future = const ActivityHistoryApiService().fetchFilteredHistory(
        filterType: 'all',
      );
    });
    _future = const ActivityHistoryApiService().fetchFilteredHistory(
      filterType: filter,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial completo')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final workouts = data?['workouts'] as List<dynamic>? ?? [];
          final nutrition = data?['nutrition_logs'] as List<dynamic>? ?? [];
          final body = data?['body_metrics'] as List<dynamic>? ?? [];

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
            children: [
              const AppSectionTitle(
                title: 'Explorar historial',
                subtitle:
                    'Filtra por tipo de registro y revisa tu traza completa.',
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: ['all', 'workout', 'nutrition', 'body'].map((filter) {
                  return ChoiceChip(
                    label: Text(filter),
                    selected: _filter == filter,
                    onSelected: (_) => _changeFilter(filter),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              if (workouts.isNotEmpty) ...[
                const AppSectionTitle(title: 'Workout'),
                const SizedBox(height: 12),
                ...workouts.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () =>
                          _showWorkoutDetail(entry as Map<String, dynamic>),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFD8D1C4)),
                        ),
                        child: Text(
                          '${entry['focus']} · ${entry['session_minutes']} min · ${(entry['completed_at']?.toString() ?? '').split('T').first}',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              if (nutrition.isNotEmpty) ...[
                const AppSectionTitle(title: 'Nutricion'),
                const SizedBox(height: 12),
                ...nutrition.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () =>
                          _showNutritionDetail(entry as Map<String, dynamic>),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFD8D1C4)),
                        ),
                        child: Text(
                          '${entry['meal_label']} · ${entry['adherence_score']}% · ${(entry['logged_at']?.toString() ?? '').split('T').first}',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              if (body.isNotEmpty) ...[
                const AppSectionTitle(title: 'Metricas'),
                const SizedBox(height: 12),
                ...body.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () =>
                          _showBodyDetail(entry as Map<String, dynamic>),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFD8D1C4)),
                        ),
                        child: Text(
                          '${entry['weight_kg']} kg · ${(entry['recorded_at']?.toString() ?? '').split('T').first}',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _showWorkoutDetail(Map<String, dynamic> entry) {
    final noteParts = (entry['notes']?.toString() ?? '')
        .split('|')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    showActivityRecordDetailSheet(
      context,
      title: entry['focus']?.toString() ?? 'Sesion workout',
      subtitle: (entry['completed_at']?.toString() ?? '').split('T').first,
      details: [
        MapEntry('Duracion', '${entry['session_minutes'] ?? 0} min'),
        MapEntry('Energia', entry['energy_level']?.toString() ?? '-'),
        if ((entry['day_iso_date']?.toString() ?? '').isNotEmpty)
          MapEntry('Dia del plan', entry['day_iso_date']?.toString() ?? ''),
        ...noteParts
            .take(3)
            .toList()
            .asMap()
            .entries
            .map((item) => MapEntry('Registro ${item.key + 1}', item.value)),
      ],
      notes: noteParts.length > 3 ? noteParts.skip(3).join('\n') : null,
      radius: 10,
    );
  }

  void _showNutritionDetail(Map<String, dynamic> entry) {
    showActivityRecordDetailSheet(
      context,
      title: entry['meal_label']?.toString() ?? 'Registro nutricional',
      subtitle: (entry['logged_at']?.toString() ?? '').split('T').first,
      details: [
        MapEntry('Adherencia', '${entry['adherence_score'] ?? 0}%'),
        MapEntry('Proteina', '${entry['protein_grams'] ?? 0} g'),
        MapEntry('Hidratacion', '${entry['hydration_liters'] ?? 0} L'),
      ],
      notes: entry['notes']?.toString(),
      radius: 10,
    );
  }

  void _showBodyDetail(Map<String, dynamic> entry) {
    showActivityRecordDetailSheet(
      context,
      title: 'Medicion corporal',
      subtitle: (entry['recorded_at']?.toString() ?? '').split('T').first,
      details: [
        MapEntry('Peso', '${entry['weight_kg'] ?? '-'} kg'),
        if (entry['waist_cm'] != null)
          MapEntry('Cintura', '${entry['waist_cm']} cm'),
        if (entry['body_fat_percentage'] != null)
          MapEntry('Grasa corporal', '${entry['body_fat_percentage']} %'),
        if (entry['sleep_hours'] != null)
          MapEntry('Sueño', '${entry['sleep_hours']} h'),
        if (entry['steps'] != null) MapEntry('Pasos', '${entry['steps']}'),
      ],
      radius: 10,
    );
  }
}
