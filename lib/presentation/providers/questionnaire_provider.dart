import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xenify/domain/entities/question.dart';
import 'package:xenify/domain/entities/questionnaire_state.dart';
import 'package:xenify/presentation/providers/notifiers/questionnaire_notifier.dart';

final questionsList = [
  // Pregunta de ubicación
  Question(
    id: 'location',
    text:
        'De donde eres? , conocer la cultura y condiciones genéticas de la región permiten personalizar mejor las recomendaciones.',
    type: QuestionType.location,
    isRequired: true,
  ),

  // Preguntas demográficas
  Question(
    id: 'birth_date',
    text: '¿Cuál es su fecha de nacimiento?',
    type: QuestionType.date,
  ),
  Question(
    id: 'gender',
    text: '¿Cuál es su género?',
    type: QuestionType.select,
    options: ['Masculino', 'Femenino', 'No binario', 'Prefiero no decir'],
  ),
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
      'Otra'
    ],
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
  if (currentId == 'occupation_type' &&
      answer != 'Trabajo' &&
      answer != 'Ambos') {
    // Si no trabaja, saltamos la pregunta de detalles del trabajo
    return questionsList.indexWhere((q) => q.id == 'has_pathology');
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
  return QuestionnaireNotifier();
});
