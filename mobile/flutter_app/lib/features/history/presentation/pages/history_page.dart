import 'package:flutter/material.dart';

import '../../../activity/data/services/activity_history_api_service.dart';
import '../../../../shared/widgets/app_section_title.dart';
import '../../../../shared/widgets/app_surface_card.dart';

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
                subtitle: 'Filtra por tipo de registro y revisa tu traza completa.',
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
                ...workouts.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppSurfaceCard(
                        child: Text(
                          '${entry['focus']} · ${entry['session_minutes']} min · ${(entry['completed_at']?.toString() ?? '').split('T').first}',
                        ),
                      ),
                    )),
              ],
              if (nutrition.isNotEmpty) ...[
                const AppSectionTitle(title: 'Nutricion'),
                const SizedBox(height: 12),
                ...nutrition.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppSurfaceCard(
                        child: Text(
                          '${entry['meal_label']} · ${entry['adherence_score']}% · ${(entry['logged_at']?.toString() ?? '').split('T').first}',
                        ),
                      ),
                    )),
              ],
              if (body.isNotEmpty) ...[
                const AppSectionTitle(title: 'Metricas'),
                const SizedBox(height: 12),
                ...body.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppSurfaceCard(
                        child: Text(
                          '${entry['weight_kg']} kg · ${(entry['recorded_at']?.toString() ?? '').split('T').first}',
                        ),
                      ),
                    )),
              ],
            ],
          );
        },
      ),
    );
  }
}
