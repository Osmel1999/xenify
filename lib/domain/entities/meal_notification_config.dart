class MealNotificationConfig {
  final String mealType; // 'breakfast', 'lunch', 'dinner'
  final String time; // formato HH:mm
  final bool isEnabled;

  MealNotificationConfig({
    required this.mealType,
    required this.time,
    this.isEnabled = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'mealType': mealType,
      'time': time,
      'isEnabled': isEnabled,
    };
  }

  factory MealNotificationConfig.fromJson(Map<String, dynamic> json) {
    return MealNotificationConfig(
      mealType: json['mealType'],
      time: json['time'],
      isEnabled: json['isEnabled'],
    );
  }
}
