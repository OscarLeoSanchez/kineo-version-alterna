import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_bottom_sheet.dart';

class WorkoutLogConfirmationSheet extends StatelessWidget {
  final String focus;
  final String energyLevel;
  final String? nextFocus;

  const WorkoutLogConfirmationSheet({
    super.key,
    required this.focus,
    required this.energyLevel,
    this.nextFocus,
  });

  String get _coachMessage {
    return switch (energyLevel) {
      'Alta' => '¡Excelente rendimiento!',
      'Media' => 'Buen trabajo, constancia es la clave.',
      'Baja' => 'Escuchaste a tu cuerpo, eso también cuenta.',
      _ => 'Sesión completada, sigue adelante.',
    };
  }

  String get _energyLabel {
    return switch (energyLevel) {
      'Alta' => 'Energía alta',
      'Media' => 'Energía media',
      'Baja' => 'Energía baja',
      _ => energyLevel,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Green checkmark icon
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFD6EEE6),
            borderRadius: BorderRadius.circular(36),
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF143C3A),
            size: 40,
          ),
        ),
        const SizedBox(height: 16),

        // Title
        Text(
          '¡Entrenamiento registrado!',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Logged: focus + energy label
        Text(
          '$focus · $_energyLabel',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Coach message
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE8EFE8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _coachMessage,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ),

        // Next focus card
        if (nextFocus != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F0E6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.arrow_forward_rounded, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mañana: $nextFocus',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Close button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ),
      ],
    );
  }
}

/// Convenience function to open the workout log confirmation sheet
void showWorkoutLogConfirmationSheet(
  BuildContext context, {
  required String focus,
  required String energyLevel,
  String? nextFocus,
}) {
  showAppBottomSheet(
    context,
    title: null,
    child: WorkoutLogConfirmationSheet(
      focus: focus,
      energyLevel: energyLevel,
      nextFocus: nextFocus,
    ),
  );
}
