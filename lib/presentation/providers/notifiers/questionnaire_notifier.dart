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

    // Procesar horarios para notificaciones
    if (questionId == 'bed_time' || questionId == 'wake_up_time') {
      if (answer is DateTime) {
        _handleTimeAnswers(questionId, answer, newAnswers);
      } else {
        print(
            '⚠️ Advertencia: Se esperaba DateTime pero se recibió ${answer.runtimeType}');
      }
    }

    // Determinar la siguiente pregunta
    int nextIndex = _findNextQuestionIndex(questionId, answer);

    if (nextIndex >= questionsList.length) {
      state = state.copyWith(
        answers: newAnswers,
        isCompleted: true,
        questionHistory: newHistory,
      );
      LocalStorage.saveQuestionnaireData(state);
    } else {
      final nextQuestion = questionsList[nextIndex];
      state = state.copyWith(
        answers: newAnswers,
        currentQuestionIndex: nextIndex,
        questionHistory: newHistory,
        currentQuestionText: nextQuestion.text,
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

  int _findNextQuestionIndex(String currentQuestionId, dynamic answer) {
    return questionsList.indexWhere((q) => q.id == currentQuestionId) + 1;
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
