import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xenify/data/local_storage.dart';
import 'package:xenify/data/notification_service.dart';
import 'package:xenify/data/provider_container.dart';
import 'package:xenify/domain/entities/medication.dart';
import 'package:xenify/domain/entities/family_condition.dart';
import 'package:xenify/domain/entities/question.dart';
import 'package:xenify/domain/entities/questionnaire_state.dart';
import 'package:xenify/domain/entities/location_data.dart';
import 'package:xenify/domain/entities/meal_notification_config.dart';
import 'package:xenify/presentation/providers/auth_provider.dart';
import 'package:xenify/presentation/providers/questionnaire_provider.dart';

class QuestionnaireNotifier extends StateNotifier<QuestionnaireState> {
  final NotificationService _notificationService;

  QuestionnaireNotifier(this._notificationService)
      : super(QuestionnaireState(currentQuestionIndex: 0));

  void answerQuestion(String questionId, dynamic answer) {
    // Preparar las actualizaciones básicas del estado
    final newAnswers = {...state.answers, questionId: answer};
    final newHistory = [...state.questionHistory, state.currentQuestionIndex];

    // Determinar la siguiente pregunta
    int nextIndex = _findNextQuestionIndex(questionId, answer);

    if (nextIndex >= questionsList.length) {
      final newState = state.copyWith(
        answers: newAnswers,
        isCompleted: true,
        questionHistory: newHistory,
      );
      state = newState;

      // Guardar datos cuando se completa el cuestionario
      LocalStorage.saveQuestionnaireData(newState);

      // Manejar respuestas relacionadas con los horarios de las comidas
      _handleMealTimeAnswers();
    } else {
      state = state.copyWith(
        answers: newAnswers,
        currentQuestionIndex: nextIndex,
        questionHistory: newHistory,
      );
    }

    // Verificar si necesitamos cargar más preguntas
    _checkAndLoadMoreQuestions();
  }

  void _handleMealTimeAnswers() {
    final breakfastTime = state.answers['breakfast_time'] as String?;
    final lunchTime = state.answers['lunch_time'] as String?;
    final dinnerTime = state.answers['dinner_time'] as String?;

    final mealConfigs = <MealNotificationConfig>[];

    if (breakfastTime != null && breakfastTime != 'No aplica') {
      mealConfigs.add(MealNotificationConfig(
        mealType: 'breakfast',
        time: _convertTimeFormat(breakfastTime),
      ));
    }

    if (lunchTime != null && lunchTime != 'No aplica') {
      mealConfigs.add(MealNotificationConfig(
        mealType: 'lunch',
        time: _convertTimeFormat(lunchTime),
      ));
    }

    if (dinnerTime != null && dinnerTime != 'No aplica') {
      mealConfigs.add(MealNotificationConfig(
        mealType: 'dinner',
        time: _convertTimeFormat(dinnerTime),
      ));
    }

    if (mealConfigs.isNotEmpty) {
      _notificationService.schedulePostMealNotifications(mealConfigs);
    }
  }

  String _convertTimeFormat(String timeRange) {
    // Manejar casos especiales
    if (timeRange.startsWith('Después de las')) {
      // Para "Después de las X:00", usar la hora mencionada
      return timeRange.replaceAll('Después de las ', '').trim();
    }

    if (timeRange == 'No aplica') {
      return '00:00'; // Valor por defecto para "No aplica"
    }

    // Para rangos normales como "6:00 - 7:00"
    try {
      final times = timeRange.split(' - ');
      return times[0]; // Usar la hora de inicio
    } catch (e) {
      print('Error parsing time range: $timeRange');
      return '00:00'; // Valor por defecto en caso de error
    }
  }

  void addMedication(Medication medication) async {
    try {
      print('📱 Intentando agregar medicamento: ${medication.name}');

      // Programar notificaciones para el nuevo medicamento
      await _notificationService.scheduleMedicationNotifications(
        medication.name,
        medication.nextDose,
        medication.endDate,
        medication.intervalHours,
      );

      // Continuar con la lógica normal
      final currentMedications =
          (state.answers['medications'] as List<Medication>?) ?? [];
      final newMedications = [...currentMedications, medication];
      final newAnswers = {...state.answers, 'medications': newMedications};

      state = state.copyWith(answers: newAnswers);
      print('✅ Medicamento agregado correctamente');
    } catch (e) {
      print('❌ Error en addMedication: $e');
      rethrow;
    }
  }

  void deleteMedication(int index) async {
    try {
      final currentMedications =
          (state.answers['medications'] as List<Medication>?) ?? [];
      if (index >= 0 && index < currentMedications.length) {
        final medicationToDelete = currentMedications[index];

        // Cancelar las notificaciones programadas para este medicamento
        await _notificationService.cancelMedicationNotifications(
          medicationToDelete.name,
          medicationToDelete.nextDose,
        );

        final newMedications = List<Medication>.from(currentMedications)
          ..removeAt(index);
        final newAnswers = {...state.answers, 'medications': newMedications};
        state = state.copyWith(answers: newAnswers);
      }
    } catch (e) {
      print('Error deleting medication: $e');
      // Aquí podrías manejar el error, por ejemplo, mostrando un mensaje al usuario
      rethrow;
    }
  }

  void updateFamilyConditions(List<FamilyCondition> conditions) {
    final newAnswers = {...state.answers, 'family_conditions': conditions};
    state = state.copyWith(answers: newAnswers);
  }

  void goBack() {
    if (state.questionHistory.isNotEmpty) {
      final newHistory = List<int>.from(state.questionHistory)..removeLast();
      final previousIndex =
          state.questionHistory.isNotEmpty ? state.questionHistory.last : 0;

      // Si estamos volviendo a una pregunta de frecuencia de proteínas,
      // necesitamos restaurar el texto personalizado
      final previousQuestion = questionsList[previousIndex];
      String? customText;
      if (previousQuestion.id == 'gluten_free_protein_frequency' &&
          state.currentProtein != null) {
        customText = previousQuestion.text
            .replaceAll('%protein%', state.currentProtein!.toLowerCase());
      }

      state = state.copyWith(
        currentQuestionIndex: previousIndex < 0 ? 0 : previousIndex,
        questionHistory: newHistory,
        currentQuestionText: customText,
      );
    }
  }

  void updateLocation(LocationData locationData) {
    final newAnswers = {...state.answers, 'location': locationData};
    state = state.copyWith(
      answers: newAnswers,
      locationData: locationData,
    );
  }

  void updateAnswer(String questionId, dynamic answer) {
    final newAnswers = {...state.answers, questionId: answer};
    state = state.copyWith(answers: newAnswers);
  }

  // El resto de la lógica para _findNextQuestionIndex y otros métodos
  int _findNextQuestionIndex(String currentQuestionId, dynamic answer) {
    int currentIndex =
        questionsList.indexWhere((q) => q.id == currentQuestionId);

    if (currentQuestionId == 'occupation_type') {
      String occupationAnswer = answer as String;
      if (occupationAnswer != 'Trabajo' && occupationAnswer != 'Ambos') {
        return questionsList.indexWhere((q) => q.id == 'wake_up_time');
      }
      return currentIndex + 1;
    }

    if (currentQuestionId == 'has_pathology' && answer == false) {
      return questionsList.indexWhere((q) => q.id == 'has_family_history');
    }
    if (currentQuestionId == 'current_treatment' && answer == false) {
      return questionsList.indexWhere((q) => q.id == 'has_family_history');
    }
    if (currentQuestionId == 'has_family_history' && answer == false) {
      return questionsList.indexWhere((q) => q.id == 'digestive_issues');
    }

    if (currentQuestionId == 'diet_type') {
      String selectedDiet = answer as String;
      int nextIndex = questionsList.indexWhere((q) =>
          q.parentId == 'diet_type' &&
          (q.dependsOn?.contains(selectedDiet) ?? false));

      // Siempre limpiar el estado relacionado con proteínas al cambiar de dieta
      state = state.copyWith(
        currentProtein: null,
        remainingProteins: const [],
        currentQuestionText: null,
      );

      // Si no se encuentra una pregunta específica para la dieta, ir a las preguntas comunes
      if (nextIndex < 0) {
        return questionsList.indexWhere((q) => q.id == 'vegetables');
      }
      return nextIndex;
    }

    // Manejar las preguntas específicas para dieta vegetariana
    if (currentQuestionId == 'vegetarian_proteins') {
      List<String> selectedProteins = answer as List<String>;
      if (selectedProteins.isNotEmpty) {
        try {
          final frequencyQuestion = questionsList.firstWhere(
            (q) => q.id == 'protein_frequency',
          );

          // Guardar texto personalizado en el estado
          final customText = frequencyQuestion.text
              .replaceAll('%protein%', selectedProteins.first.toLowerCase());

          state = state.copyWith(
            currentProtein: selectedProteins.first,
            remainingProteins: selectedProteins.skip(1).toList(),
            currentQuestionText: customText,
          );
          int nextIndex =
              questionsList.indexWhere((q) => q.id == 'protein_frequency');
          return nextIndex >= 0
              ? nextIndex
              : questionsList.indexWhere((q) => q.id == 'vegetables');
        } catch (e) {
          // Si hay algún error, continuar con las preguntas de verduras
          state = state.copyWith(currentQuestionText: null);
          return questionsList.indexWhere((q) => q.id == 'vegetables');
        }
      }
      return questionsList.indexWhere((q) => q.id == 'vegetables');
    }

    if (currentQuestionId == 'omnivore_proteins') {
      List<String> selectedProteins = answer as List<String>;
      if (selectedProteins.isNotEmpty) {
        try {
          final frequencyQuestion = questionsList.firstWhere(
            (q) => q.id == 'protein_frequency',
          );

          // Guardar texto personalizado en el estado
          final customText = frequencyQuestion.text
              .replaceAll('%protein%', selectedProteins.first.toLowerCase());

          state = state.copyWith(
            currentProtein: selectedProteins.first,
            remainingProteins: selectedProteins.skip(1).toList(),
            currentQuestionText: customText,
          );
          int nextIndex =
              questionsList.indexWhere((q) => q.id == 'protein_frequency');
          return nextIndex >= 0
              ? nextIndex
              : questionsList.indexWhere((q) => q.id == 'vegetables');
        } catch (e) {
          // Si hay algún error, limpiar el estado y continuar con verduras
          state = state.copyWith(
            currentQuestionText: null,
            currentProtein: null,
            remainingProteins: const [],
          );
          return questionsList.indexWhere((q) => q.id == 'vegetables');
        }
      }
      // Si no se seleccionaron proteínas, ir a las preguntas de verduras
      return questionsList.indexWhere((q) => q.id == 'vegetables');
    }

    // Manejar la transición después de responder sobre sustitutos sin gluten
    if (currentQuestionId == 'gluten_substitutes') {
      int nextIndex =
          questionsList.indexWhere((q) => q.id == 'gluten_free_proteins');
      return nextIndex >= 0
          ? nextIndex
          : questionsList.indexWhere((q) => q.id == 'vegetables');
    }

    // Manejar las preguntas de proteínas para dieta sin gluten
    if (currentQuestionId == 'gluten_free_proteins') {
      List<String> selectedProteins = answer as List<String>;
      if (selectedProteins.isNotEmpty) {
        try {
          final frequencyQuestion = questionsList.firstWhere(
            (q) => q.id == 'gluten_free_protein_frequency',
          );

          // Guardar texto personalizado en el estado
          final customText = frequencyQuestion.text
              .replaceAll('%protein%', selectedProteins.first.toLowerCase());

          state = state.copyWith(
            currentProtein: selectedProteins.first,
            remainingProteins: selectedProteins.skip(1).toList(),
            currentQuestionText: customText,
          );

          int nextIndex = questionsList
              .indexWhere((q) => q.id == 'gluten_free_protein_frequency');
          return nextIndex >= 0
              ? nextIndex
              : questionsList.indexWhere((q) => q.id == 'vegetables');
        } catch (e) {
          // Si no se encuentra la pregunta de frecuencia, ir a verduras
          return questionsList.indexWhere((q) => q.id == 'vegetables');
        }
      }
      return questionsList.indexWhere((q) => q.id == 'vegetables');
    }

    if (currentQuestionId == 'gluten_free_protein_frequency') {
      if (state.remainingProteins.isNotEmpty) {
        try {
          final frequencyQuestion = questionsList.firstWhere(
            (q) => q.id == 'gluten_free_protein_frequency',
          );

          final nextProtein = state.remainingProteins.first;
          final customText = frequencyQuestion.text
              .replaceAll('%protein%', nextProtein.toLowerCase());

          state = state.copyWith(
            currentProtein: nextProtein,
            remainingProteins: state.remainingProteins.skip(1).toList(),
            currentQuestionText: customText,
          );
          return currentIndex;
        } catch (e) {
          // En caso de error, limpiar estado y continuar con verduras
          state = state.copyWith(
            currentQuestionText: null,
            currentProtein: null,
            remainingProteins: const [],
          );
          return questionsList.indexWhere((q) => q.id == 'vegetables');
        }
      }

      // Si no hay más proteínas, limpiar estado y continuar con verduras
      state = state.copyWith(
        currentQuestionText: null,
        currentProtein: null,
        remainingProteins: const [],
      );
      return questionsList.indexWhere((q) => q.id == 'vegetables');
    }

    if (currentQuestionId == 'protein_frequency') {
      if (state.remainingProteins.isNotEmpty) {
        try {
          final frequencyQuestion = questionsList.firstWhere(
            (q) => q.id == 'protein_frequency',
          );

          final nextProtein = state.remainingProteins.first;
          final customText = frequencyQuestion.text
              .replaceAll('%protein%', nextProtein.toLowerCase());

          state = state.copyWith(
            currentProtein: nextProtein,
            remainingProteins: state.remainingProteins.skip(1).toList(),
            currentQuestionText: customText,
          );
          return currentIndex;
        } catch (e) {
          // En caso de error, limpiar estado y continuar con verduras
          state = state.copyWith(
            currentQuestionText: null,
            currentProtein: null,
            remainingProteins: const [],
          );
          return questionsList.indexWhere((q) => q.id == 'vegetables');
        }
      }

      // Si no hay más proteínas, limpiar estado y continuar con verduras
      state = state.copyWith(
        currentQuestionText: null,
        currentProtein: null,
        remainingProteins: const [],
      );
      return questionsList.indexWhere((q) => q.id == 'vegetables');
    }

    return currentIndex + 1;
  }

  // Método para marcar el cuestionario como completado
  void completeQuestionnaire() async {
    try {
      final authNotifier =
          providerContainer.read(authNotifierProvider.notifier);
      await authNotifier.markInitialQuestionnaireCompleted();

      // Marcar como completado en el estado local también
      state = state.copyWith(isCompleted: true);
    } catch (e) {
      print('Error al completar cuestionario: $e');
    }
  }

  /// Configura el modo de rendimiento bajo para dispositivos con recursos limitados
  void setLowPerformanceMode(bool enabled) {
    state = state.copyWith(isLowPerformanceMode: enabled);

    // Guardar estado actualizado
    LocalStorage.saveQuestionnaireData(state);
  }

  /// Carga el siguiente lote de preguntas de forma progresiva
  void _loadNextQuestionsBatch() {
    final currentLoaded = state.loadedQuestions.length;
    final totalQuestions = questionsList.length;

    // Si ya tenemos todas las preguntas cargadas, no hacemos nada
    if (currentLoaded >= totalQuestions) return;

    // Calcular el fin del próximo lote (no exceder el total)
    final endIndex = (currentLoaded + state.batchSize).clamp(0, totalQuestions);

    // Crear nueva lista con preguntas adicionales
    final updatedQuestions = List<Question>.from(state.loadedQuestions)
      ..addAll(questionsList.sublist(currentLoaded, endIndex));

    // Actualizar estado
    state = state.copyWith(loadedQuestions: updatedQuestions);

    // Guardar estado actualizado
    LocalStorage.saveQuestionnaireData(state);
  }

  /// Verifica si es necesario cargar más preguntas basado en el índice actual
  void _checkAndLoadMoreQuestions() {
    final currentIndex = state.currentQuestionIndex;
    final loadedCount = state.loadedQuestions.length;

    // Si estamos a 5 preguntas del final de las cargadas, cargamos más
    if (currentIndex >= loadedCount - 5 && loadedCount < questionsList.length) {
      _loadNextQuestionsBatch();
    }
  }
}
