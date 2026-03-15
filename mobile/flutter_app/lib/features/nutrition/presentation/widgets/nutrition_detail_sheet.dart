import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class NutritionDetailSheet extends StatelessWidget {
  /// The meal data map from the nutrition API response.
  /// Legacy keys: title, meal, macros, objective, detail, components (List),
  ///   swap_options (List), weekly_plan (List), option_bank (List)
  /// New keys: calories_kcal, protein_g, carbs_g, fat_g, fiber_g,
  ///   cooking_time_minutes, ingredients_with_quantities (List),
  ///   preparation_steps (List), allergens (List), best_for
  /// T-14: optional calorie_target and protein_target_g for macro vs. target display
  final Map<String, dynamic> meal;
  final double? calorieTarget;
  final double? proteinTargetG;

  const NutritionDetailSheet({
    super.key,
    required this.meal,
    this.calorieTarget,
    this.proteinTargetG,
  });

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

                    // Badges row (cooking time)
                    if (cookingTime != null) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _BadgeChip(label: '⏱ $cookingTime min'),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // T-08 — best_for: "Ideal para:" chip + ExpansionTile
                    if (bestFor != null && bestFor.isNotEmpty) ...[
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentMid,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('✨ '),
                                Text(
                                  'Ideal para: ',
                                  style: TextStyle(
                                    color: Colors.green.shade800,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    bestFor,
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: const EdgeInsets.only(bottom: 12),
                          leading: Icon(
                            Icons.lightbulb_outline,
                            color: Colors.green.shade700,
                            size: 20,
                          ),
                          title: Text(
                            '¿Por qué esta comida?',
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          initiallyExpanded: false,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.accentChip,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bestFor,
                                    style: const TextStyle(height: 1.5),
                                  ),
                                  // T-14 — Macros vs. target
                                  if (calorieTarget != null && calorieTarget! > 0) ...[
                                    const SizedBox(height: 10),
                                    const Divider(height: 1, color: AppColors.accentDivider),
                                    const SizedBox(height: 10),
                                    if (proteinG != null) ...[
                                      _MacroVsTargetRow(
                                        label: 'Proteína',
                                        consumed: _toDouble(proteinG),
                                        target: proteinTargetG,
                                        unit: 'g',
                                      ),
                                      const SizedBox(height: 6),
                                    ],
                                    if (caloriesKcal != null) ...[
                                      _MacroVsTargetRow(
                                        label: 'Calorías',
                                        consumed: _toDouble(caloriesKcal),
                                        target: calorieTarget,
                                        unit: 'kcal',
                                      ),
                                      const SizedBox(height: 6),
                                    ],
                                  ],
                                  // T-14 — Meal slot context
                                  if ((meal['title']?.toString() ?? '').isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.schedule,
                                          size: 14,
                                          color: Colors.green,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            'Esta comida es ideal para ${meal['title']}',
                                            style: TextStyle(
                                              color: Colors.green.shade800,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

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
                              color: AppColors.warningWarm,
                            ),
                          if (proteinG != null)
                            _EmojiMacroChip(
                              emoji: '🥩',
                              value: '$proteinG',
                              unit: 'g prot',
                              color: AppColors.macroProtein,
                            ),
                          if (carbsG != null)
                            _EmojiMacroChip(
                              emoji: '🌾',
                              value: '$carbsG',
                              unit: 'g carb',
                              color: AppColors.purpleLight,
                            ),
                          if (fatG != null)
                            _EmojiMacroChip(
                              emoji: '🫙',
                              value: '$fatG',
                              unit: 'g gras',
                              color: AppColors.warningPeach,
                            ),
                          if (fiberG != null)
                            _EmojiMacroChip(
                              emoji: '🌿',
                              value: '$fiberG',
                              unit: 'g fibra',
                              color: AppColors.macroFat,
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
                          color: AppColors.accentChip,
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
                                  color: AppColors.primary,
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
                                  color: AppColors.primary,
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
                                backgroundColor: AppColors.errorLight,
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
void showNutritionDetailSheet(
  BuildContext context,
  Map<String, dynamic> meal, {
  double? calorieTarget,
  double? proteinTargetG,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => NutritionDetailSheet(
      meal: meal,
      calorieTarget: calorieTarget,
      proteinTargetG: proteinTargetG,
    ),
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
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

// ─── T-14: Macro vs. Target Row ────────────────────────────────────────────────

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

class _MacroVsTargetRow extends StatelessWidget {
  final String label;
  final double consumed;
  final double? target;
  final String unit;

  const _MacroVsTargetRow({
    required this.label,
    required this.consumed,
    required this.target,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final targetStr = target != null && target! > 0
        ? '${consumed.round()}/${ target!.round()} $unit del objetivo'
        : '${consumed.round()} $unit';
    return Row(
      children: [
        const Icon(Icons.arrow_right, size: 16, color: Colors.black45),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
        Text(
          targetStr,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }
}
