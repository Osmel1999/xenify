import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xenify/presentation/providers/daily_questionnaire_provider.dart';
import 'package:xenify/presentation/widgets/daily_questionnaire/daily_questionnaire_modal.dart';

class DailyQuestionnaireChecker extends ConsumerStatefulWidget {
  final Widget child;

  const DailyQuestionnaireChecker({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  ConsumerState<DailyQuestionnaireChecker> createState() =>
      _DailyQuestionnaireCheckerState();
}

class _DailyQuestionnaireCheckerState
    extends ConsumerState<DailyQuestionnaireChecker> {
  @override
  void initState() {
    super.initState();
    // Verificar si hay que mostrar algún cuestionario al iniciar la aplicación
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(dailyQuestionnaireStateProvider.notifier)
          .checkAndShowActiveQuestionnaire();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        DailyQuestionnaireModal(),
      ],
    );
  }
}
