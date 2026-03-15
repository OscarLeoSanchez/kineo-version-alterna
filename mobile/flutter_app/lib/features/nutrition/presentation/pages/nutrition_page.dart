import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/session_data_cache.dart';
import '../../../../shared/widgets/activity_record_detail_sheet.dart';
import '../../../../shared/widgets/app_section_title.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/loading_button.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../../../../shared/widgets/pressable_card.dart';
import '../../../activity/data/services/activity_history_api_service.dart';
import '../../../nutrition/data/services/nutrition_api_service.dart';
import '../../../nutrition/data/services/nutrition_log_api_service.dart';
import '../../../nutrition/data/services/nutrition_photo_api_service.dart';
import '../../../nutrition/presentation/widgets/nutrition_detail_sheet.dart';
import '../../../nutrition/presentation/widgets/nutrition_log_confirmation_sheet.dart';
import '../../../profile/data/services/profile_preferences_store.dart';
import '../../../../core/theme/app_colors.dart';

// ─── Brand colors (aliased to AppColors design tokens) ────────────────────────
const _kBrand = AppColors.primary;
const _kBrandLight = AppColors.brandLight;
const _kAmber = AppColors.warningAmber;
const _kAmberLight = AppColors.warningBg;
const _kGreen = AppColors.accent;
const _kGreenLight = AppColors.primaryLight;
const _kGrey = AppColors.neutral;

// ─── Meal type helpers ─────────────────────────────────────────────────────────
IconData _mealIcon(String label) {
  switch (label.toLowerCase()) {
    case 'desayuno':
      return Icons.wb_sunny_outlined;
    case 'almuerzo':
      return Icons.lunch_dining_outlined;
    case 'cena':
      return Icons.nightlight_outlined;
    default:
      return Icons.apple_outlined;
  }
}

Color _mealColor(String label) {
  switch (label.toLowerCase()) {
    case 'desayuno':
      return AppColors.warningPeach;
    case 'almuerzo':
      return AppColors.accentLight;
    case 'cena':
      return AppColors.infoSoft;
    default:
      return AppColors.errorPale;
  }
}

// ─── Main page ─────────────────────────────────────────────────────────────────

class NutritionPage extends StatefulWidget {
  const NutritionPage({super.key});

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  _NutritionViewData? _viewData;
  bool _isInitialLoading = true;
  bool _isSubmitting = false;
  bool _showShimmer = false;
  Timer? _shimmerTimer;

  int? _selectedDayIndex;
  String _mealLabel = 'Almuerzo';

  // Photo analysis overlay
  bool _isAnalyzingPhoto = false;
  late AnimationController _analyzeSpinController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _analyzeSpinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    final cache = SessionDataCache.instance;
    if (cache.nutritionSummary != null && cache.history != null) {
      _viewData = _NutritionViewData(
        summary: cache.nutritionSummary!,
        history: cache.history!,
        coachingStyle: 'Equilibrado',
      );
      _isInitialLoading = false;
      _hydratePrefs();
      _refreshSilently();
    } else {
      // Delay shimmer so fast loads don't flash
      _shimmerTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted && _isInitialLoading) {
          setState(() => _showShimmer = true);
        }
      });
      _bootstrap();
    }
  }

  @override
  void dispose() {
    _shimmerTimer?.cancel();
    _analyzeSpinController.dispose();
    super.dispose();
  }

  // ── Data loading ────────────────────────────────────────────────────────────

  Future<void> _hydratePrefs() async {
    final prefs = await ProfilePreferencesStore().load();
    if (!mounted || _viewData == null) return;
    setState(() {
      _viewData = _viewData!.copyWith(coachingStyle: prefs.coachingStyle);
    });
  }

  Future<void> _bootstrap() async {
    try {
      final data = await _loadNutrition();
      if (!mounted) return;
      setState(() {
        _viewData = data;
        _isInitialLoading = false;
        _showShimmer = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isInitialLoading = false;
        _showShimmer = false;
      });
    }
  }

  Future<_NutritionViewData> _loadNutrition() async {
    final results = await Future.wait([
      const NutritionApiService().fetchNutritionSummary(),
      const ActivityHistoryApiService().fetchHistory(),
      ProfilePreferencesStore().load(),
    ]);
    final summary = Map<String, dynamic>.from(
      results[0] as Map<String, dynamic>,
    );
    final history = Map<String, dynamic>.from(
      results[1] as Map<String, dynamic>,
    );
    SessionDataCache.instance
      ..nutritionSummary = summary
      ..history = history;
    final prefs = results[2] as dynamic;
    return _NutritionViewData(
      summary: summary,
      history: history,
      coachingStyle: prefs.coachingStyle,
    );
  }

  Future<void> _refreshSilently() async {
    try {
      final data = await _loadNutrition();
      if (!mounted) return;
      setState(() => _viewData = data);
    } catch (_) {}
  }

  // ── Computed helpers ─────────────────────────────────────────────────────────

  Map<String, dynamic>? get _selectedDay {
    final days = (_viewData?.summary['weekly_days'] as List<dynamic>? ?? []);
    if (days.isEmpty) return null;
    final baseIndex =
        _selectedDayIndex ??
        (_viewData?.summary['selected_day_index'] as int? ?? 0);
    final safeIndex = baseIndex.clamp(0, days.length - 1);
    return Map<String, dynamic>.from(days[safeIndex] as Map);
  }

  List<Map<String, dynamic>> get _mealsForSelectedDay {
    final meals = (_selectedDay?['meals'] as List<dynamic>? ?? []);
    return meals.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Map<String, dynamic>? get _mealForSelectedLabel {
    final meals = _mealsForSelectedDay;
    if (meals.isEmpty) return null;
    for (final meal in meals) {
      if (_normalizeMealLabel(meal['title']?.toString() ?? '') ==
          _normalizeMealLabel(_mealLabel)) {
        return meal;
      }
    }
    return meals.first;
  }

  List<Map<String, dynamic>> get _nutritionHistory {
    final items =
        (_viewData?.history['nutrition_logs'] as List<dynamic>? ?? []);
    return items.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  List<Map<String, dynamic>> _logsForDay(String isoDate) {
    return _nutritionHistory.where((entry) {
      final loggedDate = (entry['logged_at']?.toString() ?? '')
          .split('T')
          .first
          .trim();
      return loggedDate == isoDate;
    }).toList();
  }

  Map<String, dynamic>? _matchLogForMeal(
    String isoDate,
    Map<String, dynamic> meal,
  ) {
    final targetTitle = _normalizeMealLabel(meal['title']?.toString() ?? '');
    for (final entry in _logsForDay(isoDate)) {
      if (_normalizeMealLabel(entry['meal_label']?.toString() ?? '') ==
          targetTitle) {
        return entry;
      }
    }
    return null;
  }

  void _openOptionBankSheet(Map<String, dynamic> meal) {
    final options = (meal['option_bank'] as List<dynamic>? ?? [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final swapOptions = (meal['swap_options'] as List<dynamic>? ?? [])
        .map((item) => item.toString())
        .toList();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Material(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              color: Theme.of(context).colorScheme.surface,
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Text(
                    'Opciones para ${meal['title'] ?? 'esta comida'}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    meal['meal_name']?.toString() ??
                        meal['meal']?.toString() ??
                        '',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  ),
                  if (options.isEmpty && swapOptions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: swapOptions
                          .map(
                            (item) => _SmallPill(
                              label: item,
                              color: _kBrandLight,
                              textColor: _kBrand,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (options.isEmpty)
                    const Text(
                      'Aún no hay banco de opciones para esta comida.',
                      style: TextStyle(color: Colors.black45),
                    )
                  else
                    ...options.map((option) {
                      final detailMeal = {
                        'title': meal['title'],
                        'meal_name': option['name'],
                        ...option,
                      };
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PressableCard(
                          borderRadius: 14,
                          onTap: () =>
                              showNutritionDetailSheet(context, detailMeal),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceCream,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.surfaceClay,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _kBrandLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.restaurant_menu_rounded,
                                    color: _kBrand,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        option['name']?.toString() ?? 'Opción',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if ((option['summary']?.toString() ?? '')
                                          .isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          option['summary'].toString(),
                                          style: const TextStyle(
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                      if ((option['macros']?.toString() ?? '')
                                          .isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        _SmallPill(
                                          label: option['macros'].toString(),
                                          color: AppColors.brandLight,
                                          textColor: _kBrand,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Colors.black38,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────────────

  Future<bool> _submitNutrition({
    required String mealLabel,
    required int adherence,
    required int proteinGrams,
    required int hydrationLiters,
    String notes = '',
  }) async {
    setState(() => _isSubmitting = true);
    try {
      final result = await const NutritionLogApiService().submitNutrition(
        mealLabel: mealLabel,
        adherenceScore: adherence,
        proteinGrams: proteinGrams,
        hydrationLiters: hydrationLiters,
        notes: notes,
      );
      if (!mounted) return false;
      showNutritionLogConfirmationSheet(
        context,
        mealLabel: mealLabel,
        adherenceScore: adherence,
        hydrationLiters: hydrationLiters.toDouble(),
      );
      if (result.sent || result.queuedOffline) _refreshSilently();
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al registrar: $e'),
          backgroundColor: AppColors.errorDark,
        ),
      );
      return false;
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _openManualRegistration() async {
    final nameController = TextEditingController();
    final kcalController = TextEditingController();
    final proteinController = TextEditingController(text: '30');
    final hydrationController = TextEditingController(text: '1');
    final notesController = TextEditingController();
    double adherence = 85;
    String mealLabel = _mealLabel;
    bool isSubmittingSheet = false;
    bool isSuccessSheet = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Material(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Registrar comida',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _mealLabelChips(
                        current: mealLabel,
                        onChanged: (v) => setSheetState(() => mealLabel = v),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de la comida',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: kcalController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Calorías aprox.',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: proteinController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Proteína (g)',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: hydrationController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Agua (L)',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Adherencia ${adherence.round()}%'),
                                Slider(
                                  value: adherence,
                                  min: 40,
                                  max: 100,
                                  divisions: 12,
                                  onChanged: (v) =>
                                      setSheetState(() => adherence = v),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      TextField(
                        controller: notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notas / ingredientes / preparación',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: isSuccessSheet
                                ? FilledButton.icon(
                                    onPressed: null,
                                    icon: const Icon(
                                      Icons.check_circle_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('Guardado'),
                                  )
                                : LoadingButton(
                                    label: 'Guardar',
                                    isLoading: isSubmittingSheet,
                                    onPressed: () async {
                                      setSheetState(
                                        () => isSubmittingSheet = true,
                                      );
                                      final extra = [
                                        if (nameController.text
                                            .trim()
                                            .isNotEmpty)
                                          nameController.text.trim(),
                                        if (kcalController.text
                                            .trim()
                                            .isNotEmpty)
                                          '${kcalController.text.trim()} kcal',
                                        if (notesController.text
                                            .trim()
                                            .isNotEmpty)
                                          notesController.text.trim(),
                                      ].join(' | ');
                                      final ok = await _submitNutrition(
                                        mealLabel: mealLabel,
                                        adherence: adherence.round(),
                                        proteinGrams:
                                            int.tryParse(
                                              proteinController.text.trim(),
                                            ) ??
                                            25,
                                        hydrationLiters:
                                            int.tryParse(
                                              hydrationController.text.trim(),
                                            ) ??
                                            1,
                                        notes: extra,
                                      );
                                      if (!context.mounted) return;
                                      if (ok) {
                                        setSheetState(() {
                                          isSubmittingSheet = false;
                                          isSuccessSheet = true;
                                        });
                                        await Future<void>.delayed(
                                          const Duration(milliseconds: 600),
                                        );
                                        if (context.mounted) {
                                          Navigator.of(context).pop();
                                        }
                                      } else {
                                        setSheetState(
                                          () => isSubmittingSheet = false,
                                        );
                                      }
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openPhotoAnalysisFlow() async {
    // Step 1 — source picker
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Material(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Text(
                  'Analizar comida con IA',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _SourceOptionButton(
                        icon: Icons.photo_camera_rounded,
                        label: 'Cámara',
                        onTap: () =>
                            Navigator.of(context).pop(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SourceOptionButton(
                        icon: Icons.photo_library_rounded,
                        label: 'Galería',
                        onTap: () =>
                            Navigator.of(context).pop(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;

    // Step 2 — pick image
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 82,
    );
    if (picked == null || !mounted) return;

    // Step 3 — show full-screen analyzing overlay
    setState(() => _isAnalyzingPhoto = true);

    Map<String, dynamic>? result;
    String? errorMsg;
    try {
      result = await const NutritionPhotoApiService().analyzePhoto(
        mealLabel: _mealLabel,
        filePath: picked.path,
      );
    } catch (e) {
      errorMsg = e.toString();
    }

    if (!mounted) return;
    setState(() => _isAnalyzingPhoto = false);

    if (errorMsg != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo analizar la foto: $errorMsg'),
          action: SnackBarAction(
            label: 'Reintentar',
            onPressed: _openPhotoAnalysisFlow,
          ),
        ),
      );
      return;
    }

    if (result == null) return;

    // Step 4 — rich result sheet
    await _showPhotoResultSheet(picked.path, result);
  }

  Future<void> _showPhotoResultSheet(
    String imagePath,
    Map<String, dynamic> result,
  ) async {
    final detectedItems = (result['detected_items'] as List<dynamic>? ?? [])
        .cast<String>();
    final ingredients = (result['ingredients'] as List<dynamic>? ?? [])
        .cast<String>();
    var adjustedKcal =
        (result['estimated_calories_kcal'] as num?)?.round() ?? 0;
    var adjustedProtein = (result['estimated_protein_g'] as num?)?.round() ?? 0;
    var adjustedCarbs = (result['estimated_carbs_g'] as num?)?.round() ?? 0;
    var adjustedFat = (result['estimated_fat_g'] as num?)?.round() ?? 0;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.72,
              minChildSize: 0.52,
              maxChildSize: 0.96,
              expand: false,
              builder: (context, scrollController) {
                return Material(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  color: Theme.of(context).colorScheme.surface,
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(
                              File(imagePath),
                              width: 88,
                              height: 88,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  result['detected_dish_name']?.toString() ??
                                      'Comida detectada',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 6),
                                if ((result['serving_hint']?.toString() ?? '')
                                    .isNotEmpty)
                                  Text(
                                    result['serving_hint'].toString(),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Colors.black54),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _MacroRow(
                        kcal: adjustedKcal,
                        protein: adjustedProtein,
                        carbs: adjustedCarbs,
                        fat: adjustedFat,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final adjusted = await _openMacroAdjustSheet(
                              kcal: adjustedKcal,
                              protein: adjustedProtein,
                              carbs: adjustedCarbs,
                              fat: adjustedFat,
                            );
                            if (adjusted == null) return;
                            setSheetState(() {
                              adjustedKcal = adjusted.$1;
                              adjustedProtein = adjusted.$2;
                              adjustedCarbs = adjusted.$3;
                              adjustedFat = adjusted.$4;
                            });
                          },
                          icon: const Icon(Icons.tune_rounded, size: 16),
                          label: const Text('Ajustar macros'),
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (detectedItems.isNotEmpty) ...[
                        _PhotoSectionLabel(label: 'INGREDIENTES DETECTADOS'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: detectedItems
                              .map(
                                (item) => Chip(
                                  label: Text(item),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (ingredients.isNotEmpty) ...[
                        _PhotoSectionLabel(label: 'INGREDIENTES ESTIMADOS'),
                        const SizedBox(height: 8),
                        ...ingredients.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 16,
                                    color: _kBrand,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(item)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      if ((result['confidence_note']?.toString() ?? '')
                          .isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.infoPale,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.infoBorder),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: _kBrand,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  result['confidence_note'].toString(),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if ((result['coach_note']?.toString() ?? '')
                          .isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _kGreenLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            result['coach_note'].toString(),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      FilledButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _submitNutrition(
                            mealLabel: _mealLabel,
                            adherence: 88,
                            proteinGrams: adjustedProtein > 0
                                ? adjustedProtein
                                : 25,
                            hydrationLiters: 1,
                            notes:
                                'Foto IA | ${result['detected_dish_name']} | '
                                '$adjustedKcal kcal | '
                                'P:$adjustedProtein C:$adjustedCarbs G:$adjustedFat | '
                                'Detectados: ${detectedItems.join(', ')}'
                                '${ingredients.isNotEmpty ? ' | Ingredientes: ${ingredients.join(', ')}' : ''}',
                          );
                        },
                        child: const Text('Registrar esta comida'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _openPhotoAnalysisFlow();
                        },
                        child: const Text('Intentar de nuevo'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<(int, int, int, int)?> _openMacroAdjustSheet({
    required int kcal,
    required int protein,
    required int carbs,
    required int fat,
  }) async {
    final kcalController = TextEditingController(text: '$kcal');
    final proteinController = TextEditingController(text: '$protein');
    final carbsController = TextEditingController(text: '$carbs');
    final fatController = TextEditingController(text: '$fat');
    final result = await showModalBottomSheet<(int, int, int, int)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Material(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Ajustar macros',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Corrige los valores antes de registrar la comida.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _NumericField(
                          controller: kcalController,
                          label: 'Kcal',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _NumericField(
                          controller: proteinController,
                          label: 'Proteína',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _NumericField(
                          controller: carbsController,
                          label: 'Carbos',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _NumericField(
                          controller: fatController,
                          label: 'Grasas',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop((
                        int.tryParse(kcalController.text.trim()) ?? kcal,
                        int.tryParse(proteinController.text.trim()) ?? protein,
                        int.tryParse(carbsController.text.trim()) ?? carbs,
                        int.tryParse(fatController.text.trim()) ?? fat,
                      ));
                    },
                    child: const Text('Guardar ajuste'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    kcalController.dispose();
    proteinController.dispose();
    carbsController.dispose();
    fatController.dispose();
    return result;
  }

  void _showHistoryDetail(Map<String, dynamic> entry) {
    showActivityRecordDetailSheet(
      context,
      title: entry['meal_label']?.toString() ?? 'Registro nutricional',
      subtitle: (entry['logged_at']?.toString() ?? '').split('T').first,
      details: [
        MapEntry('Adherencia', '${entry['adherence_score'] ?? 0}%'),
        MapEntry('Proteína', '${entry['protein_grams'] ?? 0} g'),
        MapEntry('Hidratación', '${entry['hydration_liters'] ?? 0} L'),
      ],
      notes: entry['notes']?.toString(),
      radius: 8,
    );
  }

  void _openDayDetail(Map<String, dynamic> day) {
    final meals = (day['meals'] as List<dynamic>? ?? [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final isoDate = day['iso_date']?.toString() ?? '';
    final dayLogs = _logsForDay(isoDate);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.48,
          maxChildSize: 0.96,
          expand: false,
          builder: (context, scrollController) {
            return Material(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              color: Theme.of(context).colorScheme.surface,
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Text(
                    '${day['day_label'] ?? 'Día'} · ${day['date'] ?? ''}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dayLogs.isEmpty
                        ? (day['is_past'] == true
                              ? 'No hay comidas registradas. Aquí ves lo recomendado.'
                              : 'Plan sugerido para este día.')
                        : 'Tienes ${dayLogs.length} registro(s) para este día.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  ...meals.map((meal) {
                    final log = _matchLogForMeal(isoDate, meal);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MealTimelineCard(
                        meal: meal,
                        log: log,
                        isPast: day['is_past'] == true,
                        onTap: () => _showMealDayDetail(
                          day: day,
                          meal: meal,
                          logEntry: log,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showMealDayDetail({
    required Map<String, dynamic> day,
    required Map<String, dynamic> meal,
    Map<String, dynamic>? logEntry,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.86,
          minChildSize: 0.52,
          maxChildSize: 0.98,
          expand: false,
          builder: (context, scrollController) {
            return Material(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              color: Theme.of(context).colorScheme.surface,
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Text(
                    '${meal['title'] ?? 'Comida'} · ${day['day_label'] ?? ''}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    meal['meal_name']?.toString() ??
                        meal['meal']?.toString() ??
                        '',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 14),
                  _MacroRow(
                    kcal: meal['calories_kcal'],
                    protein: meal['protein_g'],
                    carbs: meal['carbs_g'],
                    fat: meal['fat_g'],
                  ),
                  const SizedBox(height: 18),
                  if ((meal['objective']?.toString() ?? '').isNotEmpty) ...[
                    Text(
                      'Pensado para ese día',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(meal['objective'].toString()),
                    const SizedBox(height: 18),
                  ],
                  // Recommended meal card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWarm,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: _kBrandLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.image_outlined,
                            color: _kBrand,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Comida recomendada',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                meal['meal_name']?.toString() ??
                                    meal['meal']?.toString() ??
                                    '',
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 30),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  alignment: Alignment.centerLeft,
                                ),
                                onPressed: () =>
                                    showNutritionDetailSheet(context, meal),
                                child: const Text('Ver receta y detalle'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    logEntry != null
                        ? 'Registro realizado'
                        : 'Registro del usuario',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: logEntry != null
                          ? AppColors.accentBg
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: logEntry != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Adherencia ${logEntry['adherence_score'] ?? 0}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Proteína: ${logEntry['protein_grams'] ?? 0} g',
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Hidratación: ${logEntry['hydration_liters'] ?? 0} L',
                              ),
                              if ((logEntry['notes']?.toString() ?? '')
                                  .trim()
                                  .isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(logEntry['notes'].toString()),
                              ],
                            ],
                          )
                        : Text(
                            day['is_past'] == true
                                ? 'Ese día no quedó una comida registrada para esta franja.'
                                : 'Aún no hay registro para esta comida.',
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Chip helper ──────────────────────────────────────────────────────────────

  Widget _mealLabelChips({
    required String current,
    required ValueChanged<String> onChanged,
  }) {
    const labels = ['Desayuno', 'Almuerzo', 'Cena', 'Snack'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: labels.map((label) {
        final selected = current == label;
        return ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onChanged(label),
        );
      }).toList(),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: (_isInitialLoading && _showShimmer)
              ? _buildLoading()
              : _isInitialLoading
              ? const SizedBox.shrink()
              : _viewData == null
              ? _buildError()
              : _buildContent(),
        ),
        // Full-screen photo analysis overlay
        if (_isAnalyzingPhoto)
          _AnalyzingOverlay(spinController: _analyzeSpinController),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.black26),
          const SizedBox(height: 12),
          const Text('No se pudo cargar nutrición.'),
          const SizedBox(height: 12),
          FilledButton(onPressed: _bootstrap, child: const Text('Reintentar')),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final day = _selectedDay;
    final meals = _mealsForSelectedDay;
    final weeklyDays =
        (_viewData!.summary['weekly_days'] as List<dynamic>? ?? [])
            .map((d) => Map<String, dynamic>.from(d as Map))
            .toList();
    final selectedIdx =
        _selectedDayIndex ??
        (_viewData!.summary['selected_day_index'] as int? ?? 0);

    return RefreshIndicator(
      onRefresh: _refreshSilently,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          // ── Header ──
          AppSectionTitle(
            title: 'Nutrición',
            subtitle: 'Seguimiento diario, análisis IA y plan semanal.',
          ),
          const SizedBox(height: 16),

          // ── Photo AI CTA ──
          _PhotoAnalysisCTA(
            onTap: _isSubmitting ? null : _openPhotoAnalysisFlow,
          ),
          const SizedBox(height: 12),

          // ── T-20 — Shopping list CTA ──
          _ShoppingListCTA(
            onTap: () {
              final weeklyDays =
                  (_viewData!.summary['weekly_days'] as List<dynamic>? ?? []);
              final allMeals = <dynamic>[];
              for (final day in weeklyDays) {
                final dayMap = day as Map<String, dynamic>;
                final meals = dayMap['meals'] as List<dynamic>? ?? [];
                allMeals.addAll(meals);
              }
              Navigator.of(context).pushNamed(
                '/shopping-list',
                arguments: allMeals,
              );
            },
          ),
          const SizedBox(height: 16),

          // ── Today summary card ──
          _TodaySummaryCard(summary: _viewData!.summary),
          const SizedBox(height: 14),
          _CoachSwapTipCard(
            swapTip: _viewData!.summary['swap_tip']?.toString() ?? '',
            meal: _mealForSelectedLabel,
            onViewOptions: _mealForSelectedLabel == null
                ? null
                : () => _openOptionBankSheet(_mealForSelectedLabel!),
          ),
          const SizedBox(height: 20),

          // ── Weekly calendar ──
          _SectionLabel(label: 'SEMANA'),
          const SizedBox(height: 10),
          _WeekCalendar(
            days: weeklyDays,
            selectedIndex: selectedIdx.clamp(
              0,
              math.max(0, weeklyDays.length - 1),
            ),
            logsForDay: _logsForDay,
            mealsForDay: (day) => ((day['meals'] as List<dynamic>? ?? [])
                .map((m) => Map<String, dynamic>.from(m as Map))
                .toList()),
            matchLog: _matchLogForMeal,
            onDayTap: (index, item) {
              setState(() => _selectedDayIndex = index);
              _openDayDetail(item);
            },
          ),
          const SizedBox(height: 20),

          // ── Register card ──
          _RegisterCard(
            day: day,
            mealLabel: _mealLabel,
            isSubmitting: _isSubmitting,
            onMealLabelChanged: (v) => setState(() => _mealLabel = v),
            onPhotoTap: _openPhotoAnalysisFlow,
            onManualTap: _openManualRegistration,
          ),
          const SizedBox(height: 20),

          // ── Meal timeline ──
          _SectionLabel(
            label: 'COMIDAS${day != null ? ' · ${day['day_label']}' : ''}',
          ),
          const SizedBox(height: 12),
          if (meals.isEmpty)
            EmptyStateWidget(
              icon: Icons.restaurant_rounded,
              title: 'Sin registros hoy',
              subtitle:
                  'Registra tus comidas para hacer seguimiento de tu nutrición.',
              actionLabel: 'Registrar comida',
              onAction: _openManualRegistration,
              compact: true,
            )
          else
            _MealTimeline(
              meals: meals,
              isoDate: day?['iso_date']?.toString() ?? '',
              isPast: day?['is_past'] == true,
              matchLog: _matchLogForMeal,
              onMealTap: (meal) => showNutritionDetailSheet(context, meal),
            ),
          const SizedBox(height: 20),

          // ── History ──
          _SectionLabel(label: 'HISTORIAL RECIENTE'),
          const SizedBox(height: 12),
          _HistorySection(
            history: _nutritionHistory.take(8).toList(),
            onTap: _showHistoryDetail,
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: const [
        ShimmerBox(width: double.infinity, height: 80, borderRadius: 16),
        SizedBox(height: 12),
        ShimmerBox(width: double.infinity, height: 160, borderRadius: 18),
        SizedBox(height: 12),
        ShimmerBox(width: double.infinity, height: 72, borderRadius: 12),
        SizedBox(height: 12),
        ShimmerBox(width: double.infinity, height: 120, borderRadius: 14),
        SizedBox(height: 12),
        ShimmerBox(width: double.infinity, height: 100, borderRadius: 12),
        SizedBox(height: 12),
        ShimmerBox(width: double.infinity, height: 100, borderRadius: 12),
      ],
    );
  }
}

// ─── Photo Analysis CTA ────────────────────────────────────────────────────────

class _PhotoAnalysisCTA extends StatelessWidget {
  final VoidCallback? onTap;
  const _PhotoAnalysisCTA({this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableCard(
      borderRadius: 16,
      color: _kBrand,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analizar comida con IA',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Toma o sube una foto y obtén macros al instante',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white54,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Today Summary Card ────────────────────────────────────────────────────────

class _TodaySummaryCard extends StatelessWidget {
  final Map<String, dynamic> summary;
  const _TodaySummaryCard({required this.summary});

  static double _d(Map<String, dynamic> m, String key, double fallback) {
    final v = m[key];
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    final calorieTarget = _d(summary, 'calorie_target', 2000);
    final caloriesConsumed = _d(summary, 'calories_consumed_today', 0);
    final proteinTarget = _d(summary, 'protein_target_g', 150);
    final proteinConsumed = _d(summary, 'protein_consumed_g', 0);
    final carbsTarget = _d(summary, 'carbs_target_g', 250);
    final carbsConsumed = _d(summary, 'carbs_consumed_g', 0);
    final fatTarget = _d(summary, 'fat_target_g', 65);
    final fatConsumed = _d(summary, 'fat_consumed_g', 0);
    final waterTarget = _d(summary, 'water_target_l', 2.5);
    final waterConsumed = _d(summary, 'water_consumed_l', 0);
    final macroFocus = (summary['macro_focus'] as List<dynamic>? ?? [])
        .cast<String>();

    final calProgress = calorieTarget > 0
        ? (caloriesConsumed / calorieTarget).clamp(0.0, 1.0)
        : 0.0;
    final calColor = _progressColor(
      calorieTarget > 0 ? (caloriesConsumed / calorieTarget) : 0,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryMid, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Text(
                'Hoy',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '${caloriesConsumed.round()} / ${calorieTarget.round()} kcal',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Calorie ring + macros
          Row(
            children: [
              // Ring
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: _RingPainter(
                        progress: calProgress,
                        trackColor: Colors.white12,
                        progressColor: calColor,
                        strokeWidth: 8,
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${caloriesConsumed.round()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Text(
                            'kcal',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Macro bars
              Expanded(
                child: Column(
                  children: [
                    _MacroBar(
                      label: 'Proteína',
                      consumed: proteinConsumed,
                      target: proteinTarget,
                    ),
                    const SizedBox(height: 8),
                    _MacroBar(
                      label: 'Carbos',
                      consumed: carbsConsumed,
                      target: carbsTarget,
                    ),
                    const SizedBox(height: 8),
                    _MacroBar(
                      label: 'Grasas',
                      consumed: fatConsumed,
                      target: fatTarget,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Water bar
          Row(
            children: [
              const Icon(
                Icons.water_drop_outlined,
                color: Colors.lightBlueAccent,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Agua  ${waterConsumed.toStringAsFixed(1)} / ${waterTarget.toStringAsFixed(1)} L',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: waterTarget > 0
                  ? (waterConsumed / waterTarget).clamp(0.0, 1.0)
                  : 0.0,
              minHeight: 6,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.lightBlueAccent,
              ),
            ),
          ),

          // Calorie goal label
          const SizedBox(height: 10),
          Text(
            'Objetivo: ${calorieTarget.round()} kcal · ${(calorieTarget - caloriesConsumed).clamp(0, calorieTarget).round()} restantes',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          if (macroFocus.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: macroFocus
                  .map(
                    (label) => _SmallPill(
                      label: label,
                      color: _macroFocusColor(label),
                      textColor: Colors.white,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  static Color _progressColor(double rawProgress) {
    if (rawProgress < 0.9) return AppColors.accentSuccess;
    if (rawProgress <= 1.05) return AppColors.warningAmber;
    return AppColors.error;
  }

  static Color _macroFocusColor(String label) {
    final normalized = label.toLowerCase();
    if (normalized.contains('prote')) return AppColors.accentBlue;
    if (normalized.contains('carb')) return AppColors.warningAmber;
    if (normalized.contains('gras') || normalized.contains('saciedad')) {
      return AppColors.accent;
    }
    return Colors.white.withValues(alpha: 0.16);
  }
}

// ─── Weekly Calendar ───────────────────────────────────────────────────────────

class _WeekCalendar extends StatelessWidget {
  final List<Map<String, dynamic>> days;
  final int selectedIndex;
  final List<Map<String, dynamic>> Function(String) logsForDay;
  final List<Map<String, dynamic>> Function(Map<String, dynamic>) mealsForDay;
  final Map<String, dynamic>? Function(String, Map<String, dynamic>) matchLog;
  final void Function(int, Map<String, dynamic>) onDayTap;

  const _WeekCalendar({
    required this.days,
    required this.selectedIndex,
    required this.logsForDay,
    required this.mealsForDay,
    required this.matchLog,
    required this.onDayTap,
  });

  String _logStatus(Map<String, dynamic> day) {
    final isoDate = day['iso_date']?.toString() ?? '';
    final meals = mealsForDay(day);
    if (meals.isEmpty) return 'none';
    final logCount = meals.where((m) => matchLog(isoDate, m) != null).length;
    if (logCount == 0) return 'none';
    if (logCount >= meals.length) return 'full';
    return 'partial';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = days[index];
          final selected = selectedIndex == index;
          final status = _logStatus(item);
          final dotColor = status == 'full'
              ? _kGreen
              : status == 'partial'
              ? _kAmber
              : Colors.black12;

          return GestureDetector(
            onTap: () => onDayTap(index, item),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? _kBrand
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? _kBrand : _kGrey,
                  width: selected ? 0 : 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: _kBrand.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    (item['day_label']?.toString() ?? '-')
                        .substring(0, 3)
                        .toUpperCase(),
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['date']?.toString() ?? '',
                    style: TextStyle(
                      color: selected ? Colors.white70 : Colors.black45,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: selected ? Colors.white54 : dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CoachSwapTipCard extends StatelessWidget {
  final String swapTip;
  final Map<String, dynamic>? meal;
  final VoidCallback? onViewOptions;

  const _CoachSwapTipCard({
    required this.swapTip,
    required this.meal,
    required this.onViewOptions,
  });

  @override
  Widget build(BuildContext context) {
    if (swapTip.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningPale,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.warningChip,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lightbulb_rounded, color: _kAmber),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '💡 Sugerencia del coach',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  swapTip,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black87,
                    height: 1.35,
                  ),
                ),
                if (meal != null) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _SmallPill(
                        label: meal!['title']?.toString() ?? 'Comida',
                        color: _kBrandLight,
                        textColor: _kBrand,
                      ),
                      TextButton(
                        onPressed: onViewOptions,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 32),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: Colors.white,
                          foregroundColor: _kBrand,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                            side: const BorderSide(color: AppColors.warningBorder),
                          ),
                        ),
                        child: const Text('Ver opciones'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Register Card ─────────────────────────────────────────────────────────────

class _RegisterCard extends StatelessWidget {
  final Map<String, dynamic>? day;
  final String mealLabel;
  final bool isSubmitting;
  final ValueChanged<String> onMealLabelChanged;
  final VoidCallback onPhotoTap;
  final VoidCallback onManualTap;

  const _RegisterCard({
    required this.day,
    required this.mealLabel,
    required this.isSubmitting,
    required this.onMealLabelChanged,
    required this.onPhotoTap,
    required this.onManualTap,
  });

  @override
  Widget build(BuildContext context) {
    const labels = ['Desayuno', 'Almuerzo', 'Cena', 'Snack'];
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.surfaceWarm,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Registrar ${day?['day_label'] ?? 'comida'}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: labels.map((label) {
                final selected = mealLabel == label;
                return ChoiceChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) => onMealLabelChanged(label),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isSubmitting ? null : onPhotoTap,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('Analizar foto'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isSubmitting ? null : onManualTap,
                    icon: const Icon(Icons.edit_note_rounded),
                    label: const Text('Manual'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Meal Timeline ─────────────────────────────────────────────────────────────

class _MealTimeline extends StatelessWidget {
  final List<Map<String, dynamic>> meals;
  final String isoDate;
  final bool isPast;
  final Map<String, dynamic>? Function(String, Map<String, dynamic>) matchLog;
  final void Function(Map<String, dynamic>) onMealTap;

  const _MealTimeline({
    required this.meals,
    required this.isoDate,
    required this.isPast,
    required this.matchLog,
    required this.onMealTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: meals.asMap().entries.map((entry) {
        final i = entry.key;
        final meal = entry.value;
        final log = matchLog(isoDate, meal);
        final isLast = i == meals.length - 1;
        return _MealTimelineCard(
          meal: meal,
          log: log,
          isPast: isPast,
          isLast: isLast,
          onTap: () => onMealTap(meal),
        );
      }).toList(),
    );
  }
}

class _MealTimelineCard extends StatelessWidget {
  final Map<String, dynamic> meal;
  final Map<String, dynamic>? log;
  final bool isPast;
  final bool isLast;
  final VoidCallback onTap;

  const _MealTimelineCard({
    required this.meal,
    required this.log,
    required this.isPast,
    this.isLast = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = meal['title']?.toString() ?? 'Comida';
    final mealName =
        meal['meal_name']?.toString() ?? meal['meal']?.toString() ?? '';
    final kcal = meal['calories_kcal'];
    final protein = meal['protein_g'];
    final time = meal['scheduled_time']?.toString();
    final logged = log != null;
    final mealBg = _mealColor(title);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline column
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: logged ? _kGreen : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: logged ? _kGreen : _kGrey,
                      width: 2,
                    ),
                  ),
                  child: logged
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 14,
                        )
                      : null,
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: _kGrey)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Card
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: GestureDetector(
                onTap: onTap,
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: logged ? AppColors.accentSubtle : _kGrey,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: mealBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _mealIcon(title),
                            color: _kBrand,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (time != null) ...[
                                    const Spacer(),
                                    Text(
                                      time,
                                      style: const TextStyle(
                                        color: Colors.black45,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (mealName.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  mealName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  _SmallPill(
                                    label: logged
                                        ? 'Registrada'
                                        : isPast
                                        ? 'No registrada'
                                        : 'Planificada',
                                    color: logged
                                        ? _kGreenLight
                                        : isPast
                                        ? AppColors.errorLight
                                        : _kAmberLight,
                                  ),
                                  if (kcal != null &&
                                      kcal.toString().isNotEmpty)
                                    _SmallPill(label: '$kcal kcal'),
                                  if (protein != null &&
                                      protein.toString().isNotEmpty)
                                    _SmallPill(label: 'P ${protein}g'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.black26,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── History Section ───────────────────────────────────────────────────────────

class _HistorySection extends StatelessWidget {
  final List<Map<String, dynamic>> history;
  final void Function(Map<String, dynamic>) onTap;

  const _HistorySection({required this.history, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.restaurant_rounded,
        title: 'Sin registros hoy',
        subtitle:
            'Registra tus comidas para hacer seguimiento de tu nutrición.',
        compact: true,
      );
    }

    // Group by date
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final entry in history) {
      final date = (entry['logged_at']?.toString() ?? '').split('T').first;
      grouped.putIfAbsent(date, () => []).add(entry);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((group) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date separator
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                group.key,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.black45,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            ...group.value.map(
              (entry) =>
                  _HistoryEntryCard(entry: entry, onTap: () => onTap(entry)),
            ),
            const SizedBox(height: 12),
          ],
        );
      }).toList(),
    );
  }
}

class _HistoryEntryCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  final VoidCallback onTap;

  const _HistoryEntryCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = entry['meal_label']?.toString() ?? 'Registro';
    final adherence = entry['adherence_score'] as int? ?? 0;
    final protein = entry['protein_grams'];
    final hydration = entry['hydration_liters'];
    final time = (entry['logged_at']?.toString() ?? '')
        .split('T')
        .last
        .substring(0, 5);
    final mealBg = _mealColor(label);
    final adherenceColor = adherence >= 80
        ? _kGreen
        : adherence >= 50
        ? _kAmber
        : Colors.red.shade400;

    return Dismissible(
      key: ValueKey(entry['id'] ?? entry['logged_at']),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('¿Eliminar este registro?'),
          content: Text(label),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      ),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outline_rounded, color: Colors.red.shade700),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: _kGrey),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: mealBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_mealIcon(label), color: _kBrand, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            time,
                            style: const TextStyle(
                              color: Colors.black38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _SmallPill(
                            label: '$adherence%',
                            color: adherence >= 80
                                ? _kGreenLight
                                : adherence >= 50
                                ? _kAmberLight
                                : AppColors.errorLight,
                            textColor: adherenceColor,
                          ),
                          if (protein != null)
                            _SmallPill(label: 'P ${protein}g'),
                          if (hydration != null)
                            _SmallPill(label: '${hydration}L'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Analyzing Overlay ─────────────────────────────────────────────────────────

class _AnalyzingOverlay extends StatelessWidget {
  final AnimationController spinController;
  const _AnalyzingOverlay({required this.spinController});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(40),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RotationTransition(
                turns: spinController,
                child: const Icon(
                  Icons.camera_enhance_rounded,
                  size: 56,
                  color: _kBrand,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Analizando tu comida...',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'La IA está identificando macros e ingredientes',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.black45),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Source Option Button ──────────────────────────────────────────────────────

class _SourceOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceOptionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: _kBrandLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: _kBrand),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: _kBrand,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Macro Row ─────────────────────────────────────────────────────────────────

class _MacroRow extends StatelessWidget {
  final dynamic kcal;
  final dynamic protein;
  final dynamic carbs;
  final dynamic fat;

  const _MacroRow({this.kcal, this.protein, this.carbs, this.fat});

  @override
  Widget build(BuildContext context) {
    final chips = <_MacroChipData>[];
    if (kcal != null && kcal.toString().isNotEmpty) {
      chips.add(
        _MacroChipData(
          emoji: '🔥',
          value: '$kcal',
          unit: 'kcal',
          color: AppColors.warningWarm,
        ),
      );
    }
    if (protein != null && protein.toString().isNotEmpty) {
      chips.add(
        _MacroChipData(
          emoji: '🥩',
          value: '$protein',
          unit: 'g prot',
          color: AppColors.macroProtein,
        ),
      );
    }
    if (carbs != null && carbs.toString().isNotEmpty) {
      chips.add(
        _MacroChipData(
          emoji: '🌾',
          value: '$carbs',
          unit: 'g carb',
          color: AppColors.purpleLight,
        ),
      );
    }
    if (fat != null && fat.toString().isNotEmpty) {
      chips.add(
        _MacroChipData(
          emoji: '🫙',
          value: '$fat',
          unit: 'g gras',
          color: AppColors.warningPeach,
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips.map((c) => _MacroChipWidget(data: c)).toList(),
    );
  }
}

class _PhotoSectionLabel extends StatelessWidget {
  const _PhotoSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Colors.black45,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _NumericField extends StatelessWidget {
  const _NumericField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

class _MacroChipData {
  final String emoji;
  final String value;
  final String unit;
  final Color color;
  const _MacroChipData({
    required this.emoji,
    required this.value,
    required this.unit,
    required this.color,
  });
}

class _MacroChipWidget extends StatelessWidget {
  final _MacroChipData data;
  const _MacroChipWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: data.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(data.emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.value,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Text(
                data.unit,
                style: const TextStyle(fontSize: 10, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Macro Bar (today card) ────────────────────────────────────────────────────

class _MacroBar extends StatelessWidget {
  final String label;
  final double consumed;
  final double target;

  const _MacroBar({
    required this.label,
    required this.consumed,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
    final ratio = target > 0 ? (consumed / target) : 0.0;
    final color = _TodaySummaryCard._progressColor(ratio);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            const Spacer(),
            Text(
              '${consumed.round()} / ${target.round()}g',
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// ─── Ring Painter ──────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  const _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Track
    paint.color = trackColor;
    canvas.drawCircle(center, radius, paint);

    // Progress arc
    paint.color = progressColor;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ─── Small Pill ────────────────────────────────────────────────────────────────

class _SmallPill extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? textColor;

  const _SmallPill({required this.label, this.color, this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textColor ?? Colors.black54,
        ),
      ),
    );
  }
}

// ─── Section Label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

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

// ─── Helpers ───────────────────────────────────────────────────────────────────

String _normalizeMealLabel(String value) => value.trim().toLowerCase();

// ─── View data model ───────────────────────────────────────────────────────────

class _NutritionViewData {
  const _NutritionViewData({
    required this.summary,
    required this.history,
    required this.coachingStyle,
  });

  final Map<String, dynamic> summary;
  final Map<String, dynamic> history;
  final String coachingStyle;

  _NutritionViewData copyWith({
    Map<String, dynamic>? summary,
    Map<String, dynamic>? history,
    String? coachingStyle,
  }) {
    return _NutritionViewData(
      summary: summary ?? this.summary,
      history: history ?? this.history,
      coachingStyle: coachingStyle ?? this.coachingStyle,
    );
  }
}

// ─── T-20 — Shopping list CTA widget ──────────────────────────────────────────

class _ShoppingListCTA extends StatelessWidget {
  const _ShoppingListCTA({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.brandLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accentDivider),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _kBrand,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lista de compras',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: _kBrand,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Genera tu lista semanal de ingredientes agrupados.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _kBrand),
          ],
        ),
      ),
    );
  }
}
