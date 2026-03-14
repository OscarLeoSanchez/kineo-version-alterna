import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_bottom_sheet.dart';

class NutritionLogConfirmationSheet extends StatelessWidget {
  final String mealLabel;
  final int adherenceScore;
  final double hydrationLiters;

  const NutritionLogConfirmationSheet({
    super.key,
    required this.mealLabel,
    required this.adherenceScore,
    required this.hydrationLiters,
  });

  Color get _adherenceColor {
    if (adherenceScore >= 80) return const Color(0xFF2E7D52);
    if (adherenceScore >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFDC2626);
  }

  Color get _adherenceBackgroundColor {
    if (adherenceScore >= 80) return const Color(0xFFD6EEE6);
    if (adherenceScore >= 50) return const Color(0xFFFEF3C7);
    return const Color(0xFFFFE8E8);
  }

  IconData get _adherenceIcon {
    if (adherenceScore >= 80) return Icons.check_circle_rounded;
    if (adherenceScore >= 50) return Icons.remove_circle_rounded;
    return Icons.warning_rounded;
  }

  String get _adherenceLabel {
    if (adherenceScore >= 80) return '¡Excelente adherencia!';
    if (adherenceScore >= 50) return 'Buen intento, mañana mejor.';
    return 'No te preocupes, cada comida es una nueva oportunidad.';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon based on adherence
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: _adherenceBackgroundColor,
            borderRadius: BorderRadius.circular(36),
          ),
          child: Icon(
            _adherenceIcon,
            color: _adherenceColor,
            size: 40,
          ),
        ),
        const SizedBox(height: 16),

        // Title
        Text(
          'Comida registrada',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),

        // Meal label
        Text(
          mealLabel,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Adherence bar
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Adherencia',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '$adherenceScore%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _adherenceColor,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: adherenceScore / 100,
                minHeight: 10,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(_adherenceColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Hydration
        Text(
          'Hidratación: ${hydrationLiters.toStringAsFixed(1)}L anotada',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),

        // Coach message
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _adherenceBackgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _adherenceLabel,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),

        // OK button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ),
      ],
    );
  }
}

/// Convenience function to open the nutrition log confirmation sheet
void showNutritionLogConfirmationSheet(
  BuildContext context, {
  required String mealLabel,
  required int adherenceScore,
  required double hydrationLiters,
}) {
  showAppBottomSheet(
    context,
    child: NutritionLogConfirmationSheet(
      mealLabel: mealLabel,
      adherenceScore: adherenceScore,
      hydrationLiters: hydrationLiters,
    ),
  );
}
