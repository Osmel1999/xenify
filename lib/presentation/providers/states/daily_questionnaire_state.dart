import 'package:xenify/domain/entities/question.dart';
import 'package:xenify/domain/entities/daily_questionnaire_type.dart';

class DailyQuestionnaireState {
  final bool isActive;
  final DailyQuestionnaireType? activeType;
  final int currentQuestionIndex;
  final Map<String, dynamic> responses;
  final List<Question> questions;
  final bool isCompleted;

  DailyQuestionnaireState({
    this.isActive = false,
    this.activeType,
    this.currentQuestionIndex = 0,
    this.responses = const {},
    this.questions = const [],
    this.isCompleted = false,
  });

  DailyQuestionnaireState copyWith({
    bool? isActive,
    DailyQuestionnaireType? activeType,
    int? currentQuestionIndex,
    Map<String, dynamic>? responses,
    List<Question>? questions,
    bool? isCompleted,
  }) {
    return DailyQuestionnaireState(
      isActive: isActive ?? this.isActive,
      activeType: activeType ?? this.activeType,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      responses: responses ?? this.responses,
      questions: questions ?? this.questions,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
