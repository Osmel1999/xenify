import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xenify/domain/entities/question.dart';
import 'package:xenify/domain/entities/daily_questionnaire_type.dart';
import 'package:xenify/presentation/providers/daily_questionnaire_provider.dart';

class DailyQuestionnaireModal extends ConsumerWidget {
  const DailyQuestionnaireModal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dailyQuestionnaireStateProvider);

    // Si el cuestionario no está activo, no mostrar nada
    if (!state.isActive) {
      return const SizedBox.shrink();
    }

    // Si el cuestionario está completado, mostrar mensaje de agradecimiento
    if (state.isCompleted) {
      return _buildCompletedModal(context, ref);
    }

    // Si hay preguntas, mostrar la pregunta actual
    if (state.questions.isNotEmpty) {
      final currentQuestion = state.questions[state.currentQuestionIndex];
      return _buildQuestionModal(context, ref, currentQuestion);
    }

    return const SizedBox.shrink();
  }

  // Construir el modal cuando el cuestionario está completado
  Widget _buildCompletedModal(BuildContext context, WidgetRef ref) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                '¡Gracias por completar el cuestionario!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(dailyQuestionnaireStateProvider.notifier)
                      .closeQuestionnaire();
                },
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Construir el modal para mostrar una pregunta del cuestionario
  Widget _buildQuestionModal(
      BuildContext context, WidgetRef ref, Question question) {
    final state = ref.watch(dailyQuestionnaireStateProvider);

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _getQuestionnaireTitle(
                  ref.read(dailyQuestionnaireStateProvider).activeType),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: (state.currentQuestionIndex + 1) / state.questions.length,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 24),
            Text(
              question.text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildAnswerOptions(context, ref, question),
          ],
        ),
      ),
    );
  }

  // Construir las opciones de respuesta según el tipo de pregunta
  Widget _buildAnswerOptions(
      BuildContext context, WidgetRef ref, Question question) {
    switch (question.type) {
      case QuestionType.select:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...question.options!.map((option) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ElevatedButton(
                    onPressed: () {
                      ref
                          .read(dailyQuestionnaireStateProvider.notifier)
                          .answerQuestion(question.id, option);
                    },
                    child: Text(option),
                  ),
                )),
          ],
        );

      case QuestionType.yesNo:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {
                ref
                    .read(dailyQuestionnaireStateProvider.notifier)
                    .answerQuestion(question.id, true);
              },
              child: const Text('Sí'),
            ),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(dailyQuestionnaireStateProvider.notifier)
                    .answerQuestion(question.id, false);
              },
              child: const Text('No'),
            ),
          ],
        );

      case QuestionType.multiSelect:
        final List<String> selectedOptions = (ref
                .watch(dailyQuestionnaireStateProvider)
                .responses[question.id] as List<String>?) ??
            [];

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...question.options!.map((option) => CheckboxListTile(
                  title: Text(option),
                  value: selectedOptions.contains(option),
                  onChanged: (bool? value) {
                    List<String> newSelection = List.from(selectedOptions);
                    if (value == true) {
                      if (!newSelection.contains(option)) {
                        newSelection.add(option);
                      }
                    } else {
                      newSelection.remove(option);
                    }

                    // Actualizar respuestas en tiempo real
                    ref
                        .read(dailyQuestionnaireStateProvider.notifier)
                        .answerQuestion(question.id, newSelection);
                  },
                )),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (selectedOptions.isEmpty) {
                  // Si no hay selecciones, agregar "Ninguno" automáticamente
                  List<String> defaultSelection = ['Ninguno'];
                  ref
                      .read(dailyQuestionnaireStateProvider.notifier)
                      .answerQuestion(question.id, defaultSelection);
                } else {
                  // Continuar con las selecciones actuales
                  ref
                      .read(dailyQuestionnaireStateProvider.notifier)
                      .answerQuestion(question.id, selectedOptions);
                }
              },
              child: const Text('Continuar'),
            ),
          ],
        );

      default:
        return const Text('Tipo de pregunta no soportado');
    }
  }

  // Obtener el título del cuestionario según el tipo
  String _getQuestionnaireTitle(DailyQuestionnaireType? type) {
    switch (type) {
      case DailyQuestionnaireType.sleep:
        return 'Cuestionario de Sueño';
      case DailyQuestionnaireType.morning:
        return 'Cuestionario Matutino';
      case DailyQuestionnaireType.afternoon:
        return 'Cuestionario de Tarde';
      case DailyQuestionnaireType.evening:
        return 'Cuestionario Nocturno';
      case DailyQuestionnaireType.postMeal:
        return 'Cuestionario Post-Comida';
      default:
        return 'Cuestionario Diario';
    }
  }
}
