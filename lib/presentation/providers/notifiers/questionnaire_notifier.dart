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
    print('\n🔍 DEBUG - answerQuestion:');
    print('📍 ID de pregunta: $questionId');
    print('📥 Respuesta recibida: $answer');
    print('📊 Estado inicial:');
    print('- Índice actual: ${state.currentQuestionIndex}');
    print('- Proteína actual: ${state.currentProtein}');
    print('- Proteínas pendientes: ${state.remainingProteins}');

    // Preparar las actualizaciones básicas del estado
    final newAnswers = {...state.answers, questionId: answer};
    final newHistory = [...state.questionHistory, state.currentQuestionIndex];

    print('\n🔄 Procesando respuesta:');
    // Manejar respuestas de proteínas antes de determinar la siguiente pregunta
    if (questionId == 'vegetarian_proteins' ||
        questionId == 'omnivore_proteins' ||
        questionId == 'gluten_free_proteins') {
      print('📌 Manejando selección de proteínas');
      _handleProteinSelection(questionId, answer as List<String>, newAnswers);
    } else if (questionId == 'protein_frequency' ||
        questionId == 'gluten_free_protein_frequency') {
      print('📌 Manejando frecuencia de proteína');
      _handleProteinFrequencyAnswer(answer, newAnswers);

      // Si hay proteínas pendientes, no actualizamos el estado nuevamente
      if (state.remainingProteins.isNotEmpty) {
        print('⏭️ Proteínas pendientes detectadas, manteniendo estado actual');
        _checkAndLoadMoreQuestions();
        return;
      }
    }

    print('\n📊 Estado después de manejar respuesta:');
    print('- Índice actual: ${state.currentQuestionIndex}');
    print('- Proteína actual: ${state.currentProtein}');
    print('- Proteínas pendientes: ${state.remainingProteins}');

    // Determinar la siguiente pregunta después de actualizar el estado de proteínas
    print('\n🎯 Determinando siguiente pregunta...');
    int nextIndex = _findNextQuestionIndex(questionId, answer);
    print('📍 Índice siguiente calculado: $nextIndex');

    print('\n📦 Actualizando estado final:');
    if (nextIndex >= questionsList.length) {
      print('✅ Cuestionario completado');

      final newState = state.copyWith(
        answers: newAnswers,
        isCompleted: true,
        questionHistory: newHistory,
      );

      print('📊 Estado final:');
      print('- Respuestas guardadas: ${newState.answers.keys}');
      print('- Historia guardada: ${newState.questionHistory}');

      state = newState;
      LocalStorage.saveQuestionnaireData(newState);
      _handleMealTimeAnswers();
    } else {
      print('\n🔄 Preparando siguiente pregunta');
      final nextQuestion = questionsList[nextIndex];
      String? nextQuestionText;

      print('📝 Estado antes de actualización:');
      print('- Proteína actual: ${state.currentProtein}');
      print('- Proteínas pendientes: ${state.remainingProteins}');
      print('- Índice actual: ${state.currentQuestionIndex}');

      if (_isProteinFrequencyQuestion(nextQuestion.id)) {
        print('🔍 Configurando pregunta de frecuencia de proteína');
        if (state.currentProtein != null) {
          nextQuestionText = nextQuestion.text
              .replaceAll('%protein%', state.currentProtein!.toLowerCase());
          print('✏️ Texto personalizado: $nextQuestionText');
        } else {
          print('⚠️ No hay proteína actual, usando texto original');
          nextQuestionText = nextQuestion.text;
        }
      } else {
        nextQuestionText = nextQuestion.text;
        print('➡️ Siguiente pregunta: ${nextQuestion.id}');
      }

      // Preparar nuevo estado
      final newState = state.copyWith(
        answers: newAnswers,
        currentQuestionIndex: nextIndex,
        questionHistory: newHistory,
        currentQuestionText: nextQuestionText,
      );

      print('\n📊 Verificación de estado final:');
      print('- Nuevo índice: ${newState.currentQuestionIndex}');
      print('- Nueva proteína: ${newState.currentProtein}');
      print('- Proteínas pendientes: ${newState.remainingProteins}');
      print('- Nuevo texto: ${newState.currentQuestionText}');

      state = newState;
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
    print('🔄 Iniciando goBack(). Historia actual: ${state.questionHistory}');
    if (state.questionHistory.isEmpty) {
      print('❌ Historia vacía, no se puede retroceder');
      return;
    }

    final newHistory = List<int>.from(state.questionHistory)..removeLast();
    final previousIndex =
        state.questionHistory.isNotEmpty ? state.questionHistory.last : 0;
    final previousQuestion = questionsList[previousIndex];

    print(
        '📍 Retrocediendo a pregunta: ${previousQuestion.id} (índice: $previousIndex)');
    print('📝 Texto actual: ${state.currentQuestionText}');

    // Obtener las proteínas seleccionadas y sus frecuencias según el tipo de dieta
    List<String>? selectedProteins;
    String proteinKey = '';

    // Identificar el tipo de proteínas y obtener la lista correcta
    if (state.answers.containsKey('vegetarian_proteins')) {
      selectedProteins = state.answers['vegetarian_proteins'] as List<String>?;
      proteinKey = 'vegetarian_proteins';
    } else if (state.answers.containsKey('omnivore_proteins')) {
      selectedProteins = state.answers['omnivore_proteins'] as List<String>?;
      proteinKey = 'omnivore_proteins';
    } else if (state.answers.containsKey('gluten_free_proteins')) {
      selectedProteins = state.answers['gluten_free_proteins'] as List<String>?;
      proteinKey = 'gluten_free_proteins';
    }

    print('🥩 Proteínas seleccionadas recuperadas: $selectedProteins');

    // Restaurar el estado de proteínas si es necesario
    if (_isProteinFrequencyQuestion(previousQuestion.id) &&
        selectedProteins != null) {
      // Obtener las frecuencias ya registradas
      final frequencies = (state.answers['protein_frequencies']
              as List<Map<String, String>>?) ??
          [];

      print('📊 Frecuencias registradas: $frequencies');

      // Reconstruir el orden original de las proteínas
      final orderedProteins = List<String>.from(selectedProteins);

      // Encontrar la última proteína procesada
      String? lastProcessedProtein;
      if (frequencies.isNotEmpty) {
        lastProcessedProtein = frequencies.last['protein'];
        print('🔄 Última proteína procesada: $lastProcessedProtein');
      }

      // Encontrar el índice de la última proteína procesada
      int lastIndex = lastProcessedProtein != null
          ? orderedProteins.indexOf(lastProcessedProtein)
          : -1;

      // Calcular las proteínas restantes manteniendo el orden original
      final remainingProteins = lastIndex >= 0
          ? orderedProteins.sublist(0, lastIndex + 1)
          : orderedProteins;

      print('📝 Proteínas restantes en orden: $remainingProteins');

      if (remainingProteins.isNotEmpty) {
        final currentProtein = remainingProteins.last;
        final previousProteins =
            remainingProteins.sublist(0, remainingProteins.length - 1);

        state = state.copyWith(
          currentQuestionIndex: previousIndex < 0 ? 0 : previousIndex,
          questionHistory: newHistory,
          currentProtein: currentProtein,
          remainingProteins: previousProteins,
          currentQuestionText: previousQuestion.text
              .replaceAll('%protein%', currentProtein.toLowerCase()),
        );
        print('✅ Estado restaurado para proteína: $currentProtein');
        print('⏳ Proteínas anteriores pendientes: $previousProteins');
        return;
      }
    }

    // Si no es una pregunta de proteína o no hay proteínas pendientes
    final originalQuestionText = previousQuestion.text;
    print('📄 Texto original de la pregunta anterior: $originalQuestionText');

    state = state.copyWith(
      currentQuestionIndex: previousIndex < 0 ? 0 : previousIndex,
      questionHistory: newHistory,
      currentProtein: null,
      remainingProteins: const [],
      currentQuestionText: originalQuestionText,
    );

    print(
        '✅ Estado actualizado - Nueva pregunta actual: ${previousQuestion.id}');
    print('📝 Nuevo texto establecido: ${originalQuestionText}');
  }

  bool _isProteinFrequencyQuestion(String questionId) {
    return questionId == 'protein_frequency' ||
        questionId == 'gluten_free_protein_frequency';
  }

  void updateLocation(LocationData locationData) {
    final newAnswers = {...state.answers, 'location': locationData};
    state = state.copyWith(
      answers: newAnswers,
      locationData: locationData,
    );
  }

  // Maneja la selección de proteínas y actualiza el estado
  void _handleProteinSelection(String questionId, List<String> selectedProteins,
      Map<String, dynamic> answers) {
    if (selectedProteins.isEmpty) return;

    try {
      print('\n🔍 DEBUG - _handleProteinSelection:');
      print('📍 ID de pregunta actual: $questionId');
      print('📋 Proteínas seleccionadas: $selectedProteins');

      // Identificar el tipo de pregunta de frecuencia
      String frequencyQuestionId = questionId == 'gluten_free_proteins'
          ? 'gluten_free_protein_frequency'
          : 'protein_frequency';

      print('🎯 ID de pregunta de frecuencia objetivo: $frequencyQuestionId');

      // Encontrar la pregunta de frecuencia y su índice
      final frequencyIndex =
          questionsList.indexWhere((q) => q.id == frequencyQuestionId);
      final frequencyQuestion = questionsList[frequencyIndex];

      print('📊 Índice de pregunta de frecuencia: $frequencyIndex');
      print('❓ Pregunta encontrada: ${frequencyQuestion.text}');

      print('\n🔄 DEBUG - Preparando estado inicial:');

      // Preparar estado inicial limpio
      final updatedAnswers = {
        ...answers,
        'all_selected_proteins': selectedProteins,
        'protein_frequencies': <Map<String, String>>[],
        'current_question_index': frequencyIndex,
      };

      print('📦 Estado actual antes de actualizar:');
      print('- Índice actual: ${state.currentQuestionIndex}');
      print('- Proteína actual: ${state.currentProtein}');
      print('- Proteínas pendientes: ${state.remainingProteins}');
      print('- Texto actual: ${state.currentQuestionText}');

      // Configurar estado inicial con índice correcto
      final newState = state.copyWith(
        currentQuestionIndex: frequencyIndex,
        currentProtein: selectedProteins.first,
        remainingProteins: selectedProteins.skip(1).toList(),
        currentQuestionText: frequencyQuestion.text
            .replaceAll('%protein%', selectedProteins.first.toLowerCase()),
        answers: updatedAnswers,
      );

      print('\n📦 Estado nuevo preparado:');
      print('- Índice nuevo: ${newState.currentQuestionIndex}');
      print('- Nueva proteína: ${newState.currentProtein}');
      print('- Nuevas proteínas pendientes: ${newState.remainingProteins}');
      print('- Nuevo texto: ${newState.currentQuestionText}');

      state = newState;

      print('\n✅ Estado actualizado correctamente');
      print('🔍 Verificación post-actualización:');
      print('- Índice actual: ${state.currentQuestionIndex}');
      print('- Proteína actual: ${state.currentProtein}');
      print('- Proteínas pendientes: ${state.remainingProteins}');
    } catch (e) {
      print('Error en _handleProteinSelection: $e');
      state = state.copyWith(
        currentProtein: null,
        remainingProteins: const [],
        currentQuestionText: null,
      );
    }
  }

  // Maneja la respuesta de frecuencia de proteína
  void _handleProteinFrequencyAnswer(
      dynamic answer, Map<String, dynamic> answers) {
    print('\n🔍 DEBUG - _handleProteinFrequencyAnswer:');
    print('📥 Respuesta recibida: $answer');
    print('📊 Estado actual:');
    print('- Proteína actual: ${state.currentProtein}');
    print('- Proteínas pendientes: ${state.remainingProteins}');

    if (state.currentProtein == null) {
      print('❌ Error: No hay proteína actual, finalizando secuencia');
      _finishProteinFrequencies(answers);
      return;
    }

    try {
      print('🔄 Procesando respuesta de frecuencia...');

      // Preparar y validar la respuesta
      final frequency =
          answer is Map ? answer['frequency'] as String : answer as String;
      print('📝 Frecuencia extraída: $frequency');

      if (frequency.isEmpty) {
        print('❌ Error: Frecuencia inválida (vacía)');
        return;
      }

      // Registrar la frecuencia de la proteína actual
      final proteinFrequency = {
        'protein': state.currentProtein!,
        'frequency': frequency,
        'diet_type': answers['diet_type'] as String,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Obtener las frecuencias existentes
      final currentFrequencies =
          (answers['protein_frequencies'] as List<dynamic>?)
                  ?.whereType<Map<String, String>>()
                  .toList() ??
              [];

      // Actualizar con la nueva frecuencia
      final updatedFrequencies =
          List<Map<String, String>>.from(currentFrequencies);
      final existingIndex = updatedFrequencies
          .indexWhere((f) => f['protein'] == state.currentProtein);

      if (existingIndex >= 0) {
        updatedFrequencies[existingIndex] =
            proteinFrequency as Map<String, String>;
      } else {
        updatedFrequencies.add(proteinFrequency as Map<String, String>);
      }

      answers['protein_frequencies'] = updatedFrequencies;

      // Verificar si hay más proteínas pendientes
      if (state.remainingProteins.isNotEmpty) {
        // Si hay más proteínas, preparar la siguiente sin avanzar a otra pregunta
        print(
            '⏭️ Todavía hay proteínas pendientes: ${state.remainingProteins.length}');

        // Obtener el índice actual de la pregunta de frecuencia
        final frequencyQuestionId = answers.containsKey('gluten_free_proteins')
            ? 'gluten_free_protein_frequency'
            : 'protein_frequency';

        final frequencyQuestionIndex =
            questionsList.indexWhere((q) => q.id == frequencyQuestionId);

        // Actualizar el estado para mostrar la siguiente proteína pero manteniendo la misma pregunta
        final nextProtein = state.remainingProteins.first;

        final newState = state.copyWith(
          currentQuestionIndex: frequencyQuestionIndex,
          currentProtein: nextProtein,
          remainingProteins: state.remainingProteins.skip(1).toList(),
          currentQuestionText: questionsList[frequencyQuestionIndex]
              .text
              .replaceAll('%protein%', nextProtein.toLowerCase()),
        );

        // Actualizar el estado preservando la proteína actual
        state = newState.copyWith(
          answers: {...answers},
        );

        print('⏭️ Preparada siguiente proteína: $nextProtein');
        // No llamamos a answerQuestion aquí, solo actualizamos el estado
      } else {
        // Si no hay más proteínas, podemos finalizar la secuencia
        print('✅ No hay más proteínas pendientes, finalizando secuencia');
        answers['current_protein_completed'] = true;
        _finishProteinFrequencies(answers);

        // Aquí es donde avanzamos a la siguiente pregunta
        final nextQuestionIndex =
            questionsList.indexWhere((q) => q.id == 'vegetables');
        if (nextQuestionIndex >= 0) {
          state = state.copyWith(
            currentQuestionIndex: nextQuestionIndex,
            currentProtein: null,
            remainingProteins: const [],
            currentQuestionText: questionsList[nextQuestionIndex].text,
            answers: answers,
          );
        }
      }
    } catch (e) {
      print('❌ Error procesando frecuencia: $e');
      _finishProteinFrequencies(answers);
    }
  }

  /// Prepara el estado para la siguiente proteína o finaliza el proceso
  void _prepareNextProtein(Map<String, dynamic> answers) {
    print('🔄 Iniciando preparación de siguiente proteína');

    try {
      // Mantener el índice de la pregunta actual
      final currentIndex = state.currentQuestionIndex;
      print('📍 Índice actual: $currentIndex');

      // Obtener todas las proteínas y calcular pendientes
      final allProteins = answers['all_selected_proteins'] as List<String>;
      final frequencies =
          answers['protein_frequencies'] as List<Map<String, String>>? ?? [];
      final processedProteins =
          frequencies.map((f) => f['protein'] as String).toList();
      final pendingProteins =
          allProteins.where((p) => !processedProteins.contains(p)).toList();

      print('📊 Estado de proteínas:');
      print(
          '✅ Procesadas: ${processedProteins.length} de ${allProteins.length}');
      print('⏳ Pendientes: ${pendingProteins.length}');

      // Verificar si quedan proteínas por procesar
      if (pendingProteins.isEmpty) {
        print('✅ Todas las proteínas procesadas');
        answers['current_protein_completed'] = true;
        _finishProteinFrequencies(answers);
        return;
      }

      // Preparar la siguiente proteína
      final nextProtein = pendingProteins.first;
      print('⏭️ Siguiente proteína: $nextProtein');

      // Actualizar el estado manteniendo el índice actual
      final updatedAnswers = {
        ...answers,
        'current_protein': nextProtein,
        'remaining_proteins': pendingProteins.skip(1).toList(),
        'current_protein_index': processedProteins.length,
      };

      state = state.copyWith(
        currentQuestionIndex: currentIndex, // Mantener el índice actual
        currentProtein: nextProtein,
        remainingProteins: pendingProteins.skip(1).toList(),
        currentQuestionText: questionsList[currentIndex]
            .text
            .replaceAll('%protein%', nextProtein.toLowerCase()),
        answers: updatedAnswers,
      );

      print('✅ Estado actualizado correctamente');
    } catch (e) {
      print('❌ Error: $e');
      _finishProteinFrequencies(answers);
    }
  }

  /// Finaliza el proceso de registro de frecuencias de proteínas
  void _finishProteinFrequencies(Map<String, dynamic> answers) {
    print('🔄 Finalizando proceso de frecuencias de proteínas');

    try {
      // Identificar el tipo de dieta y su lista de proteínas correspondiente
      final dietType = answers['diet_type'] as String?;
      final proteinListKey = _getProteinListKey(dietType);

      if (proteinListKey != null) {
        // Verificar proteínas sin registrar
        final selectedProteins = answers[proteinListKey] as List<String>?;
        final frequencies =
            answers['protein_frequencies'] as List<Map<String, String>>;

        final missingProteins =
            _findMissingProteins(selectedProteins, frequencies);

        if (missingProteins.isNotEmpty) {
          print('⚠️ Proteínas sin frecuencia registrada: $missingProteins');
          // Registrar frecuencia por defecto para proteínas faltantes
          _registerDefaultFrequencies(missingProteins, answers);
        }
      }

      // Marcar como completado y limpiar el estado
      answers['current_protein_completed'] = true;
      state = state.copyWith(
        currentProtein: null,
        remainingProteins: const [],
        currentQuestionText: null,
        answers: answers,
      );

      print('✅ Estado de proteínas finalizado correctamente');
      LocalStorage.saveQuestionnaireData(state);
    } catch (e) {
      print('❌ Error finalizando estado de proteínas: $e');
      _cleanupState(answers);
    }
  }

  /// Obtiene la clave correspondiente a la lista de proteínas según la dieta
  String? _getProteinListKey(String? dietType) {
    switch (dietType) {
      case 'Vegetariana':
        return 'vegetarian_proteins';
      case 'Omnívora':
        return 'omnivore_proteins';
      case 'Sin gluten':
        return 'gluten_free_proteins';
      default:
        return null;
    }
  }

  /// Encuentra las proteínas que no tienen frecuencia registrada
  List<String> _findMissingProteins(
      List<String>? selectedProteins, List<Map<String, String>> frequencies) {
    if (selectedProteins == null) return [];
    return selectedProteins
        .where((protein) => !frequencies.any((f) => f['protein'] == protein))
        .toList();
  }

  /// Registra frecuencias por defecto para las proteínas faltantes
  void _registerDefaultFrequencies(
      List<String> missingProteins, Map<String, dynamic> answers) {
    final frequencies =
        (answers['protein_frequencies'] as List<Map<String, String>>?) ?? [];

    for (final protein in missingProteins) {
      frequencies.add({
        'protein': protein,
        'frequency': '1 vez',
        'diet_type': answers['diet_type'] as String,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }

    answers['protein_frequencies'] = frequencies;
    print('✅ Frecuencias por defecto registradas para: $missingProteins');
  }

  /// Limpia el estado en caso de error
  void _cleanupState(Map<String, dynamic> answers) {
    state = state.copyWith(
      currentProtein: null,
      remainingProteins: const [],
      currentQuestionText: null,
      answers: answers,
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
      final previousDiet = state.answers['diet_type'] as String?;

      // Solo limpiar el estado si la dieta ha cambiado
      if (previousDiet != selectedDiet) {
        state = state.copyWith(
          currentProtein: null,
          remainingProteins: const [],
          currentQuestionText: null,
          answers: {
            ...state.answers,
            'diet_type': selectedDiet,
            'protein_frequencies':
                <Map<String, String>>[], // Reiniciar frecuencias
            // Limpiar respuestas específicas de la dieta anterior
            'vegetarian_proteins': null,
            'omnivore_proteins': null,
            'gluten_free_proteins': null,
          },
        );
      }

      // Encontrar la siguiente pregunta específica para la dieta
      int nextIndex = questionsList.indexWhere((q) =>
          q.parentId == 'diet_type' &&
          (q.dependsOn?.contains(selectedDiet) ?? false));

      if (nextIndex < 0) {
        // Si no hay pregunta específica, ir a preguntas comunes
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

    // Manejo especial para preguntas de frecuencia de proteína
    if (currentQuestionId == 'protein_frequency' ||
        currentQuestionId == 'gluten_free_protein_frequency') {
      print('\n🔍 DEBUG - _findNextQuestionIndex para frecuencia de proteína:');
      print('📍 ID de pregunta actual: $currentQuestionId');
      print('📋 Respuesta recibida: $answer');

      // Obtener el índice de la pregunta de frecuencia actual
      final frequencyQuestionId = currentQuestionId;
      final frequencyQuestionIndex =
          questionsList.indexWhere((q) => q.id == frequencyQuestionId);

      print('📊 Estado actual de proteínas:');
      print('- Proteína actual: ${state.currentProtein}');
      print('- Proteínas pendientes: ${state.remainingProteins}');
      print('- Índice de pregunta de frecuencia: $frequencyQuestionIndex');

      print('🔍 Verificando estado de proteínas:');

      // Verificar si la proteína actual ya fue procesada
      List<Map<String, String>> frequencies =
          (state.answers['protein_frequencies'] as List<dynamic>?)
                  ?.cast<Map<String, String>>() ??
              [];

      bool currentProteinProcessed = false;
      if (state.currentProtein != null && frequencies.isNotEmpty) {
        currentProteinProcessed = frequencies.any((f) =>
            f['protein'] == state.currentProtein && f['frequency'] != null);
      }

      print('- Proteína actual: ${state.currentProtein}');
      print('- Frecuencias registradas: ${frequencies.length}');
      print('- Proteína actual procesada: $currentProteinProcessed');
      print('- Proteínas pendientes: ${state.remainingProteins}');

      // Si la proteína actual ya fue procesada y no hay más pendientes
      if (currentProteinProcessed && state.remainingProteins.isEmpty) {
        print('✅ Avanzando a verduras:');
        print('- Razón: Última proteína procesada y no hay más pendientes');
        final vegetablesIndex =
            questionsList.indexWhere((q) => q.id == 'vegetables');
        print('- Índice de pregunta de verduras: $vegetablesIndex');
        return vegetablesIndex;
      }

      // Si hay más proteínas pendientes o la actual no está procesada
      print('⏳ Manteniendo en pregunta de frecuencia:');
      print('- Razón: Proteína actual no procesada o quedan pendientes');
      return frequencyQuestionIndex;
    }

    // Si no es una pregunta especial, avanzar a la siguiente
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
