import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xenify/presentation/providers/questionnaire_provider.dart';
import 'package:xenify/presentation/widgets/question_widget.dart';

class QuestionnaireScreen extends ConsumerWidget {
  const QuestionnaireScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(questionsProvider);

    return PopScope(
      canPop: state.currentQuestionIndex == 0,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (state.currentQuestionIndex > 0) {
          ref.read(questionsProvider.notifier).goBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: state.currentQuestionIndex > 0
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    ref.read(questionsProvider.notifier).goBack();
                  },
                )
              : null,
          title: const Text('Cuestionario de Salud'),
        ),
        body: state.isCompleted
            ? const Center(child: Text('¡Cuestionario completado!'))
            : const QuestionWidget(),
      ),
    );
  }
}
