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

    print('\n📋 Verificando estado de cuestionarios:');
    print('🕒 Hora actual: $currentHour:${now.minute}');

    // Obtener estado actual de cuestionarios
    final morningQuestionnaire =
        _service.getTodayQuestionnaire(QuestionnaireType.morning);
    final eveningQuestionnaire =
        _service.getTodayQuestionnaire(QuestionnaireType.evening);

    print('\n📊 Estado actual:');
    print(
        '- Matutino: ${morningQuestionnaire?.isCompleted == true ? "Completado" : "Pendiente"}');
    print(
        '- Nocturno: ${eveningQuestionnaire?.isCompleted == true ? "Completado" : "Pendiente"}');

    // Si es hora del cuestionario nocturno y el matutino está pendiente
    if (currentHour >= 18 && currentHour < 23) {
      if (morningQuestionnaire == null || !morningQuestionnaire.isCompleted) {
        print('\n🌙 Horario nocturno detectado con matutino pendiente');
        print('📝 Creando cuestionario combinado (matutino + nocturno)');
        state = _service.createNewQuestionnaire(QuestionnaireType.evening);
        return;
      } else {
        // Solo crear cuestionario nocturno si es necesario
        if (eveningQuestionnaire == null || !eveningQuestionnaire.isCompleted) {
          print('📝 Creando cuestionario nocturno');
          state = _service.createNewQuestionnaire(QuestionnaireType.evening);
          return;
        }
      }
    }
    // Horario matutino
    else if (currentHour >= 5 && currentHour < 11) {
      if (morningQuestionnaire == null || !morningQuestionnaire.isCompleted) {
        print('📝 Creando cuestionario matutino');
        state = _service.createNewQuestionnaire(QuestionnaireType.morning);
        return;
      }
    }

    // Si no hay cuestionario pendiente para la hora actual
    print('✅ No hay cuestionarios pendientes para este horario');
    state = null;
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

    try {
      print('🔄 Completando cuestionario ${state!.type}...');
      final completedQuestionnaire = state!.copyWith(isCompleted: true);
      final morningQuestionnaire =
          _service.getTodayQuestionnaire(QuestionnaireType.morning);
      final eveningQuestionnaire =
          _service.getTodayQuestionnaire(QuestionnaireType.evening);

      // Caso 1: Cuestionario nocturno con matutino pendiente (cuestionario combinado)
      if (state!.type == QuestionnaireType.evening &&
          (morningQuestionnaire == null || !morningQuestionnaire.isCompleted)) {
        print('📝 Procesando cuestionario combinado...');

        // Crear o actualizar cuestionario matutino con campos compartidos
        final updatedMorningQuestionnaire = (morningQuestionnaire ??
                _service.createNewQuestionnaire(QuestionnaireType.morning))
            .copyWith(
          // Solo sincronizar campos que tienen sentido compartir
          energyLevel: completedQuestionnaire.energyLevel,
          mood: completedQuestionnaire.mood,
          isCompleted: true,
          // No sincronizar campos específicos del momento:
          // - sleepQuality (específico de la mañana)
          // - bathroomEntries (específicos de cada momento)
          // - meals (específicos de cada momento)
        );

        print('💾 Guardando cuestionario matutino con datos compartidos');
        await _service.saveDailyQuestionnaire(updatedMorningQuestionnaire);
      }
      // Caso 2: Cuestionario matutino cuando ya existe el nocturno completado
      else if (state!.type == QuestionnaireType.morning &&
          eveningQuestionnaire != null &&
          eveningQuestionnaire.isCompleted) {
        print(
            '🔄 Actualizando respuestas compartidas con cuestionario nocturno...');
        // Actualizar el nocturno con los valores más recientes
        final updatedEveningQuestionnaire = eveningQuestionnaire.copyWith(
          energyLevel: completedQuestionnaire.energyLevel,
          mood: completedQuestionnaire.mood,
        );
        await _service.saveDailyQuestionnaire(updatedEveningQuestionnaire);
      }

      // Guardar el cuestionario actual
      print('\n💾 Guardando cuestionario ${state!.type}');
      await _service.saveDailyQuestionnaire(completedQuestionnaire);
      state = completedQuestionnaire;

      print('✅ Cuestionario completado exitosamente');
      print('\n📊 Estado final de cuestionarios:');
      print(
          '- Matutino: ${_service.getTodayQuestionnaire(QuestionnaireType.morning)?.isCompleted ?? false}');
      print(
          '- Nocturno: ${_service.getTodayQuestionnaire(QuestionnaireType.evening)?.isCompleted ?? false}');

      // Verificar si hay más cuestionarios pendientes
      _checkAndLoadQuestionnaire();
    } catch (e) {
      print('❌ Error al completar cuestionario: $e');
      rethrow;
    }
  }
}
