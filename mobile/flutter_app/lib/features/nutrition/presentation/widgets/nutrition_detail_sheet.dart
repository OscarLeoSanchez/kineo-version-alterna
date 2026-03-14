import 'package:flutter/material.dart';

class NutritionDetailSheet extends StatelessWidget {
  /// The meal data map from the nutrition API response.
  /// Legacy keys: title, meal, macros, objective, detail, components (List),
  ///   swap_options (List), weekly_plan (List), option_bank (List)
  /// New keys: calories_kcal, protein_g, carbs_g, fat_g, fiber_g,
  ///   cooking_time_minutes, ingredients_with_quantities (List),
  ///   preparation_steps (List), allergens (List), best_for
  final Map<String, dynamic> meal;

  const NutritionDetailSheet({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    // New-format fields
    final caloriesKcal = meal['calories_kcal'];
    final proteinG = meal['protein_g'];
    final carbsG = meal['carbs_g'];
    final fatG = meal['fat_g'];
    final fiberG = meal['fiber_g'];
    final cookingTime = meal['cooking_time_minutes'];
    final ingredients = (meal['ingredients_with_quantities'] as List<dynamic>? ?? []).cast<String>();
    final preparationSteps = (meal['preparation_steps'] as List<dynamic>? ?? []).cast<String>();
    final allergens = (meal['allergens'] as List<dynamic>? ?? []).cast<String>();
    final bestFor = meal['best_for']?.toString();

    // Legacy fallback fields
    final legacyMacros = meal['macros']?.toString();
    final legacyComponents = (meal['components'] as List<dynamic>? ?? []).cast<String>();
    final objective = meal['objective']?.toString() ?? bestFor;

    final hasNewMacros =
        caloriesKcal != null || proteinG != null || carbsG != null || fatG != null || fiberG != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Material(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  children: [
                    // Header
                    Text(
                      meal['title']?.toString() ?? 'Comida',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    // Meal name subtitle
                    if ((meal['meal_name']?.toString() ?? meal['meal']?.toString() ?? '')
                        .isNotEmpty) ...[
                      Text(
                        meal['meal_name']?.toString() ?? meal['meal']?.toString() ?? '',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: Colors.black54),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Badges row (cooking time + best_for)
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (cookingTime != null) _BadgeChip(label: '⏱ $cookingTime min'),
                        if (bestFor != null && bestFor.isNotEmpty)
                          _BadgeChip(label: '🎯 $bestFor'),
                      ],
                    ),
                    if (cookingTime != null || (bestFor != null && bestFor.isNotEmpty))
                      const SizedBox(height: 16),

                    // Macros section (new format — emoji chips)
                    if (hasNewMacros) ...[
                      _SectionHeader(label: 'MACRONUTRIENTES'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (caloriesKcal != null)
                            _EmojiMacroChip(
                              emoji: '🔥',
                              value: '$caloriesKcal',
                              unit: 'kcal',
                              color: const Color(0xFFFFEDCC),
                            ),
                          if (proteinG != null)
                            _EmojiMacroChip(
                              emoji: '🥩',
                              value: '$proteinG',
                              unit: 'g prot',
                              color: const Color(0xFFDCEEDC),
                            ),
                          if (carbsG != null)
                            _EmojiMacroChip(
                              emoji: '🌾',
                              value: '$carbsG',
                              unit: 'g carb',
                              color: const Color(0xFFE8E4F4),
                            ),
                          if (fatG != null)
                            _EmojiMacroChip(
                              emoji: '🫙',
                              value: '$fatG',
                              unit: 'g gras',
                              color: const Color(0xFFFFF3E0),
                            ),
                          if (fiberG != null)
                            _EmojiMacroChip(
                              emoji: '🌿',
                              value: '$fiberG',
                              unit: 'g fibra',
                              color: const Color(0xFFE3F2FD),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ] else if (legacyMacros != null && legacyMacros.isNotEmpty) ...[
                      // Legacy macros fallback
                      Text(
                        legacyMacros,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Objective / best_for
                    if (objective != null && objective.isNotEmpty) ...[
                      _SectionHeader(label: 'OBJETIVO'),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7F4EE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(objective),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Ingredientes (new format)
                    if (ingredients.isNotEmpty) ...[
                      _SectionHeader(label: 'INGREDIENTES'),
                      const SizedBox(height: 10),
                      ...ingredients.map(
                        (ingredient) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 4, right: 8),
                                child: Icon(
                                  Icons.circle,
                                  size: 6,
                                  color: Color(0xFF143C3A),
                                ),
                              ),
                              Expanded(child: Text(ingredient)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ] else if (legacyComponents.isNotEmpty) ...[
                      _SectionHeader(label: 'COMPONENTES'),
                      const SizedBox(height: 8),
                      ...legacyComponents.map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('• $c'),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Preparación (new format) — numbered steps
                    if (preparationSteps.isNotEmpty) ...[
                      _SectionHeader(label: 'PREPARACIÓN'),
                      const SizedBox(height: 10),
                      ...preparationSteps.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                margin: const EdgeInsets.only(right: 10, top: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF143C3A),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: Center(
                                  child: Text(
                                    '${entry.key + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(entry.value),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Alérgenos
                    if (allergens.isNotEmpty) ...[
                      _SectionHeader(label: 'ALÉRGENOS'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: allergens
                            .map(
                              (a) => Chip(
                                label: Text(a),
                                backgroundColor: const Color(0xFFFFE8E8),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Legacy detail
                    if (meal['detail'] != null &&
                        (meal['detail']?.toString() ?? '').isNotEmpty) ...[
                      Text(meal['detail']!.toString()),
                      const SizedBox(height: 12),
                    ],

                    // Close button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cerrar'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Convenience function to open the nutrition detail sheet
void showNutritionDetailSheet(BuildContext context, Map<String, dynamic> meal) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => NutritionDetailSheet(meal: meal),
  );
}

// ─── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.black45,
            letterSpacing: 0.9,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

// ─── Emoji macro chip ──────────────────────────────────────────────────────────

class _EmojiMacroChip extends StatelessWidget {
  final String emoji;
  final String value;
  final String unit;
  final Color color;

  const _EmojiMacroChip({
    required this.emoji,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                unit,
                style: const TextStyle(fontSize: 10, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Badge chip ────────────────────────────────────────────────────────────────

class _BadgeChip extends StatelessWidget {
  final String label;

  const _BadgeChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1ECE3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
