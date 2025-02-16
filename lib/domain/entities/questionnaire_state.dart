import 'package:xenify/domain/entities/family_condition.dart';
import 'package:xenify/domain/entities/medication.dart';
import 'package:xenify/domain/entities/location_data.dart';

class QuestionnaireState {
  final int currentQuestionIndex;
  final Map<String, dynamic> answers;
  final bool isCompleted;
  final List<int> questionHistory;
  final List<FamilyCondition> familyConditions;
  final List<Medication> medications;
  final LocationData? locationData;
  final String? currentProtein;
  final List<String> remainingProteins;

  QuestionnaireState({
    this.currentQuestionIndex = 0,
    this.answers = const {},
    this.isCompleted = false,
    this.questionHistory = const [],
    this.familyConditions = const [],
    this.medications = const [],
    this.locationData,
    this.currentProtein,
    this.remainingProteins = const [],
  });

  QuestionnaireState copyWith({
    int? currentQuestionIndex,
    Map<String, dynamic>? answers,
    bool? isCompleted,
    List<int>? questionHistory,
    List<FamilyCondition>? familyConditions,
    List<Medication>? medications,
    LocationData? locationData,
    String? currentProtein,
    List<String>? remainingProteins,
  }) {
    return QuestionnaireState(
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      answers: answers ?? this.answers,
      isCompleted: isCompleted ?? this.isCompleted,
      questionHistory: questionHistory ?? this.questionHistory,
      familyConditions: familyConditions ?? this.familyConditions,
      medications: medications ?? this.medications,
      locationData: locationData ?? this.locationData,
      currentProtein: currentProtein ?? this.currentProtein,
      remainingProteins: remainingProteins ?? this.remainingProteins,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentQuestionIndex': currentQuestionIndex,
      'answers':
          _encodeAnswers(answers), // Nuevo método para codificar respuestas
      'isCompleted': isCompleted,
      'questionHistory': questionHistory,
      'familyConditions': familyConditions.map((c) => c.toJson()).toList(),
      'medications': medications.map((m) => m.toJson()).toList(),
      'locationData': locationData?.toJson(),
      'currentProtein': currentProtein,
      'remainingProteins': remainingProteins,
    };
  }

  // Nuevo método para codificar respuestas que pueden contener DateTime
  Map<String, dynamic> _encodeAnswers(Map<String, dynamic> answers) {
    final encodedAnswers = <String, dynamic>{};
    answers.forEach((key, value) {
      if (value is DateTime) {
        encodedAnswers[key] = value.toIso8601String();
      } else if (value is List) {
        encodedAnswers[key] = _encodeList(value);
      } else {
        encodedAnswers[key] = value;
      }
    });
    return encodedAnswers;
  }

  // Método auxiliar para codificar listas
  List<dynamic> _encodeList(List<dynamic> list) {
    return list.map((item) {
      if (item is DateTime) {
        return item.toIso8601String();
      } else if (item is Map) {
        return _encodeMap(item);
      } else {
        return item;
      }
    }).toList();
  }

  // Método auxiliar para codificar mapas
  Map<String, dynamic> _encodeMap(Map<dynamic, dynamic> map) {
    final encodedMap = <String, dynamic>{};
    map.forEach((key, value) {
      if (value is DateTime) {
        encodedMap[key.toString()] = value.toIso8601String();
      } else if (value is List) {
        encodedMap[key.toString()] = _encodeList(value);
      } else if (value is Map) {
        encodedMap[key.toString()] = _encodeMap(value);
      } else {
        encodedMap[key.toString()] = value;
      }
    });
    return encodedMap;
  }

  factory QuestionnaireState.fromJson(Map<String, dynamic> json) {
    return QuestionnaireState(
      currentQuestionIndex: json['currentQuestionIndex'] as int,
      answers: _decodeAnswers(json['answers'] as Map<String, dynamic>),
      isCompleted: json['isCompleted'] as bool,
      questionHistory: List<int>.from(json['questionHistory'] as List),
      familyConditions: (json['familyConditions'] as List)
          .map((c) => FamilyCondition.fromJson(c as Map<String, dynamic>))
          .toList(),
      medications: (json['medications'] as List)
          .map((m) => Medication.fromJson(m as Map<String, dynamic>))
          .toList(),
      locationData: json['locationData'] != null
          ? LocationData.fromJson(json['locationData'] as Map<String, dynamic>)
          : null,
      currentProtein: json['currentProtein'] as String?,
      remainingProteins: List<String>.from(json['remainingProteins'] ?? []),
    );
  }

  // Nuevo método estático para decodificar respuestas
  static Map<String, dynamic> _decodeAnswers(Map<String, dynamic> answers) {
    final decodedAnswers = <String, dynamic>{};
    answers.forEach((key, value) {
      if (value is String && value.contains('T')) {
        try {
          decodedAnswers[key] = DateTime.parse(value);
        } catch (e) {
          decodedAnswers[key] = value;
        }
      } else if (value is List) {
        decodedAnswers[key] = _decodeList(value);
      } else {
        decodedAnswers[key] = value;
      }
    });
    return decodedAnswers;
  }

  // Método auxiliar para decodificar listas
  static List<dynamic> _decodeList(List<dynamic> list) {
    return list.map((item) {
      if (item is String && item.contains('T')) {
        try {
          return DateTime.parse(item);
        } catch (e) {
          return item;
        }
      } else if (item is Map) {
        return _decodeMap(item);
      } else {
        return item;
      }
    }).toList();
  }

  // Método auxiliar para decodificar mapas
  static Map<String, dynamic> _decodeMap(Map<dynamic, dynamic> map) {
    final decodedMap = <String, dynamic>{};
    map.forEach((key, value) {
      if (value is String && value.contains('T')) {
        try {
          decodedMap[key.toString()] = DateTime.parse(value);
        } catch (e) {
          decodedMap[key.toString()] = value;
        }
      } else if (value is List) {
        decodedMap[key.toString()] = _decodeList(value);
      } else if (value is Map) {
        decodedMap[key.toString()] = _decodeMap(value);
      } else {
        decodedMap[key.toString()] = value;
      }
    });
    return decodedMap;
  }
}
