class ExerciseCatalogItem {
  final int id;
  final String name;
  final String? nameEs;
  final String? descriptionEs;
  final String? muscleGroup;
  final String? primaryMuscle;
  final String? location;
  final String? difficulty;
  final String? category;
  final bool isUnilateral;
  final int? estimatedDurationSeconds;
  final String? imageUrl;
  final String? thumbnailUrl;
  final String? videoUrl;
  final List<String> secondaryMuscles;
  final List<String> equipmentRequired;
  final List<String> equipmentAlternatives;
  final List<String> instructionsEs;
  final List<String> imageUrls;
  final List<String> tags;

  const ExerciseCatalogItem({
    required this.id,
    required this.name,
    this.nameEs,
    this.descriptionEs,
    this.muscleGroup,
    this.primaryMuscle,
    this.location,
    this.difficulty,
    this.category,
    required this.isUnilateral,
    this.estimatedDurationSeconds,
    this.imageUrl,
    this.thumbnailUrl,
    this.videoUrl,
    required this.secondaryMuscles,
    required this.equipmentRequired,
    required this.equipmentAlternatives,
    required this.instructionsEs,
    required this.imageUrls,
    required this.tags,
  });

  factory ExerciseCatalogItem.fromJson(Map<String, dynamic> json) {
    return ExerciseCatalogItem(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      nameEs: json['name_es'] as String?,
      descriptionEs: json['description_es'] as String?,
      muscleGroup: json['muscle_group'] as String?,
      primaryMuscle: json['primary_muscle'] as String?,
      location: json['location'] as String?,
      difficulty: json['difficulty'] as String?,
      category: json['category'] as String?,
      isUnilateral: json['is_unilateral'] as bool? ?? false,
      estimatedDurationSeconds: json['estimated_duration_seconds'] as int?,
      imageUrl: json['image_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      videoUrl: json['video_url'] as String?,
      secondaryMuscles:
          (json['secondary_muscles'] as List?)?.cast<String>() ?? [],
      equipmentRequired:
          (json['equipment_required'] as List?)?.cast<String>() ?? [],
      equipmentAlternatives:
          (json['equipment_alternatives'] as List?)?.cast<String>() ?? [],
      instructionsEs:
          (json['instructions_es'] as List?)?.cast<String>() ?? [],
      imageUrls: (json['image_urls'] as List?)?.cast<String>() ?? [],
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
    );
  }

  String get displayName => nameEs?.isNotEmpty == true ? nameEs! : name;
  String get displayMuscle => primaryMuscle ?? muscleGroup ?? '';
  bool get hasImage =>
      imageUrls.isNotEmpty || (imageUrl?.isNotEmpty == true);
  String? get firstImageUrl =>
      imageUrls.isNotEmpty ? imageUrls.first : imageUrl;
}
