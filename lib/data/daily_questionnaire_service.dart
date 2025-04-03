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

  // Factory constructor para usar cuando no se tiene acceso al provider
  static Future<DailyQuestionnaireService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return DailyQuestionnaireService(prefs);
  }

  bool get isInitialSetupCompleted {
    final completedInitialQuestionnaire =
        _prefs.getBool('completedInitialQuestionnaire') ?? false;
    print(
        '🔍 Verificando setup inicial: ${completedInitialQuestionnaire ? 'Completado' : 'Pendiente'}');
    return completedInitialQuestionnaire;
  }

  Future<void> syncInitialSetupWithFirestore(bool isCompleted) async {
    print(
        '🔄 Sincronizando estado del setup inicial con Firestore: $isCompleted');
    await setInitialSetupCompleted(isCompleted);
  }

  Future<void> setInitialSetupCompleted(bool completed) async {
    print('\n🔄 Actualizando estado del setup inicial:');
    print(
        '${completed ? '✅' : '❌'} Estado: ${completed ? 'completado' : 'pendiente'}');

    await _prefs.setBool('completedInitialQuestionnaire', completed);

    // No creamos cuestionarios inmediatamente al completar el setup
    // El DailyQuestionnaireProvider se encargará de esto cuando sea necesario
  }

  Future<void> saveDailyQuestionnaire(DailyQuestionnaire questionnaire) async {
    try {
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
      print('✅ Cuestionario ${questionnaire.type} guardado correctamente');
    } catch (e) {
      print('❌ Error al guardar cuestionario: $e');
      rethrow;
    }
  }

  DailyQuestionnaire? getTodayQuestionnaire(QuestionnaireType type) {
    try {
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
    } catch (e) {
      print('❌ Error al obtener cuestionario: $e');
      return null;
    }
  }

  bool shouldShowQuestionnaire(QuestionnaireType type) {
    try {
      // Verificar el setup inicial
      if (!isInitialSetupCompleted) {
        print('⚠️ Setup inicial no completado. No se mostrarán cuestionarios.');
        return false;
      }
      final now = DateTime.now();
      final currentHour = now.hour;
      print('🕒 Verificando cuestionarios a las $currentHour:${now.minute}');

      final morningQuestionnaire =
          getTodayQuestionnaire(QuestionnaireType.morning);
      final eveningQuestionnaire =
          getTodayQuestionnaire(QuestionnaireType.evening);

      // Es hora del cuestionario matutino (5 AM - 11 AM)
      if (currentHour >= 5 && currentHour < 11) {
        print('🌅 Periodo matutino (5 AM - 11 AM)');
        if (type == QuestionnaireType.morning) {
          final shouldShow =
              morningQuestionnaire == null || !morningQuestionnaire.isCompleted;
          print(shouldShow
              ? '📝 Cuestionario matutino pendiente'
              : '✅ Cuestionario matutino ya completado');
          return shouldShow;
        }
        print('❌ No es horario para cuestionario nocturno');
        return false;
      }

      // Es hora del cuestionario nocturno (6 PM - 11 PM)
      if (currentHour >= 18 && currentHour < 23) {
        print('🌙 Periodo nocturno (6 PM - 11 PM)');
        if (type == QuestionnaireType.evening) {
          // Si no se completó el matutino, mostrar cuestionario combinado
          if (morningQuestionnaire == null ||
              !morningQuestionnaire.isCompleted) {
            print(
                '📝 Mostrando cuestionario combinado (matutino pendiente + nocturno)');
            return true;
          }
          // Si el matutino está completo, mostrar solo nocturno si no está completo
          final shouldShow =
              eveningQuestionnaire == null || !eveningQuestionnaire.isCompleted;
          print(shouldShow
              ? '📝 Cuestionario nocturno pendiente'
              : '✅ Cuestionario nocturno ya completado');
          return shouldShow;
        }
        print('❌ No es horario para cuestionario matutino');
        return false;
      }

      return false;
    } catch (e) {
      print('❌ Error al verificar si se debe mostrar cuestionario: $e');
      return false;
    }
  }

  bool didCompleteBothQuestionnaires() {
    try {
      print('\n📊 Verificando estado de cuestionarios diarios:');

      // Si el setup inicial no está completado, consideramos que no hay cuestionarios
      if (!isInitialSetupCompleted) {
        print('ℹ️ Setup inicial no completado, retornando true');
        return true;
      }

      final currentHour = DateTime.now().hour;
      print('🕒 Hora actual: $currentHour:${DateTime.now().minute}');

      final morning = getTodayQuestionnaire(QuestionnaireType.morning);
      final evening = getTodayQuestionnaire(QuestionnaireType.evening);

      print(
          '- Matutino: ${morning?.isCompleted ?? false ? "Completado" : "Pendiente"}');
      print(
          '- Nocturno: ${evening?.isCompleted ?? false ? "Completado" : "Pendiente"}');

      // Antes de las 5 AM, no hay cuestionarios pendientes
      if (currentHour < 5) {
        print(
            '🌃 Horario nocturno (12 AM - 5 AM): No hay cuestionarios pendientes');
        return true;
      }

      // Entre 5 AM y 11 AM, solo verificar matutino
      if (currentHour >= 5 && currentHour < 11) {
        final completed = morning?.isCompleted ?? false;
        print(
            '🌅 Horario matutino (5 AM - 11 AM): ${completed ? "Completado" : "Pendiente"}');
        return completed;
      }

      // Entre 11 AM y 6 PM, verificar solo matutino
      if (currentHour >= 11 && currentHour < 18) {
        final completed = morning?.isCompleted ?? false;
        print(
            '☀️ Horario diurno (11 AM - 6 PM): ${completed ? "Matutino completado" : "Matutino pendiente"}');
        return completed;
      }

      // Después de las 6 PM, verificar ambos
      final bothCompleted =
          (morning?.isCompleted ?? false) && (evening?.isCompleted ?? false);
      print(
          '🌙 Horario nocturno (6 PM - 12 AM): ${bothCompleted ? "Ambos completados" : "Pendientes por completar"}');
      return bothCompleted;
    } catch (e) {
      print('❌ Error al verificar estado de cuestionarios diarios: $e');
      return false;
    }
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
    final morningQuestionnaire =
        getTodayQuestionnaire(QuestionnaireType.morning);
    print(
        '📋 Estado del cuestionario matutino: ${morningQuestionnaire?.isCompleted ?? false ? "Completado" : "Pendiente"}');
    final isCombinedQuestionnaire = currentHour >= 18 &&
        (morningQuestionnaire == null || !morningQuestionnaire.isCompleted);
    if (isCombinedQuestionnaire) {
      print('🔄 Se mostrará cuestionario combinado');
    }

    // Preguntas matutinas
    if (type == QuestionnaireType.morning ||
        (type == QuestionnaireType.evening && isCombinedQuestionnaire)) {
      questions.addAll([
        '¿Cómo calificarías la calidad de tu sueño?',
        '¿Cuáles son tus niveles de energía al despertar?',
        '¿Cuál es tu estado de ánimo al despertar?',
        '¿Has ido al baño esta mañana?',
        '¿Qué desayunaste?',
      ]);
    }

    // Preguntas nocturnas (siempre se incluyen en el cuestionario nocturno)
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
