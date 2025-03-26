import 'dart:convert';

class DailyQuestionnaireResponse {
  final String date;
  final String questionnaireType;
  final Map<String, dynamic> responses;

  DailyQuestionnaireResponse({
    required this.date,
    required this.questionnaireType,
    required this.responses,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'questionnaireType': questionnaireType,
      'responses': responses,
    };
  }

  factory DailyQuestionnaireResponse.fromJson(Map<String, dynamic> json) {
    return DailyQuestionnaireResponse(
      date: json['date'],
      questionnaireType: json['questionnaireType'],
      responses: Map<String, dynamic>.from(json['responses']),
    );
  }
}
