class PlanModification {
  final int id;
  final int userId;
  final int? planId;
  final String modificationType;
  final String targetType;
  final String? targetDayLabel;
  final String? targetBlockTitle;
  final String? targetItemName;
  final String? replacementItemName;
  final String overrideJson;
  final String? noteText;
  final bool isActive;
  final DateTime? createdAt;

  const PlanModification({
    required this.id,
    required this.userId,
    this.planId,
    required this.modificationType,
    required this.targetType,
    this.targetDayLabel,
    this.targetBlockTitle,
    this.targetItemName,
    this.replacementItemName,
    required this.overrideJson,
    this.noteText,
    required this.isActive,
    this.createdAt,
  });

  factory PlanModification.fromJson(Map<String, dynamic> json) {
    return PlanModification(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      planId: json['plan_id'] as int?,
      modificationType: json['modification_type'] as String? ?? '',
      targetType: json['target_type'] as String? ?? '',
      targetDayLabel: json['target_day_label'] as String?,
      targetBlockTitle: json['target_block_title'] as String?,
      targetItemName: json['target_item_name'] as String?,
      replacementItemName: json['replacement_item_name'] as String?,
      overrideJson: json['override_json'] as String? ?? '{}',
      noteText: json['note_text'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'modification_type': modificationType,
        'target_type': targetType,
        if (targetDayLabel != null) 'target_day_label': targetDayLabel,
        if (targetBlockTitle != null) 'target_block_title': targetBlockTitle,
        'target_item_name': targetItemName,
        if (replacementItemName != null)
          'replacement_item_name': replacementItemName,
        'override_json': overrideJson,
        if (noteText != null) 'note_text': noteText,
      };
}
