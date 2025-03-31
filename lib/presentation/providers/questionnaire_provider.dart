import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xenify/domain/entities/question.dart';
import 'package:xenify/domain/entities/questionnaire_state.dart';
import 'package:xenify/presentation/providers/notification_provider.dart';
import 'package:xenify/presentation/providers/notifiers/questionnaire_notifier.dart';

final questionsList = [
  // Pregunta de ubicación (se mantiene como primera pregunta)
  Question(
    id: 'location',
    text:
        'De donde eres? , conocer la cultura y condiciones genéticas de la región permiten personalizar mejor las recomendaciones.',
    type: QuestionType.location,
    isRequired: true,
  ),

  Question(
    id: 'birth_date',
    text: '¿Cuál es su fecha de nacimiento?',
    type: QuestionType.date,
  ),

  Question(
    id: 'gender',
    text: '¿Cuál es su género?',
    type: QuestionType.select,
    options: ['Masculino', 'Femenino', 'Prefiero no decir'],
  ),

  // Preguntas demográficas y ocupación
  Question(
    id: 'occupation_type',
    text: '¿A qué te dedicas actualmente?',
    type: QuestionType.select,
    options: ['Estudiante', 'Trabajo', 'Ambos', 'Ninguno'],
  ),
  Question(
    id: 'work_details',
    text: '¿En qué trabajas?',
    type: QuestionType.text,
    hint: 'Ej: Ingeniero de Software, Médico, etc.',
    isRequired: true,
  ),

  // Nuevas preguntas de hábitos de sueño
  Question(
    id: 'wake_up_time',
    text: '¿A qué hora sueles despertarte habitualmente?',
    type: QuestionType.time,
  ),

  Question(
    id: 'bed_time',
    text: '¿A qué hora sueles acostarte habitualmente?',
    type: QuestionType.time,
  ),

  // Nuevas preguntas de hábitos alimenticios
  Question(
    id: 'breakfast_time',
    text: '¿A qué hora sueles desayunar?',
    type: QuestionType.select,
    options: [
      'No aplica',
      '5:00 - 6:00',
      '6:00 - 7:00',
      '7:00 - 8:00',
      '8:00 - 9:00',
      '9:00 - 10:00',
      'Después de las 10:00'
    ],
  ),

  Question(
    id: 'lunch_time',
    text: '¿A qué hora sueles almorzar?',
    type: QuestionType.select,
    options: [
      'No aplica',
      '11:00 - 12:00',
      '12:00 - 13:00',
      '13:00 - 14:00',
      '14:00 - 15:00',
      '15:00 - 16:00',
      'Después de las 16:00'
    ],
  ),

  Question(
    id: 'dinner_time',
    text: '¿A qué hora sueles cenar?',
    type: QuestionType.select,
    options: [
      'No aplica',
      '17:00 - 18:00',
      '18:00 - 19:00',
      '19:00 - 20:00',
      '20:00 - 21:00',
      '21:00 - 22:00',
      'Después de las 22:00'
    ],
  ),

  // Preguntas de patología
  Question(
    id: 'has_pathology',
    text: '¿Tiene alguna patología o enfermedad diagnosticada actualmente?',
    type: QuestionType.yesNo,
  ),
  Question(
    id: 'pathology_name',
    text: '¿Cuál es su diagnóstico?',
    type: QuestionType.text,
    hint: 'Ej: Diabetes Tipo 2',
  ),
  Question(
    id: 'current_treatment',
    text: '¿Está bajo tratamiento actualmente?',
    type: QuestionType.yesNo,
  ),
  Question(
    id: 'medications',
    text: '¿Qué medicamentos toma actualmente?',
    type: QuestionType.medication,
  ),

  // Preguntas de antecedentes familiares
  Question(
    id: 'has_family_history',
    text: '¿Tiene antecedentes familiares de enfermedades?',
    type: QuestionType.yesNo,
  ),
  Question(
    id: 'family_conditions',
    text: 'Por favor, indique las enfermedades y los familiares afectados',
    type: QuestionType.familyHistory,
  ),

  // Preguntas sobre hábitos y síntomas
  Question(
    id: 'digestive_issues',
    text: '¿Experimenta algún problema digestivo?',
    type: QuestionType.multiSelect,
    options: [
      'Ninguno',
      'Acidez',
      'Gases',
      'Estreñimiento',
      'Diarrea',
      'Dolor abdominal'
    ],
  ),
  Question(
    id: 'cardiovascular_symptoms',
    text: '¿Experimenta alguno de estos síntomas?',
    type: QuestionType.multiSelect,
    options: [
      'Ninguno',
      'Palpitaciones',
      'Dolor en el pecho',
      'Dificultad para respirar',
      'Hinchazón en piernas'
    ],
  ),

  // Preguntas de dieta
  Question(
    id: 'diet_type',
    text: '¿Qué tipo de dieta sigues?',
    type: QuestionType.select,
    options: [
      'Omnívora',
      'Vegetariana',
      'Vegana',
      'Cetogénica',
      'Sin gluten',
    ],
  ),

  // Preguntas específicas para dieta sin gluten
  Question(
    id: 'gluten_awareness',
    text: '¿Cuál es la razón principal por la que sigues una dieta sin gluten?',
    type: QuestionType.select,
    options: [
      'Celiaquía diagnosticada',
      'Sensibilidad al gluten',
      'Decisión personal',
      'Recomendación médica',
    ],
    parentId: 'diet_type',
    dependsOn: ['Sin gluten'],
  ),

  Question(
    id: 'gluten_substitutes',
    text: '¿Qué sustitutos de cereales con gluten consumes?',
    type: QuestionType.multiSelect,
    options: [
      'Arroz',
      'Quinoa',
      'Amaranto',
      'Maíz',
      'Trigo sarraceno',
      'Harina de almendras',
      'Harina de coco',
    ],
    parentId: 'diet_type',
    dependsOn: ['Sin gluten'],
  ),

  Question(
    id: 'gluten_free_proteins',
    text: '¿Qué fuentes de proteína consumes principalmente?',
    type: QuestionType.multiSelect,
    options: [
      'Pollo',
      'Pescado',
      'Res',
      'Cerdo',
      'Huevo',
      'Legumbres',
      'Quinoa',
      'Frutos secos',
      'Tofu',
      'Tempeh',
    ],
    parentId: 'diet_type',
    dependsOn: ['Sin gluten'],
  ),

  Question(
    id: 'gluten_free_protein_frequency',
    text: '¿Cuántas veces a la semana consumes %protein%?',
    type: QuestionType.frequencySelect,
    options: ['1 vez', '2 veces', '3 veces', '4 veces', '5 o más veces'],
    parentId: 'gluten_free_proteins',
  ),

  // Preguntas específicas para dieta omnívora
  Question(
    id: 'omnivore_proteins',
    text: '¿Qué proteínas animales consumes?',
    type: QuestionType.multiSelect,
    options: ['Pollo', 'Pescado', 'Res', 'Cerdo', 'Cordero', 'Huevo'],
    parentId: 'diet_type',
    dependsOn: ['Omnívora'],
  ),

  Question(
    id: 'protein_frequency',
    text: '¿Cuántas veces a la semana consumes %protein%?',
    type: QuestionType.frequencySelect,
    options: ['1 vez', '2 veces', '3 veces', '4 veces', '5 o más veces'],
    parentId: 'omnivore_proteins',
  ),

  // Preguntas específicas para dieta vegetariana
  Question(
    id: 'vegetarian_proteins',
    text: '¿Qué proteínas vegetarianas consumes?',
    type: QuestionType.multiSelect,
    options: ['Legumbres', 'Tofu', 'Tempeh', 'Seitán', 'Huevo'],
    parentId: 'diet_type',
    dependsOn: ['Vegetariana'],
  ),

  // Preguntas comunes para todas las dietas
  Question(
    id: 'vegetables',
    text: '¿Qué verduras sueles consumir?',
    type: QuestionType.multiSelect,
    options: [
      'Tomate',
      'Cebolla',
      'Pimentón',
      'Lechuga',
      'Zanahoria',
      'Espinaca',
      'Brócoli',
      'Pepino',
      'Calabacín',
      'Berenjena'
    ],
  ),

  Question(
    id: 'vegetables_frequency',
    text: '¿Con qué frecuencia consumes verduras?',
    type: QuestionType.select,
    options: [
      'Todos los días',
      '4-6 veces por semana',
      '2-3 veces por semana',
      '1 vez por semana',
      'Menos de una vez por semana'
    ],
  ),

  Question(
    id: 'water_intake',
    text: '¿Cuántos vasos de agua toma al día?',
    type: QuestionType.select,
    options: ['Menos de 4 vasos', '4-6 vasos', '6-8 vasos', 'Más de 8 vasos'],
  ),
  Question(
    id: 'bathroom_frequency',
    text: '¿Cuántas veces va al baño a la semana?',
    type: QuestionType.select,
    options: ['1 vez o menos', '2-3 veces', '4-5 veces', 'Más de 5 veces'],
  ),

  // Preguntas sobre ejercicio
  Question(
    id: 'exercise_type',
    text: '¿Qué tipo de ejercicio realiza principalmente?',
    type: QuestionType.multiSelect,
    options: [
      'Ninguno',
      'Caminar',
      'Correr',
      'Natación',
      'Pesas',
      'Yoga',
      'Deportes de equipo',
      'Otro'
    ],
  ),
];

// Función para determinar la siguiente pregunta basada en respuestas anteriores
int getNextQuestionIndex(String currentId, dynamic answer, int currentIndex) {
  // Lógica para el trabajo
  if (currentId == 'occupation_type') {
    if (answer != 'Trabajo' && answer != 'Ambos') {
      // Si no trabaja, buscamos la primera pregunta después de 'work_details'
      final workDetailsIndex =
          questionsList.indexWhere((q) => q.id == 'work_details');
      if (workDetailsIndex != -1 &&
          workDetailsIndex < questionsList.length - 1) {
        return workDetailsIndex + 1;
      }
    }
  }

  // Mantener la lógica existente
  if (currentId == 'has_pathology' && answer == false) {
    return questionsList.indexWhere((q) => q.id == 'has_family_history');
  }

  if (currentId == 'current_treatment' && answer == false) {
    return questionsList.indexWhere((q) => q.id == 'has_family_history');
  }

  if (currentId == 'has_family_history' && answer == false) {
    return questionsList.indexWhere((q) => q.id == 'digestive_issues');
  }

  return currentIndex + 1;
}

final questionsProvider =
    StateNotifierProvider<QuestionnaireNotifier, QuestionnaireState>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return QuestionnaireNotifier(notificationService);
});

/// Proveedor para controlar si las animaciones están habilitadas
final animationsEnabledProvider = StateProvider<bool>((ref) => true);
