import 'package:flutter/foundation.dart';

enum QuestionnaireType {
  morning,
  evening,
}

enum BathroomType {
  urination,
  defecation,
}

class BathroomEntry {
  final BathroomType type;
  final String color;
  final String consistency;
  final bool didFloat; // Solo para defecación
  final DateTime timestamp;

  BathroomEntry({
    required this.type,
    required this.color,
    required this.consistency,
    this.didFloat = false,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'type': type.toString(),
        'color': color,
        'consistency': consistency,
        'didFloat': didFloat,
        'timestamp': timestamp.toIso8601String(),
      };

  factory BathroomEntry.fromJson(Map<String, dynamic> json) {
    return BathroomEntry(
      type: BathroomType.values.firstWhere((e) => e.toString() == json['type'],
          orElse: () => BathroomType.urination),
      color: json['color'],
      consistency: json['consistency'],
      didFloat: json['didFloat'] ?? false,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class DailyQuestionnaire {
  final QuestionnaireType type;
  final DateTime date;
  final int? sleepQuality; // 1-5
  final int? energyLevel; // 1-5
  final int? mood; // 1-5
  final List<BathroomEntry> bathroomEntries;
  final List<String> meals; // Desayuno, almuerzo, cena
  final bool isCompleted;

  DailyQuestionnaire({
    required this.type,
    required this.date,
    this.sleepQuality,
    this.energyLevel,
    this.mood,
    this.bathroomEntries = const [],
    this.meals = const [],
    this.isCompleted = false,
  });

  bool get isMorning => type == QuestionnaireType.morning;
  bool get isEvening => type == QuestionnaireType.evening;

  DailyQuestionnaire copyWith({
    QuestionnaireType? type,
    DateTime? date,
    int? sleepQuality,
    int? energyLevel,
    int? mood,
    List<BathroomEntry>? bathroomEntries,
    List<String>? meals,
    bool? isCompleted,
  }) {
    return DailyQuestionnaire(
      type: type ?? this.type,
      date: date ?? this.date,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      energyLevel: energyLevel ?? this.energyLevel,
      mood: mood ?? this.mood,
      bathroomEntries: bathroomEntries ?? this.bathroomEntries,
      meals: meals ?? this.meals,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.toString(),
        'date': date.toIso8601String(),
        'sleepQuality': sleepQuality,
        'energyLevel': energyLevel,
        'mood': mood,
        'bathroomEntries':
            bathroomEntries.map((entry) => entry.toJson()).toList(),
        'meals': meals,
        'isCompleted': isCompleted,
      };

  factory DailyQuestionnaire.fromJson(Map<String, dynamic> json) {
    return DailyQuestionnaire(
      type: QuestionnaireType.values.firstWhere(
          (e) => e.toString() == json['type'],
          orElse: () => QuestionnaireType.morning),
      date: DateTime.parse(json['date']),
      sleepQuality: json['sleepQuality'],
      energyLevel: json['energyLevel'],
      mood: json['mood'],
      bathroomEntries: (json['bathroomEntries'] as List?)
              ?.map((e) => BathroomEntry.fromJson(e))
              .toList() ??
          [],
      meals: (json['meals'] as List?)?.map((e) => e as String).toList() ?? [],
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}
