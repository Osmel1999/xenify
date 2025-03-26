import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xenify/data/daily_questionnaire_service.dart';
import 'package:xenify/domain/entities/question.dart';
import 'package:xenify/domain/entities/daily_questionnaire_type.dart';
import 'package:xenify/presentation/providers/states/daily_questionnaire_state.dart';

class DailyQuestionnaireNotifier
    extends StateNotifier<DailyQuestionnaireState> {
  DailyQuestionnaireNotifier() : super(DailyQuestionnaireState());

  // Verificar qué cuestionario debe mostrarse según la hora y el historial
  Future<void> checkAndShowActiveQuestionnaire() async {
    final now = DateTime.now();
    final currentHour = now.hour;

    // Determinar qué tipo de cuestionario debe mostrarse según la hora
    DailyQuestionnaireType? typeToShow;

    if (currentHour >= 5 && currentHour < 10) {
      // Cuestionario matutino (5:00 AM - 9:59 AM)
      final isSleepCompleted =
          await DailyQuestionnaireService.isQuestionnaireCompletedToday(
              DailyQuestionnaireType.sleep);

      if (!isSleepCompleted) {
        typeToShow = DailyQuestionnaireType.sleep;
      } else {
        typeToShow = DailyQuestionnaireType.morning;
      }
    } else if (currentHour >= 10 && currentHour < 14) {
      // Cuestionario de mediodía (10:00 AM - 1:59 PM)
      typeToShow = DailyQuestionnaireType.postMeal;
    } else if (currentHour >= 14 && currentHour < 18) {
      // Cuestionario de tarde (2:00 PM - 5:59 PM)
      typeToShow = DailyQuestionnaireType.afternoon;
    } else if (currentHour >= 18 && currentHour < 22) {
      // Cuestionario nocturno (6:00 PM - 9:59 PM)
      typeToShow = DailyQuestionnaireType.evening;
    }

    // Si hay un tipo de cuestionario para mostrar y no se ha completado hoy
    if (typeToShow != null) {
      final isCompleted =
          await DailyQuestionnaireService.isQuestionnaireCompletedToday(
              typeToShow);

      if (!isCompleted) {
        // Cargar las preguntas específicas para este tipo de cuestionario
        final questions = _getQuestionsForType(typeToShow);

        // Actualizar el estado para activar el cuestionario
        state = state.copyWith(
          isActive: true,
          activeType: typeToShow,
          questions: questions,
          currentQuestionIndex: 0,
          responses: {},
          isCompleted: false,
        );
      }
    }
  }

  // Mostrar un cuestionario específico directamente (usado cuando se toca una notificación)
  Future<bool> showQuestionnaire(DailyQuestionnaireType type) async {
    // Verificar si este cuestionario ya fue completado hoy
    final isCompleted =
        await DailyQuestionnaireService.isQuestionnaireCompletedToday(type);

    if (!isCompleted) {
      // Cargar las preguntas específicas para este tipo de cuestionario
      final questions = _getQuestionsForType(type);

      // Actualizar el estado para activar el cuestionario
      state = state.copyWith(
        isActive: true,
        activeType: type,
        questions: questions,
        currentQuestionIndex: 0,
        responses: {},
        isCompleted: false,
      );

      return true;
    }

    // El cuestionario ya fue completado
    return false;
  }

  // Responder a una pregunta
  void answerQuestion(String questionId, dynamic answer) {
    // Actualizar las respuestas
    final updatedResponses = {...state.responses, questionId: answer};

    // Determinar si avanzamos a la siguiente pregunta o finalizamos
    if (state.currentQuestionIndex < state.questions.length - 1) {
      // Avanzar a la siguiente pregunta
      state = state.copyWith(
        currentQuestionIndex: state.currentQuestionIndex + 1,
        responses: updatedResponses,
      );
    } else {
      // Finalizar el cuestionario
      state = state.copyWith(
        isCompleted: true,
        responses: updatedResponses,
      );

      // Guardar las respuestas
      _saveResponses();
    }
  }

  // Guardar las respuestas del cuestionario
  Future<void> _saveResponses() async {
    if (state.activeType != null) {
      await DailyQuestionnaireService.saveQuestionnaireResponse(
        state.activeType!,
        state.responses,
      );
    }
  }

  // Cerrar el cuestionario
  void closeQuestionnaire() {
    state = DailyQuestionnaireState();
  }

  // Obtener las preguntas para un tipo específico de cuestionario
  List<Question> _getQuestionsForType(DailyQuestionnaireType type) {
    switch (type) {
      case DailyQuestionnaireType.sleep:
        return _getSleepQuestions();
      case DailyQuestionnaireType.morning:
        return _getMorningQuestions();
      case DailyQuestionnaireType.afternoon:
        return _getAfternoonQuestions();
      case DailyQuestionnaireType.evening:
        return _getEveningQuestions();
      case DailyQuestionnaireType.postMeal:
        return _getPostMealQuestions();
      default:
        return [];
    }
  }

  // Definir preguntas para el cuestionario de sueño
  List<Question> _getSleepQuestions() {
    return [
      Question(
        id: 'sleep_hours',
        text: '¿Cuántas horas sueles dormir por noche en promedio?',
        type: QuestionType.select,
        options: [
          'Menos de 6 horas',
          '6-7 horas',
          '7-9 horas',
          'Más de 9 horas'
        ],
      ),
      Question(
        id: 'sleep_wakeups',
        text:
            '¿Con qué frecuencia te despiertas durante la noche y te cuesta volver a dormir?',
        type: QuestionType.select,
        options: [
          'Nunca o casi nunca',
          '1-2 veces por noche',
          '3-4 veces por noche',
          'Más de 5 veces por noche'
        ],
      ),
      Question(
        id: 'sleep_time_to_fall_asleep',
        text:
            '¿Cuánto tiempo sueles tardar en quedarte dormido después de acostarte?',
        type: QuestionType.select,
        options: [
          'Menos de 15 minutos',
          '15-30 minutos',
          '30-60 minutos',
          'Más de 60 minutos'
        ],
      ),
      Question(
        id: 'sleep_feeling_rested',
        text: '¿Te sientes descansado y con energía al despertar?',
        type: QuestionType.select,
        options: [
          'Sí, casi siempre',
          'Sí, la mayoría de los días',
          'Solo algunos días',
          'Casi nunca'
        ],
      ),
      Question(
        id: 'sleep_daytime_drowsiness',
        text:
            '¿Experimentas somnolencia excesiva durante el día (ej. en el trabajo, conduciendo)?',
        type: QuestionType.select,
        options: [
          'Nunca',
          'Ocasionalmente',
          'Varios días a la semana',
          'Todos los días'
        ],
      ),
    ];
  }

  // Definir preguntas para el cuestionario matutino
  List<Question> _getMorningQuestions() {
    return [
      Question(
        id: 'morning_mood',
        text: '¿Cómo te sientes esta mañana?',
        type: QuestionType.select,
        options: ['Muy bien', 'Bien', 'Regular', 'Mal', 'Muy mal'],
      ),
      Question(
        id: 'morning_energy',
        text: '¿Cómo es tu nivel de energía?',
        type: QuestionType.select,
        options: ['Muy alto', 'Alto', 'Normal', 'Bajo', 'Muy bajo'],
      ),
      Question(
        id: 'morning_anxiety',
        text: '¿Sientes ansiedad o nerviosismo?',
        type: QuestionType.select,
        options: [
          'No, en absoluto',
          'Un poco',
          'Moderadamente',
          'Bastante',
          'Mucho'
        ],
      ),
    ];
  }

  // Definir preguntas para el cuestionario de tarde
  List<Question> _getAfternoonQuestions() {
    return [
      Question(
        id: 'afternoon_energy',
        text: '¿Cómo es tu nivel de energía esta tarde?',
        type: QuestionType.select,
        options: ['Muy alto', 'Alto', 'Normal', 'Bajo', 'Muy bajo'],
      ),
      Question(
        id: 'afternoon_productivity',
        text: '¿Cómo valoras tu productividad hasta ahora?',
        type: QuestionType.select,
        options: ['Excelente', 'Buena', 'Normal', 'Baja', 'Muy baja'],
      ),
      Question(
        id: 'afternoon_stress',
        text: '¿Cuál es tu nivel de estrés actual?',
        type: QuestionType.select,
        options: ['Muy bajo', 'Bajo', 'Moderado', 'Alto', 'Muy alto'],
      ),
    ];
  }

  // Definir preguntas para el cuestionario nocturno
  List<Question> _getEveningQuestions() {
    return [
      Question(
        id: 'evening_mood',
        text: '¿Cómo te sientes esta noche?',
        type: QuestionType.select,
        options: ['Muy bien', 'Bien', 'Regular', 'Mal', 'Muy mal'],
      ),
      Question(
        id: 'evening_day_satisfaction',
        text: '¿Estás satisfecho con tu día?',
        type: QuestionType.select,
        options: [
          'Muy satisfecho',
          'Satisfecho',
          'Neutral',
          'Insatisfecho',
          'Muy insatisfecho'
        ],
      ),
      Question(
        id: 'evening_tomorrow_goals',
        text: '¿Tienes claros tus objetivos para mañana?',
        type: QuestionType.yesNo,
      ),
    ];
  }

  // Definir preguntas para el cuestionario post-comida
  List<Question> _getPostMealQuestions() {
    return [
      Question(
        id: 'meal_type',
        text: '¿Qué comida acabas de tener?',
        type: QuestionType.select,
        options: ['Desayuno', 'Almuerzo', 'Merienda', 'Cena', 'Otro'],
      ),
      Question(
        id: 'meal_satisfaction',
        text: '¿Cómo te sientes después de comer?',
        type: QuestionType.select,
        options: [
          'Muy bien',
          'Bien',
          'Normal',
          'Un poco incómodo',
          'Bastante incómodo'
        ],
      ),
      Question(
        id: 'meal_symptoms',
        text: '¿Experimentas alguno de estos síntomas después de comer?',
        type: QuestionType.multiSelect,
        options: [
          'Ninguno',
          'Hinchazón',
          'Gases',
          'Acidez',
          'Náuseas',
          'Cansancio extremo'
        ],
      ),
    ];
  }
}
