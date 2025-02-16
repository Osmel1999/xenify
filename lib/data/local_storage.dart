import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xenify/domain/entities/questionnaire_state.dart';

class LocalStorage {
  static const String _questionnaireKey = 'questionnaire_data';

  static Future<void> saveQuestionnaireData(QuestionnaireState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = json.encode(state.toJson());
      print('Saving data: $stateJson'); // Para depuración
      await prefs.setString(_questionnaireKey, stateJson);
    } catch (e) {
      print('Error saving data: $e');
      rethrow;
    }
  }

  static Future<QuestionnaireState?> loadQuestionnaireData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString(_questionnaireKey);
      if (stateJson != null) {
        print('Loading data: $stateJson'); // Para depuración
        final stateMap = json.decode(stateJson) as Map<String, dynamic>;
        return QuestionnaireState.fromJson(stateMap);
      }
      return null;
    } catch (e) {
      print('Error loading data: $e');
      return null;
    }
  }
}
