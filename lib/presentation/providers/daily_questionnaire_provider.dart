import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xenify/data/daily_questionnaire_service.dart';
import 'package:xenify/domain/entities/daily_questionnaire.dart';

// Este provider debe inicializarse en el main.dart con el valor real de SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'Debes sobrescribir este provider con una instancia real de SharedPreferences',
  );
});

final dailyQuestionnaireServiceProvider =
    Provider<DailyQuestionnaireService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return DailyQuestionnaireService(prefs);
});

final currentQuestionnaireProvider =
    StateNotifierProvider<CurrentQuestionnaireNotifier, DailyQuestionnaire?>(
        (ref) {
  final service = ref.watch(dailyQuestionnaireServiceProvider);
  return CurrentQuestionnaireNotifier(service);
});

class CurrentQuestionnaireNotifier extends StateNotifier<DailyQuestionnaire?> {
  final DailyQuestionnaireService _service;

  CurrentQuestionnaireNotifier(this._service) : super(null) {
    _checkAndLoadQuestionnaire();
  }

  void _checkAndLoadQuestionnaire() {
    final now = DateTime.now();
    final currentHour = now.hour;

    // Determinar qué tipo de cuestionario mostrar basado en la hora
    QuestionnaireType type;
    if (currentHour >= 5 && currentHour < 11) {
      type = QuestionnaireType.morning;
    } else if (currentHour >= 18 && currentHour < 23) {
      type = QuestionnaireType.evening;
    } else {
      state = null;
      return;
    }

    // Verificar si ya existe un cuestionario para hoy
    final existingQuestionnaire = _service.getTodayQuestionnaire(type);
    if (existingQuestionnaire != null && !existingQuestionnaire.isCompleted) {
      state = existingQuestionnaire;
      return;
    }

    // Si no hay cuestionario o ya está completado, verificar si debemos mostrar uno nuevo
    if (_service.shouldShowQuestionnaire(type)) {
      state = _service.createNewQuestionnaire(type);
    } else {
      state = null;
    }
  }

  Future<void> saveQuestionnaire(DailyQuestionnaire questionnaire) async {
    await _service.saveDailyQuestionnaire(questionnaire);
    state = questionnaire;
  }

  List<String> getPendingQuestions() {
    if (state == null) return [];
    return _service.getPendingQuestions(state!.type);
  }

  bool shouldShowQuestionnaire() {
    if (state == null) return false;
    return _service.shouldShowQuestionnaire(state!.type);
  }

  void updateAnswers({
    int? sleepQuality,
    int? energyLevel,
    int? mood,
    List<BathroomEntry>? bathroomEntries,
    List<String>? meals,
  }) {
    if (state == null) return;

    state = state!.copyWith(
      sleepQuality: sleepQuality ?? state!.sleepQuality,
      energyLevel: energyLevel ?? state!.energyLevel,
      mood: mood ?? state!.mood,
      bathroomEntries: bathroomEntries ?? state!.bathroomEntries,
      meals: meals ?? state!.meals,
    );
  }

  void completeQuestionnaire() async {
    if (state == null) return;

    final completedQuestionnaire = state!.copyWith(isCompleted: true);
    await _service.saveDailyQuestionnaire(completedQuestionnaire);
    state = completedQuestionnaire;

    // Verificar si necesitamos cargar el siguiente cuestionario
    _checkAndLoadQuestionnaire();
  }
}
