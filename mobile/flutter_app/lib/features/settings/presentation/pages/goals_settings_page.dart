import 'package:flutter/material.dart';

import '../../../goals/data/services/goals_api_service.dart';
import '../../../reports/data/services/reports_api_service.dart';
import '../../../../core/services/local_notification_service.dart';
import '../../../../shared/widgets/app_section_title.dart';
import '../../../../shared/widgets/app_surface_card.dart';

class GoalsSettingsPage extends StatefulWidget {
  const GoalsSettingsPage({super.key});

  @override
  State<GoalsSettingsPage> createState() => _GoalsSettingsPageState();
}

class _GoalsSettingsPageState extends State<GoalsSettingsPage> {
  final _workoutController = TextEditingController();
  final _nutritionController = TextEditingController();
  final _weightController = TextEditingController();
  final _timeController = TextEditingController();
  bool _remindersEnabled = true;
  bool _loading = true;
  bool _saving = false;
  String? _reportMarkdown;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final goal = await const GoalsApiService().fetchCurrentGoal();
    _workoutController.text = '${goal['workout_sessions_target']}';
    _nutritionController.text = '${goal['nutrition_adherence_target']}';
    _weightController.text = '${goal['weight_checkins_target']}';
    _timeController.text = goal['reminder_time']?.toString() ?? '07:00';
    _remindersEnabled = goal['reminders_enabled'] == true;
    setState(() {
      _loading = false;
    });
  }

  @override
  void dispose() {
    _workoutController.dispose();
    _nutritionController.dispose();
    _weightController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
    });
    try {
      await const GoalsApiService().updateGoal(
        workoutSessionsTarget: int.tryParse(_workoutController.text) ?? 4,
        nutritionAdherenceTarget: int.tryParse(_nutritionController.text) ?? 85,
        weightCheckinsTarget: int.tryParse(_weightController.text) ?? 2,
        remindersEnabled: _remindersEnabled,
        reminderTime: _timeController.text,
      );
      try {
        await LocalNotificationService.instance.scheduleDailyReminder(
          enabled: _remindersEnabled,
          time: _timeController.text,
        );
      } catch (e) {
        // Silently ignore permission errors — reminder will not be set.
        debugPrint('Notification scheduling failed: $e');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Objetivos actualizados.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _loadReport() async {
    final report = await const ReportsApiService().fetchWeeklyReport();
    setState(() {
      _reportMarkdown = report['markdown_report']?.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Objetivos y recordatorios')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
              children: [
                const AppSectionTitle(
                  title: 'Semana objetivo',
                  subtitle: 'Define metas de entrenamiento, adherencia y chequeos.',
                ),
                const SizedBox(height: 18),
                AppSurfaceCard(
                  child: Column(
                    children: [
                      TextField(
                        controller: _workoutController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Sesiones objetivo',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nutritionController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Adherencia nutricional objetivo',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Chequeos de peso por semana',
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        value: _remindersEnabled,
                        onChanged: (value) {
                          setState(() {
                            _remindersEnabled = value;
                          });
                        },
                        title: const Text('Recordatorios activos'),
                      ),
                      TextField(
                        controller: _timeController,
                        decoration: const InputDecoration(
                          labelText: 'Hora recordatorio (HH:MM)',
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          child: Text(_saving ? 'Guardando...' : 'Guardar'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _loadReport,
                          child: const Text('Cargar reporte semanal'),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_reportMarkdown != null) ...[
                  const SizedBox(height: 20),
                  AppSurfaceCard(
                    child: SelectableText(_reportMarkdown!),
                  ),
                ],
              ],
            ),
    );
  }
}
