import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xenify/domain/entities/questionnaire_state.dart';
import 'package:xenify/domain/entities/user_profile.dart';

class LocalStorage {
  static const String _questionnaireKey = 'questionnaire_data';
  static const String _userProfileKey = 'user_profile';

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

  static Future<void> saveUserProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = json.encode(profile.toJson());
      print('💾 Guardando perfil en local storage: $profileJson');
      await prefs.setString(_userProfileKey, profileJson);
    } catch (e) {
      print('❌ Error guardando perfil en local storage: $e');
      rethrow;
    }
  }

  static Future<UserProfile?> loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_userProfileKey);
      if (profileJson != null) {
        print('📖 Cargando perfil desde local storage');
        final profileMap = json.decode(profileJson) as Map<String, dynamic>;
        return UserProfile.fromJson(profileMap);
      }
      print('⚠️ No se encontró perfil en local storage');
      return null;
    } catch (e) {
      print('❌ Error cargando perfil desde local storage: $e');
      return null;
    }
  }
}
