import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_section_title.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../data/services/onboarding_api_service.dart';
import '../../domain/models/onboarding_profile.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _goalOptions = [
    'Perder grasa',
    'Ganar musculo',
    'Mejorar condicion fisica',
    'Mantenerme activo',
    'Rendimiento deportivo',
    'Recuperar habitos',
  ];
  static const _activityOptions = [
    'Principiante',
    'Intermedio',
    'Avanzado',
  ];
  static const _workoutDayOptions = [2, 3, 4, 5, 6, 7];
  static const _sessionMinuteOptions = [30, 45, 60, 75, 90];
  static const _trainingLocationOptions = [
    'Casa',
    'Gimnasio',
    'Mixto',
  ];
  static const _cookingStyleOptions = [
    'Simple',
    'Batch cooking',
    'Cocino a diario',
    'Casi no cocino',
  ];
  static const _mealsPerDayOptions = [3, 4, 5, 6];
  static const _equipmentOptions = [
    'Mancuernas',
    'Banda',
    'Barra',
    'Banco',
    'Peso corporal',
    'Bicicleta',
    'Maquinas de gimnasio',
    'Poleas',
    'Discos y rack',
    'Kettlebells',
    'TRX',
    'Eliptica',
    'Caminadora',
    'Remo',
    'Escaladora',
    'Balon medicinal',
    'Cuerda',
    'Box o step',
    'Piscina',
    'Saco de boxeo',
    'Smith machine',
    'Prensa',
    'Jaula de sentadilla',
    'Barras EZ',
    'Otra',
  ];
  static const _dietOptions = [
    'Alto en proteina',
    'Balanceado',
    'Deficit calorico',
    'Volumen',
    'Vegetariano',
    'Vegano',
    'Pescetariano',
    'Mediterraneo',
    'Keto',
    'Low carb',
    'Ayuno intermitente',
    'Sin azucar anadida',
    'Sin lacteos',
    'Sin gluten',
    'Comidas rapidas',
    'Meal prep',
    'Otra',
  ];
  static const _allergyOptions = [
    'Ninguna',
    'Lactosa',
    'Gluten',
    'Frutos secos',
    'Mariscos',
    'Huevo',
    'Soya',
    'Otra',
  ];
  static const _restrictionOptions = [
    'Ninguna',
    'Rodilla sensible',
    'Espalda baja sensible',
    'Hombro sensible',
    'Cuello sensible',
    'Tobillo sensible',
    'Muneca sensible',
    'Cadera sensible',
    'Poco tiempo',
    'Estres alto',
    'Sueno irregular',
    'Trabajo sedentario',
    'Entreno en casa',
    'Equipo limitado',
    'Otra',
  ];

  final _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController(text: '30');
  final _heightController = TextEditingController(text: '175');
  final _weightController = TextEditingController(text: '78');
  final _foodDislikesController = TextEditingController();
  final _additionalNotesController = TextEditingController();
  final _otherEquipmentController = TextEditingController();
  final _otherDietController = TextEditingController();
  final _otherRestrictionController = TextEditingController();
  final _otherAllergyController = TextEditingController();
  final Map<String, TextEditingController> _measurementControllers = {
    'waist_cm': TextEditingController(),
    'hip_cm': TextEditingController(),
    'chest_cm': TextEditingController(),
    'arm_cm': TextEditingController(),
    'thigh_cm': TextEditingController(),
    'calf_cm': TextEditingController(),
    'neck_cm': TextEditingController(),
    'body_fat_pct': TextEditingController(),
  };

  String _selectedGoal = _goalOptions.first;
  String _selectedActivity = 'Intermedio';
  int _selectedWorkoutDays = 4;
  int _selectedSessionMinutes = 45;
  String _selectedTrainingLocation = 'Mixto';
  String _selectedCookingStyle = 'Simple';
  int _selectedMealsPerDay = 4;
  final Set<String> _selectedEquipment = {'Mancuernas', 'Banda'};
  final Set<String> _selectedDiet = {'Alto en proteina'};
  final Set<String> _selectedAllergies = {'Ninguna'};
  final Set<String> _selectedRestrictions = {'Ninguna'};

  int _step = 0;
  bool _isSubmitting = false;
  bool _isLoading = true;
  bool _hasExistingProfile = false;

  @override
  void initState() {
    super.initState();
    _loadLatestProfile();
  }

  Future<void> _loadLatestProfile() async {
    try {
      final profile = await const OnboardingApiService().fetchLatestProfile();
      if (profile != null) {
        _applyProfile(profile);
        _hasExistingProfile = true;
      }
    } catch (_) {
      // Keep defaults when latest profile is unavailable.
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyProfile(OnboardingProfile profile) {
    _nameController.text = profile.fullName;
    _ageController.text = '${profile.age}';
    _heightController.text = '${profile.heightCm}';
    _weightController.text = '${profile.weightKg}';
    _selectedGoal = _goalOptions.contains(profile.goal)
        ? profile.goal
        : _goalOptions.first;
    _selectedActivity = _activityOptions.contains(profile.activityLevel)
        ? profile.activityLevel
        : 'Intermedio';
    _selectedWorkoutDays = _workoutDayOptions.contains(profile.workoutDaysPerWeek)
        ? profile.workoutDaysPerWeek
        : 4;
    _selectedSessionMinutes =
        _sessionMinuteOptions.contains(profile.sessionMinutes)
            ? profile.sessionMinutes
            : 45;
    _selectedTrainingLocation =
        _trainingLocationOptions.contains(profile.trainingLocation)
            ? profile.trainingLocation
            : 'Mixto';
    _selectedCookingStyle = _cookingStyleOptions.contains(profile.cookingStyle)
        ? profile.cookingStyle
        : 'Simple';
    _selectedMealsPerDay = _mealsPerDayOptions.contains(profile.mealsPerDay)
        ? profile.mealsPerDay
        : 4;
    _foodDislikesController.text = profile.foodDislikes.join(', ');
    _additionalNotesController.text = profile.additionalNotes;

    _selectedEquipment
      ..clear()
      ..addAll(
        profile.equipment.isEmpty
            ? {'Mancuernas', 'Banda'}
            : profile.equipment.map(_normalizeSelectableValue),
      );
    _selectedDiet
      ..clear()
      ..addAll(
        profile.dietaryPreferences.isEmpty
            ? {'Alto en proteina'}
            : profile.dietaryPreferences.map(_normalizeSelectableValue),
      );
    _selectedAllergies
      ..clear()
      ..addAll(
        profile.allergies.isEmpty
            ? {'Ninguna'}
            : profile.allergies.map(_normalizeSelectableValue),
      );
    _selectedRestrictions
      ..clear()
      ..addAll(
        profile.restrictions.isEmpty
            ? {'Ninguna'}
            : profile.restrictions.map(_normalizeSelectableValue),
      );

    for (final entry in _measurementControllers.entries) {
      final value = profile.bodyMeasurements[entry.key];
      entry.value.text = value == null || value == 0 ? '' : '$value';
    }

    _syncOtherValuesFromProfile(profile);
  }

  String _normalizeLabel(String value) {
    return value
        .split(' ')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String _normalizeSelectableValue(String value) {
    final normalized = _normalizeLabel(value);
    if (_equipmentOptions.contains(normalized) ||
        _dietOptions.contains(normalized) ||
        _restrictionOptions.contains(normalized) ||
        _allergyOptions.contains(normalized)) {
      return normalized;
    }
    return 'Otra';
  }

  void _syncOtherValuesFromProfile(OnboardingProfile profile) {
    _otherEquipmentController.text = _extractCustomValues(
      profile.equipment,
      _equipmentOptions,
    ).join(', ');
    _otherDietController.text = _extractCustomValues(
      profile.dietaryPreferences,
      _dietOptions,
    ).join(', ');
    _otherAllergyController.text = _extractCustomValues(
      profile.allergies,
      _allergyOptions,
      excludedBaseValues: {'Ninguna'},
    ).join(', ');
    _otherRestrictionController.text = _extractCustomValues(
      profile.restrictions,
      _restrictionOptions,
      excludedBaseValues: {'Ninguna'},
    ).join(', ');
  }

  List<String> _extractCustomValues(
    List<String> values,
    List<String> catalog, {
    Set<String> excludedBaseValues = const {},
  }) {
    final known = catalog
        .where((item) => item != 'Otra' && !excludedBaseValues.contains(item))
        .toSet();
    return values
        .where((item) => !known.contains(_normalizeLabel(item)))
        .toList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _foodDislikesController.dispose();
    _additionalNotesController.dispose();
    _otherEquipmentController.dispose();
    _otherDietController.dispose();
    _otherRestrictionController.dispose();
    _otherAllergyController.dispose();
    for (final controller in _measurementControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _nextStep() async {
    if (_step == 5) {
      await _submit();
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _step += 1;
    });
    await _pageController.animateToPage(
      _step,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _previousStep() async {
    if (_step == 0) return;

    setState(() {
      _step -= 1;
    });
    await _pageController.animateToPage(
      _step,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final profile = OnboardingProfile(
      fullName: _nameController.text.trim(),
      age: int.parse(_ageController.text),
      heightCm: int.parse(_heightController.text),
      weightKg: int.parse(_weightController.text),
      goal: _selectedGoal,
      activityLevel: _selectedActivity,
      workoutDaysPerWeek: _selectedWorkoutDays,
      sessionMinutes: _selectedSessionMinutes,
      trainingLocation: _selectedTrainingLocation,
      cookingStyle: _selectedCookingStyle,
      mealsPerDay: _selectedMealsPerDay,
      dietaryPreferences: _buildSelectedValues(
        selected: _selectedDiet,
        otherController: _otherDietController,
        excludeNone: true,
      ),
      allergies: _buildSelectedValues(
        selected: _selectedAllergies,
        otherController: _otherAllergyController,
        excludeNone: true,
      ),
      equipment: _buildSelectedValues(
        selected: _selectedEquipment,
        otherController: _otherEquipmentController,
      ),
      foodDislikes: _foodDislikesController.text
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(),
      restrictions: _buildSelectedValues(
        selected: _selectedRestrictions,
        otherController: _otherRestrictionController,
        excludeNone: true,
      ),
      bodyMeasurements: _buildBodyMeasurements(),
      additionalNotes: _additionalNotesController.text.trim(),
    );

    try {
      await const OnboardingApiService().submitProfile(profile);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos guardar tu perfil base.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Map<String, double> _buildBodyMeasurements() {
    final result = <String, double>{};
    for (final entry in _measurementControllers.entries) {
      final value = double.tryParse(entry.value.text.trim());
      if (value != null && value > 0) {
        result[entry.key] = value;
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final title = _hasExistingProfile
        ? 'Actualizar plan base'
        : 'Completar onboarding';
    final subtitle = _hasExistingProfile
        ? 'Edita tus datos actuales para recalibrar entrenamiento y nutricion.'
        : 'Vamos a construir un plan mucho mas personalizado desde el inicio.';

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSectionTitle(title: title, subtitle: subtitle),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: (_step + 1) / 6,
                        minHeight: 10,
                        backgroundColor: const Color(0xFFE6DED1),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _StepLayout(
                      title: 'Identidad y objetivo',
                      description:
                          _hasExistingProfile
                              ? 'Tu nombre ya vive en perfil. Aqui ajustamos direccion actual.'
                              : 'Definimos objetivo, nivel y punto de partida.',
                      child: Column(
                        children: [
                          if (!_hasExistingProfile)
                            _buildField(_nameController, 'Nombre completo'),
                          _buildDropdown(
                            label: 'Objetivo principal',
                            value: _selectedGoal,
                            options: _goalOptions,
                            onChanged: (value) => setState(() {
                              _selectedGoal = value!;
                            }),
                          ),
                          _buildDropdown(
                            label: 'Nivel de experiencia',
                            value: _selectedActivity,
                            options: _activityOptions,
                            onChanged: (value) => setState(() {
                              _selectedActivity = value!;
                            }),
                          ),
                          _buildDropdown(
                            label: 'Entrenas principalmente en',
                            value: _selectedTrainingLocation,
                            options: _trainingLocationOptions,
                            onChanged: (value) => setState(() {
                              _selectedTrainingLocation = value!;
                            }),
                          ),
                        ],
                      ),
                    ),
                    _StepLayout(
                      title: 'Datos base',
                      description:
                          'Medidas generales para personalizar volumen, carga y referencia inicial.',
                      child: Column(
                        children: [
                          _buildField(_ageController, 'Edad', isNumeric: true),
                          _buildField(
                            _heightController,
                            'Estatura (cm)',
                            isNumeric: true,
                          ),
                          _buildField(
                            _weightController,
                            'Peso (kg)',
                            isNumeric: true,
                          ),
                        ],
                      ),
                    ),
                    _StepLayout(
                      title: 'Contexto de entrenamiento',
                      description:
                          'Frecuencia real, duracion y equipo disponible.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDropdown(
                            label: 'Dias por semana',
                            value: _selectedWorkoutDays,
                            options: _workoutDayOptions,
                            onChanged: (value) => setState(() {
                              _selectedWorkoutDays = value!;
                            }),
                          ),
                          _buildDropdown(
                            label: 'Minutos por sesion',
                            value: _selectedSessionMinutes,
                            options: _sessionMinuteOptions,
                            onChanged: (value) => setState(() {
                              _selectedSessionMinutes = value!;
                            }),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Equipo disponible',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 10),
                          _buildMultiSelectChips(
                            options: _equipmentOptions,
                            selected: _selectedEquipment,
                            otherController: _otherEquipmentController,
                          ),
                        ],
                      ),
                    ),
                    _StepLayout(
                      title: 'Nutricion y estilo de vida',
                      description:
                          'Esto mejora el plan semanal, las alternativas y el nivel de adherencia.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDropdown(
                            label: 'Como sueles cocinar',
                            value: _selectedCookingStyle,
                            options: _cookingStyleOptions,
                            onChanged: (value) => setState(() {
                              _selectedCookingStyle = value!;
                            }),
                          ),
                          _buildDropdown(
                            label: 'Comidas al dia',
                            value: _selectedMealsPerDay,
                            options: _mealsPerDayOptions,
                            onChanged: (value) => setState(() {
                              _selectedMealsPerDay = value!;
                            }),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Preferencias nutricionales',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 10),
                          _buildMultiSelectChips(
                            options: _dietOptions,
                            selected: _selectedDiet,
                            otherController: _otherDietController,
                            allowNone: false,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Alergias o intolerancias',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 10),
                          _buildMultiSelectChips(
                            options: _allergyOptions,
                            selected: _selectedAllergies,
                            otherController: _otherAllergyController,
                            singleNoneOption: true,
                          ),
                          const SizedBox(height: 18),
                          _buildField(
                            _foodDislikesController,
                            'Alimentos que no te gustan (separados por coma)',
                            isOptional: true,
                          ),
                        ],
                      ),
                    ),
                    _StepLayout(
                      title: 'Restricciones y medidas opcionales',
                      description:
                          'Puedes dejar las medidas vacias si aun no quieres registrarlas.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Restricciones o molestias',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 10),
                          _buildMultiSelectChips(
                            options: _restrictionOptions,
                            selected: _selectedRestrictions,
                            otherController: _otherRestrictionController,
                            singleNoneOption: true,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Medidas corporales opcionales',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: _measurementControllers.entries.map((entry) {
                              return SizedBox(
                                width: 150,
                                child: TextFormField(
                                  controller: entry.value,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: _measurementLabel(entry.key),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    _StepLayout(
                      title: 'Contexto extra',
                      description:
                          'Ultimo paso. Cuentanos lo que la app deberia considerar para personalizar mejor.',
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _additionalNotesController,
                            minLines: 5,
                            maxLines: 8,
                            decoration: const InputDecoration(
                              labelText: 'Notas adicionales',
                              hintText:
                                  'Ejemplo: trabajo sentado muchas horas, me cuesta desayunar temprano, tengo ansiedad en la noche, quiero priorizar gluteo, etc.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _step == 0 || _isSubmitting
                            ? null
                            : _previousStep,
                        child: const Text('Anterior'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isSubmitting ? null : _nextStep,
                        child: Text(
                          _isSubmitting
                              ? 'Guardando...'
                              : _step == 5
                                  ? (_hasExistingProfile
                                      ? 'Actualizar plan'
                                      : 'Generar plan')
                                  : 'Continuar',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label, {
    bool isNumeric = false,
    bool isOptional = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        validator: (value) {
          if (isOptional) {
            return null;
          }
          if (value == null || value.trim().isEmpty) {
            return 'Este campo es obligatorio';
          }
          return null;
        },
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> options,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        items: options
            .map(
              (option) => DropdownMenuItem<T>(
                value: option,
                child: Text(option.toString()),
              ),
            )
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _buildMultiSelectChips({
    required List<String> options,
    required Set<String> selected,
    TextEditingController? otherController,
    bool allowNone = true,
    bool singleNoneOption = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (value) {
                setState(() {
                  if (singleNoneOption && option == 'Ninguna') {
                    selected
                      ..clear()
                      ..add('Ninguna');
                    return;
                  }

                  if (singleNoneOption) {
                    selected.remove('Ninguna');
                  }

                  if (value) {
                    selected.add(option);
                  } else {
                    selected.remove(option);
                  }

                  if (selected.isEmpty && allowNone && singleNoneOption) {
                    selected.add('Ninguna');
                  }
                });
              },
            );
          }).toList(),
        ),
        if (otherController != null && selected.contains('Otra')) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: otherController,
            decoration: const InputDecoration(
              labelText: 'Escribe otra opcion',
              hintText: 'Puedes separar varias por coma',
            ),
            validator: (_) {
              if (selected.contains('Otra') &&
                  otherController.text.trim().isEmpty) {
                return 'Escribe al menos una opcion personalizada';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  List<String> _buildSelectedValues({
    required Set<String> selected,
    required TextEditingController otherController,
    bool excludeNone = false,
  }) {
    final values = selected
        .where((item) => item != 'Otra' && (!excludeNone || item != 'Ninguna'))
        .toList();
    final customValues = otherController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    return [...values, ...customValues];
  }

  String _measurementLabel(String key) {
    return switch (key) {
      'waist_cm' => 'Cintura (cm)',
      'hip_cm' => 'Cadera (cm)',
      'chest_cm' => 'Pecho (cm)',
      'arm_cm' => 'Brazo (cm)',
      'thigh_cm' => 'Muslo (cm)',
      'calf_cm' => 'Pantorrilla (cm)',
      'neck_cm' => 'Cuello (cm)',
      'body_fat_pct' => 'Grasa corporal (%)',
      _ => key,
    };
  }
}

class _StepLayout extends StatelessWidget {
  const _StepLayout({
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      children: [
        AppSurfaceCard(
          backgroundColor: const Color(0xFFE7DED1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 10),
              Text(description),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppSurfaceCard(child: child),
      ],
    );
  }
}
