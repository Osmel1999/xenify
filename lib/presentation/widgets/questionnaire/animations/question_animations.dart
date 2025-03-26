import 'package:flutter/material.dart';
import 'package:xenify/presentation/theme/questionnaire_theme.dart';

/// Dirección de la transición entre preguntas
enum QuestionTransitionDirection {
  left, // Deslizamiento hacia la izquierda (avanzar)
  right, // Deslizamiento hacia la derecha (retroceder)
  up, // Deslizamiento hacia arriba
  down, // Deslizamiento hacia abajo
  fade, // Desvanecer sin dirección
  scale, // Escalar (zoom in/out)
}

/// Controlador de animaciones para el cuestionario
class QuestionAnimationController {
  /// Duración de las transiciones entre preguntas
  final Duration transitionDuration;

  /// Duración de las animaciones de despliegue
  final Duration deployDuration;

  /// Curva de aceleración para transiciones
  final Curve transitionCurve;

  /// Curva de aceleración para despliegue
  final Curve deployCurve;

  const QuestionAnimationController({
    this.transitionDuration = const Duration(milliseconds: 350),
    this.deployDuration = const Duration(milliseconds: 350),
    this.transitionCurve = Curves.easeInOut,
    this.deployCurve = Curves.easeOutBack,
  });

  /// Crea un controlador con las configuraciones por defecto del tema
  factory QuestionAnimationController.fromTheme() {
    return QuestionAnimationController(
      transitionDuration: QuestionnaireTheme.transitionDuration,
    );
  }

  /// Obtiene la ruta para la transición entre preguntas
  PageRouteBuilder<void> getQuestionRoute(
      {required Widget child, required QuestionTransitionDirection direction}) {
    return PageRouteBuilder<void>(
      transitionDuration: transitionDuration,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return _buildTransition(child, direction, animation);
      },
    );
  }

  /// Construye las transiciones específicas para cada dirección
  Widget _buildTransition(Widget child, QuestionTransitionDirection direction,
      Animation<double> animation) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: transitionCurve,
    );

    switch (direction) {
      case QuestionTransitionDirection.left:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case QuestionTransitionDirection.right:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case QuestionTransitionDirection.up:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case QuestionTransitionDirection.down:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, -1.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case QuestionTransitionDirection.fade:
        return FadeTransition(
          opacity: curvedAnimation,
          child: child,
        );

      case QuestionTransitionDirection.scale:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.95,
            end: 1.0,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: child,
          ),
        );
    }
  }
}

/// Animador para elementos dentro de la pregunta
class QuestionElementAnimator extends StatefulWidget {
  /// Widget hijo a animar
  final Widget child;

  /// Índice para calcular el retraso de la animación
  final int index;

  /// Duración de la animación
  final Duration duration;

  /// Retraso base entre elementos
  final Duration delay;

  /// Curva de aceleración
  final Curve curve;

  /// Tipo de animación a aplicar
  final QuestionElementAnimationType animationType;

  /// Establece si la animación debe ejecutarse al crearse
  final bool animateOnInit;

  const QuestionElementAnimator({
    Key? key,
    required this.child,
    this.index = 0,
    this.duration = const Duration(milliseconds: 350),
    this.delay = const Duration(milliseconds: 100),
    this.curve = Curves.easeOutBack,
    this.animationType = QuestionElementAnimationType.fadeSlideIn,
    this.animateOnInit = true,
  }) : super(key: key);

  @override
  State<QuestionElementAnimator> createState() =>
      _QuestionElementAnimatorState();
}

class _QuestionElementAnimatorState extends State<QuestionElementAnimator>
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

    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    if (widget.animateOnInit) {
      // Añadir retraso según el índice para efecto cascada
      Future.delayed(widget.delay * widget.index, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildAnimatedWidget();
  }

  /// Construye el widget animado según el tipo de animación seleccionado
  Widget _buildAnimatedWidget() {
    switch (widget.animationType) {
      case QuestionElementAnimationType.fadeSlideIn:
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - _animation.value)),
              child: Opacity(
                opacity: _animation.value.clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
          child: widget.child,
        );

      case QuestionElementAnimationType.fadeIn:
        return FadeTransition(
          opacity: _animation,
          child: widget.child,
        );

      case QuestionElementAnimationType.scaleIn:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.95,
            end: 1.0,
          ).animate(_animation),
          child: FadeTransition(
            opacity: _animation,
            child: widget.child,
          ),
        );

      case QuestionElementAnimationType.slideInLeft:
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(50 * (1 - _animation.value), 0),
              child: Opacity(
                opacity: _animation.value,
                child: child,
              ),
            );
          },
          child: widget.child,
        );

      case QuestionElementAnimationType.slideInRight:
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(-50 * (1 - _animation.value), 0),
              child: Opacity(
                opacity: _animation.value,
                child: child,
              ),
            );
          },
          child: widget.child,
        );

      case QuestionElementAnimationType.none:
        return widget.child;
    }
  }

  /// Reproduce la animación manualmente
  void play() {
    _controller.forward(from: 0.0);
  }

  /// Invierte la animación
  void reverse() {
    _controller.reverse();
  }
}

/// Tipos de animaciones para elementos dentro de las preguntas
enum QuestionElementAnimationType {
  fadeSlideIn, // Desvanecimiento con deslizamiento hacia arriba
  fadeIn, // Solo desvanecimiento
  scaleIn, // Escala con desvanecimiento
  slideInLeft, // Deslizamiento desde la izquierda
  slideInRight, // Deslizamiento desde la derecha
  none, // Sin animación
}

/// Widget para animar la entrada y salida de una pregunta completa
class AnimatedQuestionCard extends StatefulWidget {
  /// Widget hijo (tarjeta de pregunta)
  final Widget child;

  /// Controlador de animación
  final QuestionAnimationController animationController;

  /// Dirección de la animación
  final QuestionTransitionDirection direction;

  /// Indica si la pregunta está activa actualmente
  final bool isActive;

  /// Callback cuando la animación de salida completa
  final VoidCallback? onExitComplete;

  const AnimatedQuestionCard({
    Key? key,
    required this.child,
    this.animationController = const QuestionAnimationController(),
    this.direction = QuestionTransitionDirection.left,
    this.isActive = true,
    this.onExitComplete,
  }) : super(key: key);

  @override
  State<AnimatedQuestionCard> createState() => _AnimatedQuestionCardState();
}

class _AnimatedQuestionCardState extends State<AnimatedQuestionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationController.transitionDuration,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.animationController.transitionCurve,
    );

    if (widget.isActive) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedQuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isActive && !widget.isActive && !_isExiting) {
      _isExiting = true;
      _controller.reverse().then((_) {
        if (widget.onExitComplete != null) {
          widget.onExitComplete!();
        }
      });
    } else if (!oldWidget.isActive && widget.isActive) {
      _isExiting = false;
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return _buildAnimatedTransition(child!);
      },
      child: widget.child,
    );
  }

  /// Construye la transición animada según la dirección
  Widget _buildAnimatedTransition(Widget child) {
    switch (widget.direction) {
      case QuestionTransitionDirection.left:
      case QuestionTransitionDirection.right:
        final double offsetX =
            widget.direction == QuestionTransitionDirection.left ? 1.0 : -1.0;
        return Transform.translate(
          offset: Offset(offsetX * (1 - _animation.value) * 100, 0),
          child: Opacity(
            opacity: _animation.value,
            child: child,
          ),
        );

      case QuestionTransitionDirection.up:
      case QuestionTransitionDirection.down:
        final double offsetY =
            widget.direction == QuestionTransitionDirection.up ? 1.0 : -1.0;
        return Transform.translate(
          offset: Offset(0, offsetY * (1 - _animation.value) * 100),
          child: Opacity(
            opacity: _animation.value,
            child: child,
          ),
        );

      case QuestionTransitionDirection.fade:
        return Opacity(
          opacity: _animation.value,
          child: child,
        );

      case QuestionTransitionDirection.scale:
        return Transform.scale(
          scale: 0.95 + (0.05 * _animation.value),
          child: Opacity(
            opacity: _animation.value,
            child: child,
          ),
        );
    }
  }
}

/// Widget para animar secuencialmente un conjunto de elementos
class SequentialAnimator extends StatelessWidget {
  /// Lista de widgets a animar
  final List<Widget> children;

  /// Tipo de animación a aplicar
  final QuestionElementAnimationType animationType;

  /// Duración de cada animación
  final Duration duration;

  /// Retraso entre animaciones
  final Duration delay;

  /// Curva de animación
  final Curve curve;

  /// Padding entre elementos
  final EdgeInsetsGeometry padding;

  const SequentialAnimator({
    Key? key,
    required this.children,
    this.animationType = QuestionElementAnimationType.fadeSlideIn,
    this.duration = const Duration(milliseconds: 350),
    this.delay = const Duration(milliseconds: 100),
    this.curve = Curves.easeOutBack,
    this.padding = const EdgeInsets.symmetric(vertical: 8.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(children.length, (index) {
          return Padding(
            padding: padding,
            child: QuestionElementAnimator(
              index: index,
              duration: duration,
              delay: delay,
              curve: curve,
              animationType: animationType,
              child: children[index],
            ),
          );
        }),
      ),
    );
  }
}

/// Gestor de microinteracciones para elementos interactivos en el cuestionario
class QuestionMicrointeractions {
  /// Feedback táctil (vibración) para selecciones
  static Future<void> selectionFeedback() async {
    // La implementación depende de los paquetes disponibles
    // Para un implementación completa, considera usar:
    // - flutter_haptic_feedback
    // - vibration
    // Aquí, usamos una implementación básica
    // await HapticFeedback.lightImpact();
  }

  /// Animaciones de botón para eventos de presión
  static Widget buildPressableAnimatedContainer({
    required Widget child,
    required VoidCallback onPressed,
    required BoxDecoration decoration,
    Duration duration = const Duration(milliseconds: 150),
    double pressedScale = 0.98,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isPressed = false;

        return GestureDetector(
          onTapDown: (_) {
            setState(() => isPressed = true);
            selectionFeedback();
          },
          onTapUp: (_) {
            setState(() => isPressed = false);
          },
          onTapCancel: () {
            setState(() => isPressed = false);
          },
          onTap: onPressed,
          child: AnimatedScale(
            scale: isPressed ? pressedScale : 1.0,
            duration: duration,
            child: AnimatedContainer(
              duration: duration,
              decoration: decoration,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
