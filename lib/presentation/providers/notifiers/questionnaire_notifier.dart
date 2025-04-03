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
import 'package:xenify/presentation/providers/daily_questionnaire_provider.dart';
import 'package:xenify/data/daily_questionnaire_service.dart';

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
    print('🔄 Actualizando respuesta para pregunta: $questionId');
    print('📝 Nueva respuesta: $answer');

    final newAnswers = {...state.answers, questionId: answer};
    state = state.copyWith(answers: newAnswers);

    print('✅ Respuesta actualizada exitosamente');
  }

  Future<void> completeQuestionnaire() async {
    try {
      print('🔄 Iniciando proceso de completar cuestionario...');

      // Obtener los servicios necesarios
      final firestoreService = providerContainer.read(firestoreServiceProvider);
      final authService = providerContainer.read(authServiceProvider);
      final prefs = providerContainer.read(sharedPreferencesProvider);

      // Crear una instancia del servicio con el SharedPreferences del provider
      final dailyQuestionnaireService = DailyQuestionnaireService(prefs);

      // Obtener el usuario actual directamente del AuthService
      final user = authService.currentUser;

      if (user == null) {
        print('❌ Error inesperado: No se pudo obtener el usuario actual');
        throw Exception('Error al obtener el usuario actual');
      }

      print('👤 Usuario actual: ${user.uid}');
      print('📦 Preparando respuestas para guardar...');

      // Preparar una copia limpia de las respuestas
      Map<String, dynamic> answersToSave = {};

      // Procesar cada respuesta individualmente
      state.answers.forEach((key, value) {
        try {
          if (value == null) {
            answersToSave[key] = null;
          } else if (value is LocationData) {
            print('🗺️ Convirtiendo LocationData para $key');
            answersToSave[key] = value.toJson();
          } else if (value is DateTime) {
            print('🕒 Convirtiendo DateTime para $key');
            answersToSave[key] = value.toIso8601String();
          } else if (value is List) {
            print('📝 Procesando lista para $key');
            answersToSave[key] = value.map((item) {
              if (item is Medication) {
                return item.toJson();
              } else if (item is FamilyCondition) {
                return item.toJson();
              } else {
                return item;
              }
            }).toList();
          } else {
            // Para tipos simples (String, int, bool, etc)
            answersToSave[key] = value;
          }
        } catch (e) {
          print('⚠️ Error procesando respuesta para $key: $e');
          print('⚠️ Tipo de valor: ${value.runtimeType}');
          rethrow;
        }
      });

      print(
          '💾 Guardando respuestas y marcando como completado en Firestore...');
      await firestoreService.saveQuestionnaireAnswersAndComplete(
          user.uid, answersToSave);

      // Actualizar estado local usando DailyQuestionnaireService
      print('🔄 Actualizando estado del cuestionario inicial...');
      await dailyQuestionnaireService.syncInitialSetupWithFirestore(true);

      // Actualizar estado del auth provider
      final authNotifier =
          providerContainer.read(authNotifierProvider.notifier);
      await authNotifier.markInitialQuestionnaireCompleted(answersToSave);

      // Actualizar estado local
      state = state.copyWith(isCompleted: true);
      print('✨ Proceso de completar cuestionario finalizado exitosamente');
    } catch (e) {
      print('❌ Error al completar cuestionario: $e');
      rethrow;
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

    // Buscar la siguiente pregunta válida
    while (nextIndex < questionsList.length) {
      final nextQuestion = questionsList[nextIndex];
      bool shouldSkip = false;

      // Verificar si la pregunta tiene dependencias
      if (nextQuestion.parentId != null && nextQuestion.dependsOn != null) {
        // Obtener la respuesta de la pregunta padre
        final parentAnswer = answers[nextQuestion.parentId];

        // Si no hay respuesta para la pregunta padre, saltar esta pregunta
        if (parentAnswer == null) {
          shouldSkip = true;
        } else {
          // Verificar si la respuesta cumple con las dependencias
          bool dependencyMet = false;
          if (parentAnswer is String) {
            dependencyMet = nextQuestion.dependsOn!.contains(parentAnswer);
          } else if (parentAnswer is List<String>) {
            dependencyMet = parentAnswer
                .any((answer) => nextQuestion.dependsOn!.contains(answer));
          }

          // Si no se cumple la dependencia, saltar esta pregunta
          if (!dependencyMet) {
            shouldSkip = true;
          }
        }
      }

      // Si esta pregunta debe saltarse, buscar la siguiente
      if (shouldSkip) {
        nextIndex++;
        continue;
      }

      // Verificar flujos específicos basados en el ID de la pregunta
      if (questionId == 'occupation_type' &&
          answer != 'Trabajo' &&
          answer != 'Ambos') {
        if (nextQuestion.id == 'work_details') {
          nextIndex++;
          continue;
        }
      } else if (questionId == 'has_pathology' && answer == false) {
        if (nextQuestion.id == 'pathology_name' ||
            nextQuestion.id == 'current_treatment' ||
            nextQuestion.id == 'medications') {
          nextIndex++;
          continue;
        }
      } else if (questionId == 'current_treatment' && answer == false) {
        if (nextQuestion.id == 'medications') {
          nextIndex++;
          continue;
        }
      } else if (questionId == 'has_family_history' && answer == false) {
        if (nextQuestion.id == 'family_conditions') {
          nextIndex++;
          continue;
        }
      }

      // Si llegamos aquí, encontramos una pregunta válida
      break;
    }

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
