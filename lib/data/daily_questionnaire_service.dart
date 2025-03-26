import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:xenify/domain/entities/daily_questionnaire_response.dart';
import 'package:xenify/domain/entities/daily_questionnaire_type.dart';

class DailyQuestionnaireService {
  static const String _questionnairesKey = 'daily_questionnaires';

  // Verifica si un cuestionario específico ya fue completado hoy
  static Future<bool> isQuestionnaireCompletedToday(
      DailyQuestionnaireType type) async {
    final prefs = await SharedPreferences.getInstance();
    final storedQuestionnaires = prefs.getStringList(_questionnairesKey) ?? [];

    // Obtener fecha actual en formato YYYY-MM-DD
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Buscar si existe un cuestionario del tipo especificado para el día de hoy
    for (var item in storedQuestionnaires) {
      final Map<String, dynamic> questionnaire =
          Map<String, dynamic>.from(jsonDecode(item));

      if (questionnaire['date'] == today &&
          questionnaire['questionnaireType'] == type.toString()) {
        return true;
      }
    }

    return false;
  }

  // Guarda una respuesta de cuestionario
  static Future<void> saveQuestionnaireResponse(
      DailyQuestionnaireType type, Map<String, dynamic> responses) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedQuestionnaires =
          prefs.getStringList(_questionnairesKey) ?? [];

      // Crear nuevo objeto de respuesta
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final newResponse = DailyQuestionnaireResponse(
        date: today,
        questionnaireType: type.toString(),
        responses: responses,
      );

      // Agregar a la lista de cuestionarios
      storedQuestionnaires.add(jsonEncode(newResponse.toJson()));

      // Guardar la lista actualizada
      await prefs.setStringList(_questionnairesKey, storedQuestionnaires);
    } catch (e) {
      print('Error guardando cuestionario: $e');
      rethrow;
    }
  }

  // Obtiene las respuestas de cuestionarios por tipo y fecha
  static Future<List<DailyQuestionnaireResponse>> getQuestionnaireResponses({
    DailyQuestionnaireType? type,
    DateTime? date,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedQuestionnaires =
          prefs.getStringList(_questionnairesKey) ?? [];
      final results = <DailyQuestionnaireResponse>[];

      String? dateFilter;
      if (date != null) {
        dateFilter = DateFormat('yyyy-MM-dd').format(date);
      }

      for (var item in storedQuestionnaires) {
        final questionnaire =
            DailyQuestionnaireResponse.fromJson(jsonDecode(item));

        bool matchesType =
            type == null || questionnaire.questionnaireType == type.toString();
        bool matchesDate =
            dateFilter == null || questionnaire.date == dateFilter;

        if (matchesType && matchesDate) {
          results.add(questionnaire);
        }
      }

      return results;
    } catch (e) {
      print('Error obteniendo cuestionarios: $e');
      return [];
    }
  }
}
