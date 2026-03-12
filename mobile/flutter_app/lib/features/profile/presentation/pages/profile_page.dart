import 'package:flutter/material.dart';

import '../../../../core/router/app_router.dart';
import '../../../auth/data/services/auth_session_controller.dart';
import '../../data/services/profile_preferences_sync_service.dart';
import '../../domain/models/profile_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<ProfilePreferences> _preferencesFuture;

  @override
  void initState() {
    super.initState();
    _preferencesFuture = ProfilePreferencesSyncService().load();
  }

  Future<void> _refreshPreferences() async {
    setState(() {
      _preferencesFuture = ProfilePreferencesSyncService().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = AuthSessionScope.of(context);
    final session = controller.session;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: FutureBuilder<ProfilePreferences>(
        future: _preferencesFuture,
        builder: (context, snapshot) {
          final preferences = snapshot.data ?? ProfilePreferences.defaults();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF143C3A), Color(0xFF2B6C66)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white24,
                      child: Text(
                        _initials(session?.fullName ?? 'KC'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      session?.fullName ?? 'Usuario Kineo',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      session?.email ?? 'Sin correo disponible',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.tonalIcon(
                      onPressed: () => _editName(
                        controller: controller,
                        currentName: session?.fullName ?? '',
                      ),
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Editar nombre'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const _ProfileInfoCard(
                title: 'Sesion activa',
                description:
                    'Tu sesion queda guardada en el dispositivo y se valida al abrir la app.',
                icon: Icons.shield_moon_rounded,
              ),
              const SizedBox(height: 12),
              const _ProfileInfoCard(
                title: 'Estado del coach',
                description:
                    'Tu perfil, objetivos y plan del dia se sincronizan contra la API activa.',
                icon: Icons.sync_rounded,
              ),
              const SizedBox(height: 20),
              Text('Preferencias', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              _ActionTile(
                icon: Icons.psychology_alt_rounded,
                title: 'Estilo de coach',
                subtitle: preferences.coachingStyle,
                onTap: () => _pickChoice(
                  context: context,
                  title: 'Estilo de coach',
                  currentValue: preferences.coachingStyle,
                  options: const ['Equilibrado', 'Exigente', 'Flexible'],
                  onSelected: (value) => _savePreferences(
                    preferences.copyWith(coachingStyle: value),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _ActionTile(
                icon: Icons.straighten_rounded,
                title: 'Unidades',
                subtitle: preferences.units,
                onTap: () => _pickChoice(
                  context: context,
                  title: 'Unidades',
                  currentValue: preferences.units,
                  options: const ['Metricas', 'Imperiales'],
                  onSelected: (value) => _savePreferences(
                    preferences.copyWith(units: value),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_active_rounded,
                      color: Color(0xFF143C3A),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recordatorios personales',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            preferences.remindersEnabled
                                ? 'Activos'
                                : 'Pausados',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: preferences.remindersEnabled,
                      onChanged: (value) => _savePreferences(
                        preferences.copyWith(remindersEnabled: value),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Cuenta', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              _ActionTile(
                icon: Icons.person_outline_rounded,
                title: 'Nombre del perfil',
                subtitle: session?.fullName ?? 'Sin nombre',
                onTap: () => _editName(
                  controller: controller,
                  currentName: session?.fullName ?? '',
                ),
              ),
              const SizedBox(height: 12),
              _ActionTile(
                icon: Icons.alternate_email_rounded,
                title: 'Correo',
                subtitle: session?.email ?? 'Sin correo',
              ),
              const SizedBox(height: 12),
              _ActionTile(
                icon: Icons.workspace_premium_outlined,
                title: 'Centro de control',
                subtitle: 'Configurar ajustes avanzados del sistema',
                onTap: () async {
                  await Navigator.of(context).pushNamed(AppRouter.controlCenter);
                  if (!mounted) return;
                  await _refreshPreferences();
                },
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async {
                  await controller.logout();
                  if (!context.mounted) return;
                  Navigator.of(context).pushNamedAndRemoveUntil('/auth', (_) => false);
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Cerrar sesion'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _savePreferences(ProfilePreferences preferences) async {
    await ProfilePreferencesSyncService().save(preferences);
    await _refreshPreferences();
  }

  Future<void> _pickChoice({
    required BuildContext context,
    required String title,
    required String currentValue,
    required List<String> options,
    required Future<void> Function(String value) onSelected,
  }) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: options
                .map(
                  (option) => ListTile(
                    title: Text(option),
                    trailing: option == currentValue
                        ? const Icon(Icons.check_rounded)
                        : null,
                    onTap: () => Navigator.of(context).pop(option),
                  ),
                )
                .toList(),
          ),
        );
      },
    );

    if (selected != null) {
      await onSelected(selected);
    }
  }

  Future<void> _editName({
    required AuthSessionController controller,
    required String currentName,
  }) async {
    final textController = TextEditingController(text: currentName);

    final updatedName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Editar nombre'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(
              labelText: 'Nombre completo',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(textController.text.trim());
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (updatedName == null || updatedName.length < 2) {
      return;
    }

    await controller.updateProfileName(updatedName);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil actualizado')),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) {
      return 'KC';
    }
    return parts.map((part) => part[0].toUpperCase()).join();
  }
}

class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE8D8BF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: const Color(0xFF143C3A)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF143C3A)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (onTap != null) const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
