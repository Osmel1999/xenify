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

    // Manejar respuestas de proteínas antes de determinar la siguiente pregunta
    if (questionId == 'vegetarian_proteins' ||
        questionId == 'omnivore_proteins' ||
        questionId == 'gluten_free_proteins') {
      _handleProteinSelection(questionId, answer as List<String>, newAnswers);
    } else if (questionId == 'protein_frequency' ||
        questionId == 'gluten_free_protein_frequency') {
      _handleProteinFrequencyAnswer(answer, newAnswers);
    }

    // Determinar la siguiente pregunta después de actualizar el estado de proteínas
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
      // Actualizar el estado con el texto de la próxima pregunta
      final nextQuestion = questionsList[nextIndex];
      String? nextQuestionText;

      if (_isProteinFrequencyQuestion(nextQuestion.id)) {
        // Para preguntas de frecuencia de proteína
        if (state.currentProtein != null) {
          nextQuestionText = nextQuestion.text
              .replaceAll('%protein%', state.currentProtein!.toLowerCase());
          print(
              '🔄 Actualizando pregunta para proteína: ${state.currentProtein}');
        } else {
          print('⚠️ No hay proteína actual, usando texto original');
          nextQuestionText = nextQuestion.text;
        }
      } else {
        // Para otras preguntas, usar el texto original
        nextQuestionText = nextQuestion.text;
        print('➡️ Avanzando a pregunta: ${nextQuestion.id}');
      }

      state = state.copyWith(
        answers: newAnswers,
        currentQuestionIndex: nextIndex,
        questionHistory: newHistory,
        currentQuestionText: nextQuestionText,
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

    // Obtener las proteínas seleccionadas según el tipo de dieta
    List<String>? selectedProteins;
    if (state.answers.containsKey('vegetarian_proteins')) {
      selectedProteins = state.answers['vegetarian_proteins'] as List<String>?;
    } else if (state.answers.containsKey('omnivore_proteins')) {
      selectedProteins = state.answers['omnivore_proteins'] as List<String>?;
    } else if (state.answers.containsKey('gluten_free_proteins')) {
      selectedProteins = state.answers['gluten_free_proteins'] as List<String>?;
    }

    // Restaurar el estado de proteínas si es necesario
    if (_isProteinFrequencyQuestion(previousQuestion.id) &&
        selectedProteins != null) {
      // Obtener las frecuencias ya registradas
      final frequencies = (state.answers['protein_frequencies']
              as List<Map<String, String>>?) ??
          [];

      // Filtrar las proteínas que ya tienen frecuencia registrada
      final proteinsWithFrequency =
          frequencies.map((f) => f['protein'] as String).toList();
      final remainingProteins = selectedProteins
          .where((p) => !proteinsWithFrequency.contains(p))
          .toList();

      // Si hay proteínas pendientes, establecer la siguiente
      if (remainingProteins.isNotEmpty) {
        state = state.copyWith(
          currentQuestionIndex: previousIndex < 0 ? 0 : previousIndex,
          questionHistory: newHistory,
          currentProtein: remainingProteins.first,
          remainingProteins: remainingProteins.skip(1).toList(),
          currentQuestionText: previousQuestion.text
              .replaceAll('%protein%', remainingProteins.first.toLowerCase()),
        );
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
      // Determinar el ID correcto de la pregunta de frecuencia
      String frequencyQuestionId = questionId == 'gluten_free_proteins'
          ? 'gluten_free_protein_frequency'
          : 'protein_frequency';

      // Encontrar la pregunta de frecuencia
      final frequencyQuestion = questionsList.firstWhere(
        (q) => q.id == frequencyQuestionId,
      );

      // Actualizar el estado con la primera proteína y las restantes
      state = state.copyWith(
        currentProtein: selectedProteins.first,
        remainingProteins: selectedProteins.skip(1).toList(),
        currentQuestionText: frequencyQuestion.text
            .replaceAll('%protein%', selectedProteins.first.toLowerCase()),
        // Inicializar o limpiar las frecuencias anteriores
        answers: {
          ...answers,
          'protein_frequencies': <Map<String, String>>[],
        },
      );
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
    if (state.currentProtein == null) {
      print('❌ No hay proteína actual, finalizando secuencia');
      _finishProteinFrequencies(answers);
      return;
    }

    try {
      // Preparar y validar la respuesta
      final frequency =
          answer is Map ? answer['frequency'] as String : answer as String;
      if (frequency.isEmpty) {
        print('❌ Frecuencia inválida');
        return;
      }

      // Registrar la frecuencia de la proteína actual
      final proteinFrequency = {
        'protein': state.currentProtein!,
        'frequency': frequency,
        'diet_type': answers['diet_type'] as String,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Actualizar la lista de frecuencias
      final currentFrequencies =
          (answers['protein_frequencies'] as List<dynamic>?)
                  ?.whereType<Map<String, String>>()
                  .toList() ??
              [];

      final updatedFrequencies =
          List<Map<String, String>>.from(currentFrequencies);
      final existingIndex = updatedFrequencies
          .indexWhere((f) => f['protein'] == state.currentProtein);

      if (existingIndex >= 0) {
        updatedFrequencies[existingIndex] = proteinFrequency;
      } else {
        updatedFrequencies.add(proteinFrequency);
      }

      // Actualizar el estado con la nueva frecuencia
      answers['protein_frequencies'] = updatedFrequencies;

      if (state.remainingProteins.isEmpty) {
        print('✅ Todas las proteínas procesadas');
        answers['current_protein_completed'] = true;
        _finishProteinFrequencies(answers);
      } else {
        print('⏭️ Preparando siguiente proteína');
        _prepareNextProtein(answers);
      }
    } catch (e) {
      print('❌ Error procesando frecuencia: $e');
      _finishProteinFrequencies(answers);
    }
  }

  /// Prepara el estado para la siguiente proteína o finaliza el proceso
  void _prepareNextProtein(Map<String, dynamic> answers) {
    if (state.remainingProteins.isEmpty) {
      print('✅ No hay más proteínas, finalizando proceso');
      answers['current_protein_completed'] = true;
      _finishProteinFrequencies(answers);
      return;
    }

    try {
      // Obtener la siguiente proteína y su pregunta correspondiente
      final nextProtein = state.remainingProteins.first;
      final currentQuestionId = state.currentQuestionIndex >= 0 &&
              state.currentQuestionIndex < questionsList.length
          ? questionsList[state.currentQuestionIndex].id
          : null;

      // Encontrar la pregunta correcta para la siguiente proteína
      final frequencyQuestion = questionsList.firstWhere(
        (q) => q.id == currentQuestionId,
        orElse: () => questionsList.firstWhere((q) =>
            q.id ==
            (answers.containsKey('gluten_free_proteins')
                ? 'gluten_free_protein_frequency'
                : 'protein_frequency')),
      );

      // Actualizar el estado con la nueva proteína
      answers['current_protein_completed'] = false;
      state = state.copyWith(
        currentProtein: nextProtein,
        remainingProteins: state.remainingProteins.skip(1).toList(),
        currentQuestionText: frequencyQuestion.text
            .replaceAll('%protein%', nextProtein.toLowerCase()),
        answers: answers,
      );

      print('✅ Preparada siguiente proteína: $nextProtein');
    } catch (e) {
      print('❌ Error preparando siguiente proteína: $e');
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

    // Manejar preguntas de frecuencia de proteína
    if (currentQuestionId == 'protein_frequency' ||
        currentQuestionId == 'gluten_free_protein_frequency') {
      // Si no hay más proteínas pendientes o ya se completó, avanzar a verduras
      if (state.remainingProteins.isEmpty ||
          (state.answers['current_protein_completed'] as bool? ?? false)) {
        print('✅ Avanzando a sección de verduras');
        return questionsList.indexWhere((q) => q.id == 'vegetables');
      }

      // Si aún hay proteínas por procesar, mantener en la misma pregunta
      print(
          '⏳ Continuando con siguiente proteína: ${state.remainingProteins.first}');
      return currentIndex;
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
