import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xenify/domain/entities/question.dart';
import 'package:xenify/presentation/providers/questionnaire_provider.dart';
import 'package:xenify/presentation/theme/questionnaire_theme.dart';
import 'package:xenify/presentation/widgets/questionnaire/animations/question_animations.dart';

/// Dirección de navegación
enum NavigationDirection {
  forward,
  backward,
}

/// Callback para eventos de navegación
typedef NavigationCallback = void Function(NavigationDirection direction,
    {bool skipQuestion});

/// Widget para gestionar la navegación entre preguntas del cuestionario
class QuestionnaireNavigation extends ConsumerStatefulWidget {
  /// Callback a ejecutar cuando se navega entre preguntas
  final NavigationCallback onNavigate;

  /// Categoría de la pregunta actual (para establecer el color)
  final QuestionCategory category;

  /// Estado actual del cuestionario
  final QuestionType questionType;

  /// Índice de la pregunta actual
  final int currentIndex;

  /// Cantidad total de preguntas
  final int totalQuestions;

  /// Indica si la pregunta tiene respuesta
  final bool hasResponse;

  /// Indica si los gestos de deslizamiento están habilitados
  final bool enableSwipeGestures;

  /// Widget hijo (contenido del cuestionario)
  final Widget child;

  const QuestionnaireNavigation({
    Key? key,
    required this.onNavigate,
    required this.category,
    required this.questionType,
    required this.currentIndex,
    required this.totalQuestions,
    required this.hasResponse,
    required this.child,
    this.enableSwipeGestures = true,
  }) : super(key: key);

  @override
  ConsumerState<QuestionnaireNavigation> createState() =>
      _QuestionnaireNavigationState();
}

class _QuestionnaireNavigationState
    extends ConsumerState<QuestionnaireNavigation> {
  // Controlador para las animaciones de PageView
  final PageController _pageController = PageController(initialPage: 1);

  // Página actual (0: anterior, 1: actual, 2: siguiente)
  int _currentPageIndex = 1;

  // Indica si hay un deslizamiento en curso
  bool _isNavigating = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFirstQuestion = widget.currentIndex == 0;
    final isLastQuestion = widget.currentIndex >= widget.totalQuestions - 1;
    final categoryColor = QuestionnaireTheme.getCategoryColor(widget.category);

    // Si no se permiten gestos o es una pregunta especial, devolver solo el hijo
    if (!widget.enableSwipeGestures ||
        widget.questionType == QuestionType.medication ||
        widget.questionType == QuestionType.familyHistory) {
      return Column(
        children: [
          Expanded(child: widget.child),
          if (_shouldShowNavigationButtons())
            _buildNavigationButtons(
                isFirstQuestion, isLastQuestion, categoryColor),
        ],
      );
    }

    // Con gestos de deslizamiento habilitados
    return Column(
      children: [
        // Contenido del cuestionario con soporte para deslizamiento
        Expanded(
          child: GestureDetector(
            // Detectar deslizamientos horizontales
            onHorizontalDragEnd: (details) {
              if (_isNavigating) return;

              // Velocidad mínima para considerar un deslizamiento válido
              final minVelocity = 200.0;

              // Deslizamiento hacia la izquierda (siguiente)
              if (details.primaryVelocity != null &&
                  details.primaryVelocity! < -minVelocity &&
                  !isLastQuestion &&
                  widget.hasResponse) {
                _handleNavigation(NavigationDirection.forward);
              }

              // Deslizamiento hacia la derecha (anterior)
              else if (details.primaryVelocity != null &&
                  details.primaryVelocity! > minVelocity &&
                  !isFirstQuestion) {
                _handleNavigation(NavigationDirection.backward);
              }
            },
            child: widget.child,
          ),
        ),

        // Botones de navegación
        if (_shouldShowNavigationButtons())
          _buildNavigationButtons(
              isFirstQuestion, isLastQuestion, categoryColor),
      ],
    );
  }

  /// Determina si se deben mostrar los botones de navegación
  bool _shouldShowNavigationButtons() {
    // No mostrar botones en tipos de pregunta específicos que ya tienen su propia navegación
    return widget.questionType != QuestionType.familyHistory &&
        widget.questionType != QuestionType.medication;
  }

  /// Construye los botones de navegación inferior
  Widget _buildNavigationButtons(
      bool isFirstQuestion, bool isLastQuestion, Color categoryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botón de retroceso (solo visible si no es la primera pregunta)
          if (!isFirstQuestion)
            OutlinedButton.icon(
              onPressed: () => _handleNavigation(NavigationDirection.backward),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Anterior'),
              style: OutlinedButton.styleFrom(
                foregroundColor: categoryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                side: BorderSide(color: categoryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )
          else
            const SizedBox(
                width: 48), // Espaciador si estamos en la primera pregunta

          // Indicadores de progreso
          _buildProgressIndicators(categoryColor),

          // Botón de siguiente/finalizar
          ElevatedButton.icon(
            onPressed: widget.hasResponse
                ? () => _handleNavigation(NavigationDirection.forward)
                : null,
            icon: Icon(isLastQuestion ? Icons.check : Icons.arrow_forward),
            label: Text(isLastQuestion ? 'Finalizar' : 'Continuar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: categoryColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              disabledForegroundColor: Colors.grey[500],
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye los indicadores de progreso (puntos)
  Widget _buildProgressIndicators(Color categoryColor) {
    return Row(
      children: [
        // Botón de saltar pregunta
        TextButton(
          onPressed: () => _handleNavigation(
            NavigationDirection.forward,
            skipQuestion: true,
          ),
          child: Text(
            'Saltar',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  /// Manejador de eventos de navegación
  void _handleNavigation(NavigationDirection direction,
      {bool skipQuestion = false}) {
    // Evitar navegaciones múltiples simultáneas
    if (_isNavigating) return;

    setState(() {
      _isNavigating = true;
    });

    // Ejecutar callback de navegación
    widget.onNavigate(direction, skipQuestion: skipQuestion);

    // Resetear el flag de navegación después de un breve retraso
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    });
  }
}

/// Gestor de navegación completa del cuestionario
class QuestionnaireNavigationManager extends ConsumerStatefulWidget {
  /// Widget hijo que contiene el contenido del cuestionario
  final Widget child;

  /// Categoría de la pregunta actual
  final QuestionCategory category;

  /// Tipo de la pregunta actual
  final QuestionType questionType;

  /// Indica si los gestos de deslizamiento están habilitados
  final bool enableSwipeGestures;

  /// Callback a ejecutar cuando se completa el cuestionario
  final VoidCallback? onQuestionnaireCompleted;

  /// Indica si las animaciones están habilitadas
  final bool enableAnimations;

  const QuestionnaireNavigationManager({
    Key? key,
    required this.child,
    required this.category,
    required this.questionType,
    this.enableSwipeGestures = true,
    this.onQuestionnaireCompleted,
    this.enableAnimations = true, // Nuevo parámetro
  }) : super(key: key);

  @override
  ConsumerState<QuestionnaireNavigationManager> createState() =>
      _QuestionnaireNavigationManagerState();
}

class _QuestionnaireNavigationManagerState
    extends ConsumerState<QuestionnaireNavigationManager> {
  // Dirección de la última transición
  QuestionTransitionDirection _lastTransitionDirection =
      QuestionTransitionDirection.fade;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(questionsProvider);
    final currentQuestionIndex = state.currentQuestionIndex;
    final isLastQuestion = currentQuestionIndex >= questionsList.length - 1;

    // Si el cuestionario está completado, solo devolver el hijo (sin navegación)
    if (state.isCompleted) {
      return widget.child;
    }

    final currentQuestion = currentQuestionIndex < questionsList.length
        ? questionsList[currentQuestionIndex]
        : null;

    // Comprobar si hay respuesta para la pregunta actual
    final hasResponse = currentQuestion != null &&
        state.answers.containsKey(currentQuestion.id);

    return QuestionnaireNavigation(
      category: widget.category,
      questionType: widget.questionType,
      currentIndex: currentQuestionIndex,
      totalQuestions: questionsList.length,
      hasResponse: hasResponse,
      enableSwipeGestures: widget.enableSwipeGestures,
      onNavigate: (direction, {bool skipQuestion = false}) {
        _handleNavigation(direction, skipQuestion: skipQuestion);
      },
      child: ref.watch(animationsEnabledProvider) && widget.enableAnimations
          ? AnimatedQuestionCard(
              direction: _lastTransitionDirection,
              child: widget.child,
            )
          : widget.child,
    );
  }

  /// Manejar la navegación entre preguntas
  void _handleNavigation(NavigationDirection direction,
      {bool skipQuestion = false}) {
    final state = ref.read(questionsProvider);
    final currentQuestionIndex = state.currentQuestionIndex;
    final currentQuestion = questionsList[currentQuestionIndex];

    // Determinar la dirección de la transición según la navegación
    setState(() {
      _lastTransitionDirection = direction == NavigationDirection.forward
          ? QuestionTransitionDirection.left
          : QuestionTransitionDirection.right;
    });

    if (direction == NavigationDirection.forward) {
      if (skipQuestion) {
        // Para saltar preguntas, proporcionar respuesta predeterminada
        dynamic defaultAnswer;
        switch (currentQuestion.type) {
          case QuestionType.multiSelect:
            defaultAnswer = <String>[];
            break;
          case QuestionType.yesNo:
            defaultAnswer = false;
            break;
          default:
            defaultAnswer = null;
        }

        ref
            .read(questionsProvider.notifier)
            .answerQuestion(currentQuestion.id, defaultAnswer);
      } else {
        // Avanzar con la respuesta existente
        final answer = state.answers[currentQuestion.id];
        ref
            .read(questionsProvider.notifier)
            .answerQuestion(currentQuestion.id, answer);
      }

      // Comprobar si hemos completado el cuestionario
      Future.delayed(const Duration(milliseconds: 300), () {
        if (currentQuestionIndex >= questionsList.length - 1 &&
            widget.onQuestionnaireCompleted != null) {
          widget.onQuestionnaireCompleted!();
        }
      });
    } else {
      // Retroceder a la pregunta anterior
      ref.read(questionsProvider.notifier).goBack();
    }
  }
}

/// Widget para mostrar un indicador de ayuda de gesto de deslizamiento
class SwipeGestureHint extends StatefulWidget {
  /// Color del indicador
  final Color color;

  /// Duración de la animación
  final Duration duration;

  /// Dirección del gesto (true: izquierda->derecha, false: derecha->izquierda)
  final bool isRightToLeft;

  const SwipeGestureHint({
    Key? key,
    required this.color,
    this.duration = const Duration(seconds: 1),
    this.isRightToLeft = true,
  }) : super(key: key);

  @override
  State<SwipeGestureHint> createState() => _SwipeGestureHintState();
}

class _SwipeGestureHintState extends State<SwipeGestureHint>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Definir la animación de deslizamiento (derecha a izquierda o izquierda a derecha)
    final begin =
        widget.isRightToLeft ? const Offset(0.3, 0) : const Offset(-0.3, 0);
    final end =
        widget.isRightToLeft ? const Offset(-0.3, 0) : const Offset(0.3, 0);

    _slideAnimation = Tween<Offset>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Iniciar la animación con repetición
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!widget.isRightToLeft)
              Icon(Icons.arrow_back, color: widget.color),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                widget.isRightToLeft
                    ? 'Deslizar para continuar'
                    : 'Deslizar para regresar',
                style: TextStyle(
                  color: widget.color,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (widget.isRightToLeft)
              Icon(Icons.arrow_forward, color: widget.color),
          ],
        ),
      ),
    );
  }
}
