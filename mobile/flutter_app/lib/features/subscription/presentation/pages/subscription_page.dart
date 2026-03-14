import 'package:flutter/material.dart';

import '../../../profile/data/services/profile_preferences_sync_service.dart';
import '../../../profile/domain/models/profile_preferences.dart';

class ControlCenterPage extends StatefulWidget {
  const ControlCenterPage({super.key});

  @override
  State<ControlCenterPage> createState() => _ControlCenterPageState();
}

class _ControlCenterPageState extends State<ControlCenterPage> {
  late Future<ProfilePreferences> _preferencesFuture;

  @override
  void initState() {
    super.initState();
    _preferencesFuture = ProfilePreferencesSyncService().load();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() {
      _preferencesFuture = ProfilePreferencesSyncService().load();
    });
  }

  Future<void> _savePreferences(ProfilePreferences preferences) async {
    await ProfilePreferencesSyncService().save(preferences);
    if (!mounted) return;
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Centro de control')),
      body: FutureBuilder<ProfilePreferences>(
        future: _preferencesFuture,
        builder: (context, snapshot) {
          final preferences = snapshot.data ?? ProfilePreferences.defaults();

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E342F), Color(0xFF6A5A31)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ajustes avanzados del sistema',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Aqui controlas como responde Kineo durante el dia: prioridad, profundidad de recomendaciones y nivel de intervencion automatica.',
                        style: const TextStyle(
                          color: Colors.white70,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: 'Coach',
                        value: preferences.coachingStyle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        title: 'Prioridad',
                        value: preferences.dailyPriority,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        title: 'Lectura',
                        value: preferences.recommendationDepth,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Controles principales', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                _ChoiceCard(
                  title: 'Prioridad del dia',
                  subtitle:
                      'Decide si el sistema debe priorizar adherencia, rendimiento o recuperacion.',
                  currentValue: preferences.dailyPriority,
                  options: const ['Adherencia', 'Rendimiento', 'Recuperacion'],
                  onSelected: (value) => _savePreferences(
                    preferences.copyWith(dailyPriority: value),
                  ),
                ),
                const SizedBox(height: 12),
                _ChoiceCard(
                  title: 'Profundidad de recomendaciones',
                  subtitle:
                      'Controla cuan detalladas deben ser las sugerencias del sistema.',
                  currentValue: preferences.recommendationDepth,
                  options: const ['Esencial', 'Balanceada', 'Profunda'],
                  onSelected: (value) => _savePreferences(
                    preferences.copyWith(recommendationDepth: value),
                  ),
                ),
                const SizedBox(height: 12),
                _ToggleCard(
                  title: 'Ajustes proactivos',
                  subtitle:
                      'Permite que Kineo proponga microajustes segun tu contexto y tus registros.',
                  value: preferences.proactiveAdjustments,
                  onChanged: (value) => _savePreferences(
                    preferences.copyWith(proactiveAdjustments: value),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Capacidades activas', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                const _InfoCard(
                  title: 'Inicio operativo',
                  description:
                      'El home ya muestra acciones rapidas, checklist diario, progreso del dia y edicion directa del ultimo registro.',
                  tone: Color(0xFFDDEBE5),
                ),
                const SizedBox(height: 12),
                const _InfoCard(
                  title: 'Personalizacion contextual',
                  description:
                      'El estilo del coach, la prioridad diaria y la profundidad cambian workout, nutricion y lectura del dashboard.',
                  tone: Color(0xFFF2E5D0),
                ),
                const SizedBox(height: 12),
                const _InfoCard(
                  title: 'Sincronizacion persistente',
                  description:
                      'Las preferencias quedan guardadas en dispositivo y backend para mantener continuidad.',
                  tone: Color(0xFFE8E3F1),
                ),
                const SizedBox(height: 24),
                Text('Comportamiento actual', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                _StateCard(
                  title: 'Workout adaptativo',
                  description:
                      _workoutBehaviorDescription(preferences),
                ),
                const SizedBox(height: 12),
                _StateCard(
                  title: 'Nutricion contextual',
                  description:
                      _nutritionBehaviorDescription(preferences),
                ),
                const SizedBox(height: 12),
                _StateCard(
                  title: 'Modo de intervencion',
                  description: preferences.proactiveAdjustments
                      ? 'Los ajustes proactivos estan activos: Kineo puede sumar microajustes y bloques adaptativos segun tu contexto.'
                      : 'Los ajustes proactivos estan en pausa: Kineo mantiene una estructura mas estable y menos intervencion automatica.',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF4EFE6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD8DED7)),
      ),
      child: Column(
        children: [
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF143C3A),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.title,
    required this.subtitle,
    required this.currentValue,
    required this.options,
    required this.onSelected,
  });

  final String title;
  final String subtitle;
  final String currentValue;
  final List<String> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCE2DB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options
                .map(
                  (option) => ChoiceChip(
                    label: Text(option),
                    selected: option == currentValue,
                    selectedColor: const Color(0xFFDCEBE4),
                    onSelected: (_) => onSelected(option),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  const _ToggleCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCE2DB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.description,
    required this.tone,
  });

  final String title;
  final String description;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(description, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF4F0E8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFD6DDD7)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

String _workoutBehaviorDescription(ProfilePreferences preferences) {
  final priority = switch (preferences.dailyPriority) {
    'Rendimiento' =>
      'Hoy el entrenamiento empuja el bloque principal y agrega un marcador de rendimiento.',
    'Recuperacion' =>
      'Hoy el entrenamiento baja friccion, protege recuperacion y prioriza control tecnico.',
    _ => 'Hoy el entrenamiento busca adherencia simple y una sesion sostenible.',
  };
  final depth = switch (preferences.recommendationDepth) {
    'Esencial' => ' Se compacta a una estructura corta y facil de ejecutar.',
    'Profunda' => ' Se agregan checklist tecnico y mas puntos de decision.',
    _ => ' Mantiene una lectura balanceada entre claridad y detalle.',
  };
  return '$priority$depth';
}

String _nutritionBehaviorDescription(ProfilePreferences preferences) {
  final priority = switch (preferences.dailyPriority) {
    'Rendimiento' =>
      'La nutricion prioriza energia util y timing alrededor del entreno.',
    'Recuperacion' =>
      'La nutricion prioriza hidratacion, digestiones simples y menor carga de decision.',
    _ => 'La nutricion prioriza adherencia diaria, saciedad y consistencia.',
  };
  final depth = switch (preferences.recommendationDepth) {
    'Esencial' => ' Se enfoca en menos decisiones y comidas ancla.',
    'Profunda' => ' Incluye guias de reemplazo y criterios mas finos de decision.',
    _ => ' Mantiene recomendaciones equilibradas y faciles de sostener.',
  };
  return '$priority$depth';
}
