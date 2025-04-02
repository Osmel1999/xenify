import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;
import 'package:xenify/domain/entities/daily_questionnaire.dart';

class DailyQuestionnaireService {
  static const String _morningKey = 'morning_questionnaire';
  static const String _eveningKey = 'evening_questionnaire';
  static const String _lastCompletionKey = 'last_questionnaire_completion';
  static const String _initialSetupKey = 'initial_setup_completed';

  @protected
  final SharedPreferences _prefs;

  DailyQuestionnaireService(this._prefs);

  bool get isInitialSetupCompleted {
    final completed = _prefs.getBool(_initialSetupKey) ?? false;
    print(
        '🔍 Verificando setup inicial: ${completed ? 'Completado' : 'Pendiente'}');
    return completed;
  }

  Future<void> setInitialSetupCompleted(bool completed) async {
    print(
        '${completed ? '✅' : '❌'} Marcando setup inicial como ${completed ? 'completado' : 'pendiente'}');
    await _prefs.setBool(_initialSetupKey, completed);

    if (completed) {
      // Crear cuestionarios iniciales si es necesario según la hora actual
      final now = DateTime.now();
      final currentHour = now.hour;

      if (currentHour >= 5 && currentHour < 11) {
        print('📝 Creando cuestionario matutino inicial');
        await saveDailyQuestionnaire(
            createNewQuestionnaire(QuestionnaireType.morning));
      } else if (currentHour >= 18 && currentHour < 23) {
        print('📝 Creando cuestionario nocturno inicial');
        await saveDailyQuestionnaire(
            createNewQuestionnaire(QuestionnaireType.evening));
      }
    }
  }

  Future<void> saveDailyQuestionnaire(DailyQuestionnaire questionnaire) async {
    // Verificar el setup inicial
    if (!isInitialSetupCompleted) {
      print(
          '⚠️ Setup inicial no completado. No se pueden guardar cuestionarios.');
      return;
    }

    final key = questionnaire.isMorning ? _morningKey : _eveningKey;
    await _prefs.setString(key, jsonEncode(questionnaire.toJson()));
    await _prefs.setString(
        _lastCompletionKey, DateTime.now().toIso8601String());
  }

  DailyQuestionnaire? getTodayQuestionnaire(QuestionnaireType type) {
    // Verificar el setup inicial
    if (!isInitialSetupCompleted) {
      print('⚠️ Setup inicial no completado. No se mostrarán cuestionarios.');
      return null;
    }

    final key = type == QuestionnaireType.morning ? _morningKey : _eveningKey;
    final data = _prefs.getString(key);

    if (data != null) {
      final questionnaire = DailyQuestionnaire.fromJson(jsonDecode(data));
      // Verificar si el cuestionario es de hoy
      if (questionnaire.date.year == DateTime.now().year &&
          questionnaire.date.month == DateTime.now().month &&
          questionnaire.date.day == DateTime.now().day) {
        return questionnaire;
      }
    }
    return null;
  }

  bool shouldShowQuestionnaire(QuestionnaireType type) {
    // Verificar el setup inicial
    if (!isInitialSetupCompleted) {
      print('⚠️ Setup inicial no completado. No se mostrarán cuestionarios.');
      return false;
    }

    final now = DateTime.now();
    final currentHour = now.hour;

    // Verificar si ya se completó el cuestionario hoy
    final todayQuestionnaire = getTodayQuestionnaire(type);
    if (todayQuestionnaire?.isCompleted ?? false) {
      return false;
    }

    // Si es después de las 6 PM y no se completó el cuestionario matutino,
    // debemos mostrar un cuestionario combinado
    if (currentHour >= 18 && type == QuestionnaireType.evening) {
      final morningQuestionnaire =
          getTodayQuestionnaire(QuestionnaireType.morning);
      return morningQuestionnaire == null || !morningQuestionnaire.isCompleted;
    }

    // Para cuestionario matutino: mostrar entre 5 AM y 11 AM
    if (type == QuestionnaireType.morning) {
      return currentHour >= 5 && currentHour < 11;
    }

    // Para cuestionario nocturno: mostrar entre 6 PM y 11 PM
    return currentHour >= 18 && currentHour < 23;
  }

  bool didCompleteBothQuestionnaires() {
    // Si el setup inicial no está completado, consideramos que no hay cuestionarios
    if (!isInitialSetupCompleted) return true;

    final morning = getTodayQuestionnaire(QuestionnaireType.morning);
    final evening = getTodayQuestionnaire(QuestionnaireType.evening);

    return (morning?.isCompleted ?? false) && (evening?.isCompleted ?? false);
  }

  DailyQuestionnaire createNewQuestionnaire(QuestionnaireType type) {
    return DailyQuestionnaire(
      type: type,
      date: DateTime.now(),
    );
  }

  List<String> getPendingQuestions(QuestionnaireType type) {
    final List<String> questions = [];
    final currentHour = DateTime.now().hour;
    final isCombinedQuestionnaire = currentHour >= 18 &&
        getTodayQuestionnaire(QuestionnaireType.morning) == null;

    if (type == QuestionnaireType.morning || isCombinedQuestionnaire) {
      questions.addAll([
        '¿Cómo calificarías la calidad de tu sueño?',
        '¿Cuáles son tus niveles de energía al despertar?',
        '¿Cuál es tu estado de ánimo al despertar?',
        '¿Has ido al baño esta mañana?',
        '¿Qué desayunaste?',
      ]);
    }

    if (type == QuestionnaireType.evening) {
      questions.addAll([
        '¿Cuáles fueron tus niveles de energía durante el día?',
        '¿Cuál fue tu estado de ánimo durante el día?',
        '¿Cuántas veces fuiste al baño hoy?',
        '¿Qué almorzaste?',
        '¿Qué cenaste?',
      ]);
    }

    return questions;
  }
}
