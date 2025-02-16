import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xenify/data/local_storage.dart';
import 'package:xenify/domain/entities/medication.dart';
import 'package:xenify/domain/entities/family_condition.dart';
import 'package:xenify/domain/entities/questionnaire_state.dart';
import 'package:xenify/domain/entities/location_data.dart';
import 'package:xenify/presentation/providers/questionnaire_provider.dart';

class QuestionnaireNotifier extends StateNotifier<QuestionnaireState> {
  QuestionnaireNotifier() : super(QuestionnaireState());

  void answerQuestion(String questionId, dynamic answer) {
    final newAnswers = {...state.answers, questionId: answer};
    final newHistory = [...state.questionHistory, state.currentQuestionIndex];

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
    } else {
      state = state.copyWith(
        answers: newAnswers,
        currentQuestionIndex: nextIndex,
        questionHistory: newHistory,
      );
    }
  }

  int _findNextQuestionIndex(String currentQuestionId, dynamic answer) {
    int currentIndex =
        questionsList.indexWhere((q) => q.id == currentQuestionId);

    // Manejar la lógica de las preguntas de ocupación
    if (currentQuestionId == 'occupation_type') {
      String occupationAnswer = answer as String;
      if (occupationAnswer != 'Trabajo' && occupationAnswer != 'Ambos') {
        // Si no trabaja, saltar la pregunta de detalles del trabajo
        return questionsList.indexWhere((q) => q.id == 'has_pathology');
      }
      // Si trabaja o estudia y trabaja, continuar con la siguiente pregunta
      return currentIndex + 1;
    }

    // Manejar el resto de la lógica de saltos
    if (currentQuestionId == 'has_pathology' && answer == false) {
      return questionsList.indexWhere((q) => q.id == 'has_family_history');
    }
    if (currentQuestionId == 'current_treatment' && answer == false) {
      return questionsList.indexWhere((q) => q.id == 'has_family_history');
    }
    if (currentQuestionId == 'has_family_history' && answer == false) {
      return questionsList.indexWhere((q) => q.id == 'digestive_issues');
    }

    // Manejar preguntas dependientes de la dieta
    if (currentQuestionId == 'diet_type') {
      String selectedDiet = answer as String;
      return questionsList.indexWhere((q) =>
          q.parentId == 'diet_type' &&
          (q.dependsOn?.contains(selectedDiet) ?? false));
    }

    // Manejar preguntas de frecuencia de proteínas
    if (currentQuestionId == 'omnivore_proteins') {
      List<String> selectedProteins = answer as List<String>;
      if (selectedProteins.isNotEmpty) {
        state = state.copyWith(
          currentProtein: selectedProteins.first,
          remainingProteins: selectedProteins.skip(1).toList(),
        );
        return questionsList.indexWhere((q) => q.id == 'protein_frequency');
      }
    }

    if (currentQuestionId == 'protein_frequency') {
      if (state.remainingProteins.isNotEmpty) {
        state = state.copyWith(
          currentProtein: state.remainingProteins.first,
          remainingProteins: state.remainingProteins.skip(1).toList(),
        );
        print('Current protein: ${state.currentProtein}');
        return currentIndex;
      }
    }

    // Si no hay saltos específicos, ir a la siguiente pregunta
    return currentIndex + 1;
  }

  void addMedication(Medication medication) {
    final currentMedications =
        (state.answers['medications'] as List<Medication>?) ?? [];
    final newMedications = [...currentMedications, medication];
    final newAnswers = {...state.answers, 'medications': newMedications};

    state = state.copyWith(answers: newAnswers);
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

      state = state.copyWith(
        currentQuestionIndex: previousIndex,
        questionHistory: newHistory,
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
}
