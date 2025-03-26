import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xenify/domain/entities/question.dart';
import 'package:xenify/presentation/theme/questionnaire_theme.dart';

/// Widget para preguntas de selección múltiple (checkboxes)
class MultipleSelectionWidget extends ConsumerWidget {
  /// La pregunta a mostrar
  final Question question;

  /// La categoría de la pregunta (determina el color)
  final QuestionCategory category;

  /// Callback para cuando se actualiza una selección
  final Function(List<String>) onSelectionUpdated;

  /// Lista de opciones actualmente seleccionadas
  final List<String> selectedOptions;

  /// Indica si se requiere al menos una selección
  final bool isRequired;

  const MultipleSelectionWidget({
    Key? key,
    required this.question,
    required this.category,
    required this.onSelectionUpdated,
    required this.selectedOptions,
    this.isRequired = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryColor = QuestionnaireTheme.getCategoryColor(category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Opciones
        ...question.options!.map((option) {
          final isSelected = selectedOptions.contains(option);

          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: _buildCheckbox(option, isSelected, categoryColor),
          );
        }).toList(),

        const SizedBox(height: 8),

        // Mensaje de ayuda (opcional)
        if (isRequired)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              selectedOptions.isEmpty
                  ? 'Por favor, selecciona al menos una opción.'
                  : 'Puedes seleccionar varias opciones.',
              style: QuestionnaireTheme.secondaryTextStyle.copyWith(
                fontStyle: FontStyle.italic,
                color: selectedOptions.isEmpty
                    ? Colors.red.shade700
                    : QuestionnaireTheme.textTertiaryColor,
              ),
            ),
          ),

        // Botón de continuar
        if (selectedOptions.isNotEmpty || !isRequired)
          _buildContinueButton(context, categoryColor),
      ],
    );
  }

  Widget _buildCheckbox(String option, bool isSelected, Color categoryColor) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _toggleOption(option),
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
                // Checkbox personalizado
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSelected
                          ? categoryColor
                          : Colors.grey.withOpacity(0.5),
                      width: 2,
                    ),
                    color: isSelected ? categoryColor : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context, Color categoryColor) {
    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: categoryColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: categoryColor.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: () {
            // Si no hay selecciones y se selecciona "Continuar", usar "Ninguno" como valor por defecto
            if (selectedOptions.isEmpty &&
                isRequired &&
                question.options!.contains('Ninguno')) {
              final updatedSelection = ['Ninguno'];
              onSelectionUpdated(updatedSelection);
            } else {
              onSelectionUpdated(selectedOptions);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Text(
              'Continuar',
              style: QuestionnaireTheme.buttonTextStyle,
            ),
          ),
        ),
      ),
    );
  }

  void _toggleOption(String option) {
    List<String> updatedSelection = List<String>.from(selectedOptions);

    // Si la opción es "Ninguno", deseleccionar todas las demás
    if (option == 'Ninguno') {
      if (updatedSelection.contains('Ninguno')) {
        updatedSelection.remove('Ninguno');
      } else {
        updatedSelection = ['Ninguno'];
      }
    } else {
      // Si se selecciona otra opción, quitar "Ninguno" si estaba seleccionado
      if (updatedSelection.contains('Ninguno')) {
        updatedSelection.remove('Ninguno');
      }

      // Alternar la selección de la opción
      if (updatedSelection.contains(option)) {
        updatedSelection.remove(option);
      } else {
        updatedSelection.add(option);
      }
    }

    onSelectionUpdated(updatedSelection);
  }
}
