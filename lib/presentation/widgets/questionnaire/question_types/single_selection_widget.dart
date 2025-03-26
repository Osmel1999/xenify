import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xenify/domain/entities/question.dart';
import 'package:xenify/presentation/theme/questionnaire_theme.dart';

/// Widget para preguntas de selección única (tipo radio button)
class SingleSelectionWidget extends ConsumerWidget {
  /// La pregunta a mostrar
  final Question question;

  /// La categoría de la pregunta (determina el color)
  final QuestionCategory category;

  /// Callback para cuando se selecciona una opción
  final Function(String) onOptionSelected;

  /// Opción actualmente seleccionada (si hay)
  final String? currentSelectedOption;

  const SingleSelectionWidget({
    Key? key,
    required this.question,
    required this.category,
    required this.onOptionSelected,
    this.currentSelectedOption,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryColor = QuestionnaireTheme.getCategoryColor(category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: question.options!.map((option) {
        final isSelected = option == currentSelectedOption;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildOptionCard(option, isSelected, categoryColor),
        );
      }).toList(),
    );
  }

  Widget _buildOptionCard(String option, bool isSelected, Color categoryColor) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onOptionSelected(option),
        borderRadius: BorderRadius.circular(8),
        splashColor: categoryColor.withOpacity(0.1),
        highlightColor: categoryColor.withOpacity(0.05),
        child: Ink(
          decoration: BoxDecoration(
            color: isSelected ? categoryColor.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? categoryColor : Colors.grey.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Radio button
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? categoryColor
                          : Colors.grey.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: isSelected
                        ? Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: categoryColor,
                            ),
                          )
                        : null,
                  ),
                ),

                const SizedBox(width: 16),

                // Texto de la opción
                Expanded(
                  child: Text(
                    option,
                    style: QuestionnaireTheme.optionTextStyle.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w500 : FontWeight.normal,
                      color: isSelected
                          ? QuestionnaireTheme.textPrimaryColor
                          : QuestionnaireTheme.textSecondaryColor,
                    ),
                  ),
                ),

                // Icono de seleccionado (opcional)
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: categoryColor,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
