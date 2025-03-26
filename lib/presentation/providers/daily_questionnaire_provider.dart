import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xenify/presentation/providers/notifiers/daily_questionnaire_notifier.dart';
import 'package:xenify/presentation/providers/states/daily_questionnaire_state.dart';

// Provider para el estado del cuestionario diario
final dailyQuestionnaireStateProvider =
    StateNotifierProvider<DailyQuestionnaireNotifier, DailyQuestionnaireState>(
  (ref) => DailyQuestionnaireNotifier(),
);
