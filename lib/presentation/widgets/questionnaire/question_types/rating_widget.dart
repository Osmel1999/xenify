import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xenify/domain/entities/question.dart';
import 'package:xenify/presentation/theme/questionnaire_theme.dart';

/// Tipos de escala de valoración
enum RatingType {
  emoji, // Emojis (caras)
  stars, // Estrellas
  numeric, // Valores numéricos
}

/// Widget para preguntas con respuesta mediante escalas de valoración
class RatingWidget extends ConsumerStatefulWidget {
  /// La pregunta a mostrar
  final Question question;

  /// La categoría de la pregunta (determina el color)
  final QuestionCategory category;

  /// Callback para cuando se selecciona una valoración
  final Function(int) onRatingSelected;

  /// Valor actual (si existe)
  final int? currentRating;

  /// Cantidad de opciones en la escala (por defecto 5)
  final int ratingCount;

  /// Tipo de escala (emoji, estrellas, numérica)
  final RatingType ratingType;

  /// Etiquetas a mostrar (si aplica)
  final List<String>? labels;

  const RatingWidget({
    Key? key,
    required this.question,
    required this.category,
    required this.onRatingSelected,
    this.currentRating,
    this.ratingCount = 5,
    this.ratingType = RatingType.emoji,
    this.labels,
  }) : super(key: key);

  @override
  ConsumerState<RatingWidget> createState() => _RatingWidgetState();
}

class _RatingWidgetState extends ConsumerState<RatingWidget> {
  int? _selectedRating;

  @override
  void initState() {
    super.initState();
    _selectedRating = widget.currentRating;
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = QuestionnaireTheme.getCategoryColor(widget.category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Escala de valoración
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: _buildRatingScale(categoryColor),
        ),

        // Descripción de la valoración seleccionada (si aplica)
        if (_selectedRating != null &&
            widget.labels != null &&
            widget.labels!.length >= widget.ratingCount &&
            _selectedRating! > 0 &&
            _selectedRating! <= widget.labels!.length)
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: categoryColor.withOpacity(0.3),
              ),
            ),
            child: Text(
              widget.labels![_selectedRating! - 1],
              style: QuestionnaireTheme.optionTextStyle.copyWith(
                color: categoryColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),

        // Botón para confirmar
        if (_selectedRating != null)
          _buildConfirmButton(context, categoryColor),
      ],
    );
  }

  Widget _buildRatingScale(Color categoryColor) {
    switch (widget.ratingType) {
      case RatingType.emoji:
        return _buildEmojiRating(categoryColor);
      case RatingType.stars:
        return _buildStarsRating(categoryColor);
      case RatingType.numeric:
        return _buildNumericRating(categoryColor);
    }
  }

  Widget _buildEmojiRating(Color categoryColor) {
    // Lista de emojis correspondientes a los niveles de valoración
    final List<IconData> emojis = _getEmojiIcons();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(widget.ratingCount, (index) {
        final rating = index + 1;
        final isSelected = _selectedRating == rating;

        // Calcular color según posición en la escala
        final double intensity = index / (widget.ratingCount - 1);
        final Color emojiColor = _getGradientColor(intensity, categoryColor);

        return GestureDetector(
          onTap: () => _selectRating(rating),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  isSelected ? emojiColor.withOpacity(0.2) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Column(
              children: [
                Icon(
                  emojis[index],
                  size: isSelected ? 40 : 32,
                  color: emojiColor,
                ),
                if (widget.labels != null &&
                    widget.labels!.length == widget.ratingCount) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.labels![index],
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? emojiColor : Colors.grey,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStarsRating(Color categoryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.ratingCount, (index) {
        final rating = index + 1;
        final isSelected =
            _selectedRating != null && _selectedRating! >= rating;

        return GestureDetector(
          onTap: () => _selectRating(rating),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(8),
            child: Icon(
              isSelected ? Icons.star : Icons.star_border,
              color: isSelected ? categoryColor : Colors.grey.shade400,
              size: 36,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNumericRating(Color categoryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(widget.ratingCount, (index) {
        final rating = index + 1;
        final isSelected = _selectedRating == rating;

        return GestureDetector(
          onTap: () => _selectRating(rating),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? categoryColor : Colors.white,
              border: Border.all(
                color: isSelected ? categoryColor : Colors.grey.shade300,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: categoryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                rating.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildConfirmButton(BuildContext context, Color categoryColor) {
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
            if (_selectedRating != null) {
              widget.onRatingSelected(_selectedRating!);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Text(
              'Confirmar',
              style: QuestionnaireTheme.buttonTextStyle,
            ),
          ),
        ),
      ),
    );
  }

  // Actualiza la valoración seleccionada
  void _selectRating(int rating) {
    setState(() {
      _selectedRating = rating;
    });

    // Opcional: llamar al callback inmediatamente o esperar confirmación
    // widget.onRatingSelected(rating);
  }

  // Obtiene los iconos de emoji para cada nivel
  List<IconData> _getEmojiIcons() {
    if (widget.ratingCount == 3) {
      return [
        Icons.sentiment_very_dissatisfied,
        Icons.sentiment_neutral,
        Icons.sentiment_very_satisfied,
      ];
    } else if (widget.ratingCount == 5) {
      return [
        Icons.sentiment_very_dissatisfied,
        Icons.sentiment_dissatisfied,
        Icons.sentiment_neutral,
        Icons.sentiment_satisfied,
        Icons.sentiment_very_satisfied,
      ];
    } else {
      // Generar una lista de longitud variable (menos precisa)
      return List.generate(widget.ratingCount, (index) {
        final normalized = index / (widget.ratingCount - 1);
        if (normalized < 0.25) {
          return Icons.sentiment_very_dissatisfied;
        } else if (normalized < 0.5) {
          return Icons.sentiment_dissatisfied;
        } else if (normalized < 0.75) {
          return Icons.sentiment_satisfied;
        } else {
          return Icons.sentiment_very_satisfied;
        }
      });
    }
  }

  // Obtiene un color a lo largo de un gradiente según la intensidad
  Color _getGradientColor(double intensity, Color baseColor) {
    if (intensity < 0.5) {
      // Desde rojo (0) hasta amarillo (0.5)
      return Color.lerp(
        Colors.red.shade700,
        Colors.amber.shade500,
        intensity * 2,
      )!;
    } else {
      // Desde amarillo (0.5) hasta verde (1.0)
      return Color.lerp(
        Colors.amber.shade500,
        Colors.green.shade600,
        (intensity - 0.5) * 2,
      )!;
    }
  }
}
