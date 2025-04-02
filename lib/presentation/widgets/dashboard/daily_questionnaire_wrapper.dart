import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xenify/presentation/providers/daily_questionnaire_provider.dart';
import 'package:xenify/presentation/screens/dashboard_screen.dart';
import 'package:xenify/presentation/screens/daily_questionnaire_screen.dart';
import 'package:xenify/domain/entities/daily_questionnaire.dart';

class DailyQuestionnaireWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const DailyQuestionnaireWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  ConsumerState<DailyQuestionnaireWrapper> createState() =>
      _DailyQuestionnaireWrapperState();
}

class _DailyQuestionnaireWrapperState
    extends ConsumerState<DailyQuestionnaireWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Verificar cuestionario después de que el widget se construya
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkQuestionnaires();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('🔄 App resumed - Verificando cuestionarios pendientes...');
      _checkQuestionnaires();
    }
  }

  void _checkQuestionnaires() {
    final dailyQuestionnaireService =
        ref.read(dailyQuestionnaireServiceProvider);

    // Verificar ambos tipos de cuestionarios
    final shouldShowMorning = dailyQuestionnaireService
        .shouldShowQuestionnaire(QuestionnaireType.morning);
    final shouldShowEvening = dailyQuestionnaireService
        .shouldShowQuestionnaire(QuestionnaireType.evening);

    print('📝 Estado de cuestionarios:');
    print('- Matutino pendiente: $shouldShowMorning');
    print('- Nocturno pendiente: $shouldShowEvening');

    if (shouldShowMorning || shouldShowEvening) {
      _showQuestionnaireDialog(
        isMorning: shouldShowMorning,
        isEvening: shouldShowEvening,
      );
    }
  }

  void _showQuestionnaireDialog({
    required bool isMorning,
    required bool isEvening,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Text(
          isMorning && isEvening
              ? '¡Tienes cuestionarios pendientes!'
              : isMorning
                  ? '¿Cómo te sientes esta mañana?'
                  : '¿Cómo estuvo tu día?',
        ),
        content: Text(
          isMorning && isEvening
              ? 'Tienes pendiente el cuestionario matutino y nocturno. Los combinaremos para hacerlo más fácil.'
              : 'Es hora de tu cuestionario diario. Esto nos ayudará a monitorear tu bienestar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Más tarde'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DailyQuestionnaireScreen(),
                ),
              );
            },
            child: const Text('Completar ahora'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
