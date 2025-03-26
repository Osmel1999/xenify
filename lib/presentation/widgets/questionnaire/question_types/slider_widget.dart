import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xenify/domain/entities/question.dart';
import 'package:xenify/presentation/theme/questionnaire_theme.dart';

/// Widget para preguntas con respuesta mediante deslizador (slider)
class SliderWidget extends ConsumerStatefulWidget {
  /// La pregunta a mostrar
  final Question question;

  /// La categoría de la pregunta (determina el color)
  final QuestionCategory category;

  /// Callback para cuando cambia el valor del slider
  final Function(double) onValueChanged;

  /// Valor actual (si existe)
  final double? currentValue;

  /// Valor mínimo del slider
  final double minValue;

  /// Valor máximo del slider
  final double maxValue;

  /// Divisiones del slider (opcional)
  final int? divisions;

  /// Formato para mostrar el valor actual
  final String Function(double)? valueFormatter;

  const SliderWidget({
    Key? key,
    required this.question,
    required this.category,
    required this.onValueChanged,
    this.currentValue,
    this.minValue = 0.0,
    this.maxValue = 100.0,
    this.divisions,
    this.valueFormatter,
  }) : super(key: key);

  @override
  ConsumerState<SliderWidget> createState() => _SliderWidgetState();
}

class _SliderWidgetState extends ConsumerState<SliderWidget> {
  late double _value;

  @override
  void initState() {
    super.initState();
    // Inicializar con el valor actual o el valor del medio
    _value = widget.currentValue ?? (widget.minValue + widget.maxValue) / 2;
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = QuestionnaireTheme.getCategoryColor(widget.category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Valor actual
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: categoryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getValueIcon(),
                color: categoryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _formatValue(_value),
                style: QuestionnaireTheme.questionTextStyle.copyWith(
                  fontSize: 18,
                  color: categoryColor,
                ),
              ),
            ],
          ),
        ),

        // Slider
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            activeTrackColor: categoryColor,
            inactiveTrackColor: Colors.grey.withOpacity(0.2),
            thumbColor: categoryColor,
            thumbShape: _CustomSliderThumbShape(color: categoryColor),
            overlayColor: categoryColor.withOpacity(0.2),
            valueIndicatorColor: categoryColor,
            valueIndicatorTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: Slider(
            value: _value,
            min: widget.minValue,
            max: widget.maxValue,
            divisions: widget.divisions,
            label: _formatValue(_value),
            onChanged: (value) {
              setState(() {
                _value = value;
              });
              widget.onValueChanged(value);
            },
          ),
        ),

        // Etiquetas min/max
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatValue(widget.minValue),
                style: QuestionnaireTheme.secondaryTextStyle,
              ),
              Text(
                _formatValue(widget.maxValue),
                style: QuestionnaireTheme.secondaryTextStyle,
              ),
            ],
          ),
        ),

        // Botón para confirmar
        _buildConfirmButton(context, categoryColor),
      ],
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
            widget.onValueChanged(_value);
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

  // Formatea el valor según el formato proporcionado o por defecto
  String _formatValue(double value) {
    if (widget.valueFormatter != null) {
      return widget.valueFormatter!(value);
    }

    // Si el valor es entero, mostrarlo sin decimales
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }

    return value.toStringAsFixed(1);
  }

  // Determina un icono según el valor relativo (bajo, medio, alto)
  IconData _getValueIcon() {
    final range = widget.maxValue - widget.minValue;
    final normalizedValue = (_value - widget.minValue) / range;

    if (normalizedValue < 0.33) {
      return Icons.arrow_downward;
    } else if (normalizedValue < 0.66) {
      return Icons.horizontal_rule;
    } else {
      return Icons.arrow_upward;
    }
  }
}

/// Forma personalizada para el pulgar del slider
class _CustomSliderThumbShape extends SliderComponentShape {
  final Color color;

  const _CustomSliderThumbShape({
    required this.color,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(20, 20);
  }

  @override
  void paint(PaintingContext context, Offset center,
      {required Animation<double> activationAnimation,
      required Animation<double> enableAnimation,
      required bool isDiscrete,
      required TextPainter labelPainter,
      required RenderBox parentBox,
      required SliderThemeData sliderTheme,
      required TextDirection textDirection,
      required double value,
      required double textScaleFactor,
      required Size sizeWithOverflow}) {
    final canvas = context.canvas;

    // Sombra
    final shadowPath = Path()
      ..addOval(Rect.fromCenter(center: center, width: 24, height: 24));

    canvas.drawShadow(shadowPath, Colors.black.withOpacity(0.3), 2, true);

    // Círculo externo blanco
    final outerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 12, outerPaint);

    // Círculo interno con el color de la categoría
    final innerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 8, innerPaint);
  }
}
