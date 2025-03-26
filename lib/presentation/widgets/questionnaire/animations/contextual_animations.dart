import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:xenify/domain/entities/question.dart';
import 'package:xenify/presentation/theme/questionnaire_theme.dart';

/// Controlador para animaciones contextuales basadas en el tipo de pregunta
class ContextualAnimations {
  /// Obtiene la animación contextual apropiada para el tipo de pregunta
  static Widget wrapWithContextualAnimation({
    required Widget child,
    required QuestionCategory category,
    required QuestionType questionType,
    bool animate = true,
  }) {
    if (!animate) {
      return child;
    }

    switch (questionType) {
      case QuestionType.time:
        return _TimeAnimation(
          child: child,
          category: category,
        );

      case QuestionType.select:
      case QuestionType.multiSelect:
      case QuestionType.dietaryOptions:
        return _SelectionAnimation(
          child: child,
          category: category,
        );

      case QuestionType.yesNo:
        return _YesNoAnimation(
          child: child,
          category: category,
        );

      case QuestionType.medication:
        return _MedicationAnimation(
          child: child,
          category: category,
        );

      default:
        // Sin animación contextual específica
        return child;
    }
  }
}

/// Animación contextual para preguntas relacionadas con el tiempo
class _TimeAnimation extends StatefulWidget {
  final Widget child;
  final QuestionCategory category;

  const _TimeAnimation({
    Key? key,
    required this.child,
    required this.category,
  }) : super(key: key);

  @override
  State<_TimeAnimation> createState() => _TimeAnimationState();
}

class _TimeAnimationState extends State<_TimeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = QuestionnaireTheme.getCategoryColor(widget.category);

    return Stack(
      children: [
        widget.child,

        // Reloj animado decorativo en la esquina superior derecha
        Positioned(
          top: 16,
          right: 16,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return SizedBox(
                width: 36,
                height: 36,
                child: CustomPaint(
                  painter: _ClockPainter(
                    color: categoryColor,
                    progress: _controller.value,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Pintor personalizado para el reloj animado
class _ClockPainter extends CustomPainter {
  final Color color;
  final double progress;

  _ClockPainter({
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Dibujar círculo exterior
    final outerPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius, outerPaint);

    // Dibujar marcas de hora
    final hourMarkPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * math.pi / 180;
      final outerPoint = Offset(
        center.dx + (radius - 2) * math.cos(angle),
        center.dy + (radius - 2) * math.sin(angle),
      );
      final innerPoint = Offset(
        center.dx + (radius - 5) * math.cos(angle),
        center.dy + (radius - 5) * math.sin(angle),
      );

      canvas.drawLine(innerPoint, outerPoint, hourMarkPaint);
    }

    // Dibujar manecilla de hora
    final hourHandPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final hourAngle = (progress * 2 * math.pi) + math.pi / 2;
    final hourHandLength = radius * 0.5;
    final hourHand = Offset(
      center.dx + hourHandLength * math.cos(hourAngle),
      center.dy + hourHandLength * math.sin(hourAngle),
    );

    canvas.drawLine(center, hourHand, hourHandPaint);

    // Dibujar manecilla de minuto
    final minuteHandPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final minuteAngle = (progress * 24 * math.pi) + math.pi / 2;
    final minuteHandLength = radius * 0.75;
    final minuteHand = Offset(
      center.dx + minuteHandLength * math.cos(minuteAngle),
      center.dy + minuteHandLength * math.sin(minuteAngle),
    );

    canvas.drawLine(center, minuteHand, minuteHandPaint);

    // Dibujar punto central
    final centerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 2, centerPaint);
  }

  @override
  bool shouldRepaint(_ClockPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// Animación contextual para preguntas de selección
class _SelectionAnimation extends StatefulWidget {
  final Widget child;
  final QuestionCategory category;

  const _SelectionAnimation({
    Key? key,
    required this.child,
    required this.category,
  }) : super(key: key);

  @override
  State<_SelectionAnimation> createState() => _SelectionAnimationState();
}

class _SelectionAnimationState extends State<_SelectionAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = QuestionnaireTheme.getCategoryColor(widget.category);

    return Stack(
      children: [
        widget.child,

        // Indicador de selección en la esquina superior
        Positioned(
          top: 16,
          right: 16,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.touch_app,
                    color: categoryColor,
                    size: 22,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Animación contextual para preguntas de sí/no
class _YesNoAnimation extends StatefulWidget {
  final Widget child;
  final QuestionCategory category;

  const _YesNoAnimation({
    Key? key,
    required this.child,
    required this.category,
  }) : super(key: key);

  @override
  State<_YesNoAnimation> createState() => _YesNoAnimationState();
}

class _YesNoAnimationState extends State<_YesNoAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _rotationAnimation = Tween<double>(
      begin: -0.05,
      end: 0.05,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = QuestionnaireTheme.getCategoryColor(widget.category);

    return Stack(
      children: [
        widget.child,

        // Indicadores de sí/no balanceándose
        Positioned(
          top: 20,
          right: 20,
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: -_rotationAnimation.value,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.green,
                        size: 18,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.red,
                        size: 18,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Animación contextual para preguntas de medicación
class _MedicationAnimation extends StatefulWidget {
  final Widget child;
  final QuestionCategory category;

  const _MedicationAnimation({
    Key? key,
    required this.child,
    required this.category,
  }) : super(key: key);

  @override
  State<_MedicationAnimation> createState() => _MedicationAnimationState();
}

class _MedicationAnimationState extends State<_MedicationAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _floatAnimation = Tween<double>(
      begin: 0,
      end: 6,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = QuestionnaireTheme.getCategoryColor(widget.category);

    return Stack(
      children: [
        widget.child,

        // Animación de píldora flotante
        Positioned(
          top: 16,
          right: 16,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -_floatAnimation.value),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.medication,
                    color: categoryColor,
                    size: 22,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Widget de animación de estado de ánimo con transición de colores
class MoodTransitionAnimation extends StatefulWidget {
  /// Widget hijo a mostrar
  final Widget child;

  /// Valor del estado de ánimo (de 0.0 a 1.0)
  final double moodValue;

  /// Duración de la transición
  final Duration duration;

  const MoodTransitionAnimation({
    Key? key,
    required this.child,
    required this.moodValue,
    this.duration = const Duration(milliseconds: 500),
  }) : super(key: key);

  @override
  State<MoodTransitionAnimation> createState() =>
      _MoodTransitionAnimationState();
}

class _MoodTransitionAnimationState extends State<MoodTransitionAnimation> {
  @override
  Widget build(BuildContext context) {
    // Colores para la transición del estado de ánimo
    final colors = [
      Colors.red.shade700, // Muy mal
      Colors.orange.shade700, // Mal
      Colors.amber.shade500, // Regular
      Colors.lightGreen.shade600, // Bien
      Colors.green.shade700, // Muy bien
    ];

    // Calcular el índice base y la fracción para la interpolación
    final index = (widget.moodValue * (colors.length - 1)).floor();
    final fraction = (widget.moodValue * (colors.length - 1)) - index;

    // Asegurar que estamos dentro de los límites
    final safeIndex = math.min(index, colors.length - 2);

    // Interpolar entre los dos colores
    final color =
        Color.lerp(colors[safeIndex], colors[safeIndex + 1], fraction)!;

    return AnimatedContainer(
      duration: widget.duration,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withOpacity(0.1),
            Colors.white,
          ],
          stops: const [0.0, 0.3],
        ),
      ),
      child: widget.child,
    );
  }
}

/// Widget para animaciones de actividad física
class ActivityPulseAnimation extends StatefulWidget {
  /// Widget hijo a mostrar
  final Widget child;

  /// Nivel de actividad (0.0 a 1.0)
  final double activityLevel;

  const ActivityPulseAnimation({
    Key? key,
    required this.child,
    required this.activityLevel,
  }) : super(key: key);

  @override
  State<ActivityPulseAnimation> createState() => _ActivityPulseAnimationState();
}

class _ActivityPulseAnimationState extends State<ActivityPulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // La velocidad del pulso depende del nivel de actividad
    final duration =
        Duration(milliseconds: (1000 - widget.activityLevel * 500).round());

    _controller = AnimationController(
      vsync: this,
      duration: duration,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.0 + (widget.activityLevel * 0.08),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,

        // Indicador de pulso
        Positioned(
          top: 16,
          right: 16,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.directions_run,
                    color: Colors.orange.shade700,
                    size: 22,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Widget para microinteracción de "tomar medicamento"
class TakeMedicationAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback onAnimationComplete;
  final Color color;

  const TakeMedicationAnimation({
    Key? key,
    required this.child,
    required this.onAnimationComplete,
    required this.color,
  }) : super(key: key);

  @override
  State<TakeMedicationAnimation> createState() =>
      _TakeMedicationAnimationState();
}

class _TakeMedicationAnimationState extends State<TakeMedicationAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _moveAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.7,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _moveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeInOut),
      ),
    );

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void playAnimation() {
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.translate(
            offset: Offset(0, -100 * _moveAnimation.value),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Widget para animación de trazado de check (para completados)
class CheckmarkDrawAnimation extends StatefulWidget {
  final Color color;
  final double size;
  final Duration duration;
  final VoidCallback? onComplete;

  const CheckmarkDrawAnimation({
    Key? key,
    required this.color,
    this.size = 60.0, // Aumentado para mejor visibilidad
    this.duration = const Duration(milliseconds: 800),
    this.onComplete,
  }) : super(key: key);

  @override
  State<CheckmarkDrawAnimation> createState() => _CheckmarkDrawAnimationState();
}

class _CheckmarkDrawAnimationState extends State<CheckmarkDrawAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.onComplete != null) {
        widget.onComplete!();
      }
    });

    // Iniciar la animación automáticamente
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: widget.color.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return CustomPaint(
              size: Size(widget.size * 0.7,
                  widget.size * 0.7), // Ajustar tamaño del checkmark
              painter: _CheckmarkPainter(
                color: widget.color,
                progress: _animation.value,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Pintor personalizado para dibujar el check mark
class _CheckmarkPainter extends CustomPainter {
  final Color color;
  final double progress;

  _CheckmarkPainter({
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    final path = Path();

    // Reposicionamos los puntos del check mark para centrarlo mejor
    // y asegurar que está dentro del círculo
    final startPoint = Offset(size.width * 0.3, size.height * 0.55);
    final midPoint = Offset(size.width * 0.45, size.height * 0.7);
    final endPoint = Offset(size.width * 0.7, size.height * 0.4);

    // Calcular la longitud total del trazo
    final totalLength =
        (midPoint - startPoint).distance + (endPoint - midPoint).distance;

    // Calcular cuánto del trazo se ha completado
    final currentLength = totalLength * progress;

    // Dibujar el primer segmento
    final firstSegmentLength = (midPoint - startPoint).distance;
    if (currentLength <= firstSegmentLength) {
      // Solo dibujar parte del primer segmento
      final t = currentLength / firstSegmentLength;
      final firstSegmentEnd = Offset.lerp(startPoint, midPoint, t)!;

      path.moveTo(startPoint.dx, startPoint.dy);
      path.lineTo(firstSegmentEnd.dx, firstSegmentEnd.dy);
    } else {
      // Dibujar todo el primer segmento
      path.moveTo(startPoint.dx, startPoint.dy);
      path.lineTo(midPoint.dx, midPoint.dy);

      // Dibujar parte del segundo segmento
      final secondSegmentProgress =
          (currentLength - firstSegmentLength) / (endPoint - midPoint).distance;
      // Limitar el valor de secondSegmentProgress entre 0.0 y 1.0
      final limitedProgress = secondSegmentProgress.clamp(0.0, 1.0);
      final secondSegmentEnd =
          Offset.lerp(midPoint, endPoint, limitedProgress)!;

      path.lineTo(secondSegmentEnd.dx, secondSegmentEnd.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
