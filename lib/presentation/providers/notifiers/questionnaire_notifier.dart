import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xenify/data/local_storage.dart';
import 'package:xenify/data/notification_service.dart';
import 'package:xenify/data/provider_container.dart';
import 'package:xenify/domain/entities/medication.dart';
import 'package:xenify/domain/entities/family_condition.dart';
import 'package:xenify/domain/entities/question.dart';
import 'package:xenify/domain/entities/questionnaire_state.dart';
import 'package:xenify/domain/entities/location_data.dart';
import 'package:xenify/presentation/providers/auth_provider.dart';
import 'package:xenify/presentation/providers/questionnaire_provider.dart';

class QuestionnaireNotifier extends StateNotifier<QuestionnaireState> {
  final NotificationService _notificationService;

  QuestionnaireNotifier(this._notificationService)
      : super(QuestionnaireState(currentQuestionIndex: 0));

  void answerQuestion(String questionId, dynamic answer) {
    print('\n🔍 DEBUG - answerQuestion:');
    print('📍 ID de pregunta: $questionId');
    print('📥 Respuesta recibida: $answer');

    // Preparar las actualizaciones básicas del estado
    final newAnswers = {...state.answers, questionId: answer};
    final newHistory = [...state.questionHistory, state.currentQuestionIndex];

    // Procesar horarios para notificaciones si es necesario
    if (questionId == 'bed_time' || questionId == 'wake_up_time') {
      if (answer is DateTime) {
        _handleTimeAnswers(questionId, answer, newAnswers);
      } else {
        print(
            '⚠️ Advertencia: Se esperaba DateTime pero se recibió ${answer.runtimeType}');
      }
    }

    // Determinar la siguiente pregunta
    int nextIndex =
        _findNextQuestionWithDependencies(questionId, answer, newAnswers);

    if (nextIndex >= questionsList.length) {
      state = state.copyWith(
        answers: newAnswers,
        isCompleted: true,
        questionHistory: newHistory,
      );
      LocalStorage.saveQuestionnaireData(state);
    } else {
      final nextQuestion = questionsList[nextIndex];
      String questionText = nextQuestion.text;

      state = state.copyWith(
        answers: newAnswers,
        currentQuestionIndex: nextIndex,
        questionHistory: newHistory,
        currentQuestionText: questionText,
      );
    }

    _checkAndLoadMoreQuestions();
  }

  void _handleTimeAnswers(
      String questionId, DateTime timeValue, Map<String, dynamic> answers) {
    print('🕒 Procesando respuesta de horario:');
    print('- Pregunta: $questionId');
    print('- Hora: ${timeValue.hour}:${timeValue.minute}');

    // Normalizar la fecha recibida con la fecha actual
    final now = DateTime.now();
    final normalizedTime = DateTime(
      now.year,
      now.month,
      now.day,
      timeValue.hour,
      timeValue.minute,
    );

    // Actualizar el valor en answers con la fecha normalizada
    answers[questionId] = normalizedTime;

    // Obtener ambos horarios (ya normalizados)
    final wakeUpTime = questionId == 'wake_up_time'
        ? normalizedTime
        : answers['wake_up_time'] as DateTime?;

    final bedTime = questionId == 'bed_time'
        ? normalizedTime
        : answers['bed_time'] as DateTime?;

    // Si tenemos ambos horarios, programar notificaciones
    if (wakeUpTime != null && bedTime != null) {
      print('✅ Ambos horarios disponibles, programando notificaciones:');
      print('- Despertar: ${wakeUpTime.hour}:${wakeUpTime.minute}');
      print('- Dormir: ${bedTime.hour}:${bedTime.minute}');

      _notificationService.scheduleWakeAndSleepNotifications(
          wakeUpTime, bedTime);
    }
  }

  void updateAnswer(String questionId, dynamic answer) {
    final newAnswers = {...state.answers, questionId: answer};
    state = state.copyWith(answers: newAnswers);
  }

  void completeQuestionnaire() async {
    try {
      final authNotifier =
          providerContainer.read(authNotifierProvider.notifier);
      await authNotifier.markInitialQuestionnaireCompleted();
      state = state.copyWith(isCompleted: true);
    } catch (e) {
      print('Error al completar cuestionario: $e');
    }
  }

  void goBack() {
    if (state.questionHistory.isEmpty) return;

    final newHistory = List<int>.from(state.questionHistory)..removeLast();
    final previousIndex =
        state.questionHistory.isNotEmpty ? state.questionHistory.last : 0;

    state = state.copyWith(
      currentQuestionIndex: previousIndex,
      questionHistory: newHistory,
    );
  }

  void setLowPerformanceMode(bool enabled) {
    state = state.copyWith(isLowPerformanceMode: enabled);
    LocalStorage.saveQuestionnaireData(state);
  }

  void addMedication(Medication medication) async {
    try {
      print('🔔 Programando recordatorios para medicamento:');
      print('- Nombre: ${medication.name}');
      print('- Próxima dosis: ${medication.nextDose}');
      print('- Intervalo: ${medication.intervalHours} horas');

      // Programar notificaciones para el medicamento
      await _notificationService.scheduleMedicationNotifications(
        medication.name,
        medication.nextDose,
        medication.endDate,
        medication.intervalHours,
      );

      // Actualizar el estado con el nuevo medicamento
      List<Medication> currentMedications = [];
      if (state.answers['medications'] != null) {
        if (state.answers['medications'] is List) {
          currentMedications = (state.answers['medications'] as List)
              .map((item) {
                if (item is Medication) return item;
                if (item is Map<String, dynamic>)
                  return Medication.fromJson(item);
                return null;
              })
              .whereType<Medication>()
              .toList();
        }
      }

      currentMedications.add(medication);
      final newAnswers = {...state.answers, 'medications': currentMedications};
      state = state.copyWith(answers: newAnswers);

      print(
          '✅ Medicamento agregado y notificaciones programadas correctamente');
    } catch (e) {
      print('❌ Error al programar notificaciones del medicamento: $e');
      rethrow;
    }
  }

  void deleteMedication(int index) async {
    try {
      List<Medication> medications = [];
      if (state.answers['medications'] is List) {
        medications = (state.answers['medications'] as List)
            .map((item) {
              if (item is Medication) return item;
              if (item is Map<String, dynamic>)
                return Medication.fromJson(item);
              return null;
            })
            .whereType<Medication>()
            .toList();
      }

      if (index >= 0 && index < medications.length) {
        final medicationToDelete = medications[index];
        print('🗑️ Eliminando recordatorios del medicamento:');
        print('- Nombre: ${medicationToDelete.name}');

        // Cancelar las notificaciones del medicamento
        await _notificationService.cancelMedicationNotifications(
          medicationToDelete.name,
          medicationToDelete.nextDose,
        );

        // Eliminar el medicamento del estado
        medications.removeAt(index);
        final newAnswers = {...state.answers, 'medications': medications};
        state = state.copyWith(answers: newAnswers);

        print('✅ Medicamento y notificaciones eliminados correctamente');
      }
    } catch (e) {
      print('❌ Error al eliminar medicamento: $e');
      rethrow;
    }
  }

  void updateFamilyConditions(List<FamilyCondition> conditions) {
    final newAnswers = {...state.answers, 'family_conditions': conditions};
    state = state.copyWith(answers: newAnswers);
  }

  void updateLocation(LocationData locationData) {
    final newAnswers = {...state.answers, 'location': locationData};
    state = state.copyWith(
      answers: newAnswers,
      locationData: locationData,
    );
  }

  int _findNextQuestionWithDependencies(
      String questionId, dynamic answer, Map<String, dynamic> answers) {
    final currentIndex = questionsList.indexWhere((q) => q.id == questionId);

    // Caso base: si no encontramos la pregunta o es la última, devolver el final
    if (currentIndex == -1 || currentIndex >= questionsList.length - 1) {
      return questionsList.length;
    }

    int nextIndex = currentIndex + 1;

    // Verificar flujos específicos basados en el ID de la pregunta
    if (questionId == 'occupation_type') {
      if (answer != 'Trabajo' && answer != 'Ambos') {
        // Saltar a la pregunta después de 'work_details'
        final workDetailsIndex =
            questionsList.indexWhere((q) => q.id == 'work_details');
        if (workDetailsIndex != -1 &&
            workDetailsIndex < questionsList.length - 1) {
          nextIndex = workDetailsIndex + 1;
        }
      }
    } else if (questionId == 'has_pathology' && answer == false) {
      nextIndex = questionsList.indexWhere((q) => q.id == 'has_family_history');
    } else if (questionId == 'current_treatment' && answer == false) {
      nextIndex = questionsList.indexWhere((q) => q.id == 'has_family_history');
    } else if (questionId == 'has_family_history' && answer == false) {
      nextIndex = questionsList.indexWhere((q) => q.id == 'digestive_issues');
    } else if (questionId == 'diet_type') {
      // Manejar el flujo especial para el tipo de dieta
      print('🍽️ Tipo de dieta seleccionado: $answer');

      // Buscar la pregunta de proteínas correspondiente según la dieta
      String proteinQuestionId = '';
      switch (answer) {
        case 'Omnívora':
          proteinQuestionId = 'protein_sources_omnivore';
          break;
        case 'Vegetariana':
          proteinQuestionId = 'protein_sources_vegetarian';
          break;
        case 'Vegana':
          proteinQuestionId = 'protein_sources_vegan';
          break;
        case 'Sin gluten':
          proteinQuestionId = 'protein_sources_glutenfree';
          break;
      }

      // Buscar el índice de la pregunta de proteínas correspondiente
      final proteinQuestionIndex =
          questionsList.indexWhere((q) => q.id == proteinQuestionId);
      if (proteinQuestionIndex != -1) {
        nextIndex = proteinQuestionIndex;
      }
    }

    // Verificar si la siguiente pregunta tiene dependencias que no se cumplen
    while (nextIndex < questionsList.length) {
      Question nextQuestion = questionsList[nextIndex];

      // Si la pregunta tiene un parentId, verificar dependencias
      if (nextQuestion.parentId != null && nextQuestion.dependsOn != null) {
        String parentId = nextQuestion.parentId!;

        // Obtener la respuesta a la pregunta padre
        dynamic parentAnswer = answers[parentId];
        print(
            '🔄 Verificando dependencia: Pregunta ${nextQuestion.id} depende de $parentId = $parentAnswer');

        // Si es una pregunta de selección múltiple, verificar si alguna de las opciones coincide
        bool dependencyMet = false;

        if (parentAnswer is String &&
            nextQuestion.dependsOn!.contains(parentAnswer)) {
          dependencyMet = true;
        } else if (parentAnswer is List<String>) {
          // Para preguntas multiselect, verificar si hay alguna coincidencia
          for (String option in parentAnswer) {
            if (nextQuestion.dependsOn!.contains(option)) {
              dependencyMet = true;
              break;
            }
          }
        }

        // Si no se cumple la dependencia, buscar la siguiente pregunta sin dependencia o con dependencia cumplida
        if (!dependencyMet) {
          print(
              '❌ Dependencia no cumplida para ${nextQuestion.id}, buscando siguiente pregunta válida');

          // Buscar la siguiente pregunta sin parentId o con un parentId diferente
          bool foundNextValid = false;
          for (int i = nextIndex + 1; i < questionsList.length; i++) {
            if (questionsList[i].parentId != parentId) {
              nextIndex = i;
              foundNextValid = true;
              break;
            }
          }

          // Si no encontramos una pregunta válida, llegar al final
          if (!foundNextValid) {
            nextIndex = questionsList.length;
          }

          continue; // Verificar la nueva pregunta encontrada
        }
      }

      // Si llegamos aquí, la pregunta es válida para mostrar
      break;
    }

    print('➡️ Siguiente índice de pregunta: $nextIndex');
    return nextIndex;
  }

  void _checkAndLoadMoreQuestions() {
    final currentIndex = state.currentQuestionIndex;
    final loadedCount = state.loadedQuestions.length;

    if (currentIndex >= loadedCount - 5 && loadedCount < questionsList.length) {
      final endIndex =
          (loadedCount + state.batchSize).clamp(0, questionsList.length);
      final updatedQuestions = List<Question>.from(state.loadedQuestions)
        ..addAll(questionsList.sublist(loadedCount, endIndex));

      state = state.copyWith(loadedQuestions: updatedQuestions);
    }
  }
}
