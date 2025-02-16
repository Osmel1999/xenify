class Question {
  final String id;
  final String text;
  final QuestionType type;
  final List<String>? options;
  final String? hint;
  final bool isRequired;
  final String?
      parentId; // ID de la pregunta padre (para preguntas dependientes)
  final List<String>? dependsOn; // Valores de los que depende esta pregunta

  Question({
    required this.id,
    required this.text,
    required this.type,
    this.options,
    this.hint,
    this.isRequired = true,
    this.parentId,
    this.dependsOn,
  });
}

enum QuestionType {
  yesNo,
  text,
  number,
  date,
  select,
  multiSelect,
  medication,
  familyHistory,
  location,
  dietaryOptions, // Nuevo tipo para opciones de dieta
  frequencySelect, // Nuevo tipo para frecuencia de consumo
}
