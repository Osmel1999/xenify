class FamilyCondition {
  final String condition;
  final String relative;

  FamilyCondition({
    required this.condition,
    required this.relative,
  });

  Map<String, dynamic> toJson() {
    return {
      'condition': condition,
      'relative': relative,
    };
  }

  factory FamilyCondition.fromJson(Map<String, dynamic> json) {
    return FamilyCondition(
      condition: json['condition'],
      relative: json['relative'],
    );
  }
}
