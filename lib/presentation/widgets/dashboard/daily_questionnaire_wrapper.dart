import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xenify/presentation/providers/daily_questionnaire_provider.dart';
import 'package:xenify/presentation/screens/dashboard_screen.dart';
import 'package:xenify/presentation/screens/daily_questionnaire_screen.dart';

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
    extends ConsumerState<DailyQuestionnaireWrapper> {
  bool _hasCheckedQuestionnaire = false;

  @override
  void initState() {
    super.initState();
    // Programar la verificación del cuestionario después de que el widget se construya
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkQuestionnaire();
    });
  }

  void _checkQuestionnaire() {
    if (_hasCheckedQuestionnaire) return;

    final questionnaire = ref.read(currentQuestionnaireProvider);
    if (questionnaire != null &&
        ref.read(dailyQuestionnaireServiceProvider).shouldShowQuestionnaire(
              questionnaire.type,
            )) {
      _showQuestionnaireDialog();
    }

    setState(() {
      _hasCheckedQuestionnaire = true;
    });
  }

  void _showQuestionnaireDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Text(
          ref.read(currentQuestionnaireProvider)?.isMorning == true
              ? '¿Cómo te sientes esta mañana?'
              : '¿Cómo estuvo tu día?',
        ),
        content: const Text(
          'Es hora de tu cuestionario diario. Esto nos ayudará a monitorear tu bienestar.',
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
