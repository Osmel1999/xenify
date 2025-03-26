import 'package:flutter/material.dart';
import 'package:xenify/presentation/theme/questionnaire_theme.dart';

/// Barra de progreso que muestra el avance en el cuestionario.
/// Cambia de color según la categoría de la pregunta actual.
class QuestionnaireProgressBar extends StatelessWidget {
  /// Valor actual de progreso (de 0.0 a 1.0)
  final double progress;

  /// Categoría de la pregunta actual (determina el color)
  final QuestionCategory category;

  /// Texto opcional para mostrar el progreso (ej. "3/10")
  final String? progressText;

  /// Indica si se debe mostrar animación
  final bool animate;

  /// Duración de la animación
  final Duration animationDuration;

  const QuestionnaireProgressBar({
    Key? key,
    required this.progress,
    required this.category,
    this.progressText,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categoryColor = QuestionnaireTheme.getCategoryColor(category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Fila con texto de progreso si está disponible
        if (progressText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progreso',
                  style: QuestionnaireTheme.secondaryTextStyle,
                ),
                Text(
                  progressText!,
                  style: QuestionnaireTheme.secondaryTextStyle.copyWith(
                    fontWeight: FontWeight.w500,
                    color: categoryColor,
                  ),
                ),
              ],
            ),
          ),

        // Barra de progreso
        Container(
          height: QuestionnaireTheme.progressBarHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: QuestionnaireTheme.disabledColor,
            borderRadius:
                BorderRadius.circular(QuestionnaireTheme.progressBarHeight / 2),
          ),
          child: Stack(
            children: [
              // Progreso actual
              AnimatedContainer(
                duration: animate ? animationDuration : Duration.zero,
                curve: Curves.easeInOut,
                height: QuestionnaireTheme.progressBarHeight,
                width: double.infinity * progress,
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: BorderRadius.circular(
                      QuestionnaireTheme.progressBarHeight / 2),
                  boxShadow: [
                    BoxShadow(
                      color: categoryColor.withOpacity(0.3),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Versión avanzada de la barra de progreso que también muestra secciones.
/// Útil para cuestionarios divididos en múltiples categorías o secciones.
class QuestionnaireSegmentedProgressBar extends StatelessWidget {
  /// Valor actual de progreso (de 0.0 a 1.0)
  final double progress;

  /// Lista de secciones del cuestionario con sus respectivas categorías
  final List<ProgressSegment> segments;

  /// Texto opcional para mostrar el progreso (ej. "3/10")
  final String? progressText;

  /// Índice de la sección actual
  final int currentSegmentIndex;

  /// Indica si se debe mostrar animación
  final bool animate;

  /// Duración de la animación
  final Duration animationDuration;

  const QuestionnaireSegmentedProgressBar({
    Key? key,
    required this.progress,
    required this.segments,
    required this.currentSegmentIndex,
    this.progressText,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Fila con texto de progreso si está disponible
        if (progressText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      segments[currentSegmentIndex].category.icon,
                      size: 16,
                      color: QuestionnaireTheme.getCategoryColor(
                        segments[currentSegmentIndex].category,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      segments[currentSegmentIndex].title,
                      style: QuestionnaireTheme.secondaryTextStyle.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  progressText!,
                  style: QuestionnaireTheme.secondaryTextStyle.copyWith(
                    fontWeight: FontWeight.w500,
                    color: QuestionnaireTheme.getCategoryColor(
                      segments[currentSegmentIndex].category,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Barra de progreso segmentada
        Container(
          height: QuestionnaireTheme.progressBarHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: QuestionnaireTheme.disabledColor,
            borderRadius:
                BorderRadius.circular(QuestionnaireTheme.progressBarHeight / 2),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calcular el ancho total disponible
              final totalWidth = constraints.maxWidth;
              double currentPosition = 0;

              // Crear los segmentos de la barra
              return Stack(
                children: segments.map((segment) {
                  // Calcular el ancho de este segmento
                  final segmentWidth = totalWidth * segment.weight;
                  final segmentColor =
                      QuestionnaireTheme.getCategoryColor(segment.category);

                  // Calcular el progreso dentro de este segmento
                  final segmentProgress = _calculateSegmentProgress(
                    currentPosition / totalWidth,
                    (currentPosition + segmentWidth) / totalWidth,
                    progress,
                  );

                  // Crear el widget del segmento
                  final segmentWidget = Positioned(
                    left: currentPosition,
                    child: AnimatedContainer(
                      duration: animate ? animationDuration : Duration.zero,
                      curve: Curves.easeInOut,
                      height: QuestionnaireTheme.progressBarHeight,
                      width: segmentWidth * segmentProgress,
                      decoration: BoxDecoration(
                        color: segmentColor,
                        borderRadius: _getSegmentBorderRadius(
                          currentPosition,
                          segmentWidth,
                          totalWidth,
                          segmentProgress,
                        ),
                      ),
                    ),
                  );

                  // Actualizar la posición para el siguiente segmento
                  currentPosition += segmentWidth;

                  return segmentWidget;
                }).toList(),
              );
            },
          ),
        ),

        // Indicadores de secciones
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: segments.map((segment) {
              final isActive = segments.indexOf(segment) <= currentSegmentIndex;
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? QuestionnaireTheme.getCategoryColor(segment.category)
                      : QuestionnaireTheme.disabledColor,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Calcula el progreso dentro de un segmento específico
  double _calculateSegmentProgress(
      double segmentStart, double segmentEnd, double totalProgress) {
    if (totalProgress <= segmentStart) {
      return 0.0;
    } else if (totalProgress >= segmentEnd) {
      return 1.0;
    } else {
      // Progreso proporcional dentro del segmento
      return (totalProgress - segmentStart) / (segmentEnd - segmentStart);
    }
  }

  /// Calcula el radio de borde apropiado para un segmento
  BorderRadius _getSegmentBorderRadius(
    double position,
    double width,
    double totalWidth,
    double segmentProgress,
  ) {
    final radius = QuestionnaireTheme.progressBarHeight / 2;

    // Si es el inicio de la barra y tiene progreso
    if (position == 0 && segmentProgress > 0) {
      // Si no llena el segmento completo
      if (segmentProgress < 1.0) {
        return BorderRadius.only(
          topLeft: Radius.circular(radius),
          bottomLeft: Radius.circular(radius),
        );
      }
    }

    // Si es el final de la barra y está completamente lleno
    if (position + width == totalWidth && segmentProgress == 1.0) {
      return BorderRadius.circular(radius);
    }

    // Caso por defecto
    return BorderRadius.zero;
  }
}

/// Representa un segmento en la barra de progreso
class ProgressSegment {
  /// Título del segmento
  final String title;

  /// Categoría del segmento (determina el color)
  final QuestionCategory category;

  /// Peso relativo del segmento (proporción del ancho total)
  final double weight;

  const ProgressSegment({
    required this.title,
    required this.category,
    this.weight = 1.0,
  });
}
