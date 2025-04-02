import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xenify/domain/entities/question.dart';
import 'package:xenify/presentation/providers/questionnaire_provider.dart';
import 'package:xenify/presentation/widgets/question_widget_updated.dart';
import 'package:xenify/presentation/screens/dashboard_screen.dart';
import 'package:xenify/presentation/theme/questionnaire_theme.dart';
import 'package:xenify/presentation/widgets/questionnaire/animations/question_animations.dart';
import 'package:xenify/presentation/widgets/questionnaire/progress_bar_widget.dart';
import 'package:xenify/presentation/widgets/questionnaire/adaptive_questionnaire.dart';

class QuestionnaireScreen extends ConsumerStatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  ConsumerState<QuestionnaireScreen> createState() =>
      _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends ConsumerState<QuestionnaireScreen> {
  // Variables de estado
  QuestionTransitionDirection _lastTransitionDirection =
      QuestionTransitionDirection.fade;
  int _checkmarkCounter = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(questionsProvider);
    final currentQuestionIndex = state.currentQuestionIndex;
    final isLastQuestion = currentQuestionIndex >= questionsList.length - 1;

    // Obtener la categoría actual para personalizar el tema
    final currentQuestion =
        currentQuestionIndex >= 0 && currentQuestionIndex < questionsList.length
            ? questionsList[currentQuestionIndex]
            : null;
    final questionCategory = currentQuestion != null
        ? _getQuestionCategory(currentQuestion)
        : QuestionCategory.general;

    return PopScope(
      canPop: state.currentQuestionIndex == 0,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (state.currentQuestionIndex > 0 && !didPop) {
          _navigateBack();
        }
      },
      child: Scaffold(
        backgroundColor: QuestionnaireTheme.backgroundColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: QuestionnaireTheme.backgroundColor,
          leading: state.currentQuestionIndex > 0
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: QuestionnaireTheme.getCategoryColor(questionCategory),
                  onPressed: _navigateBack,
                )
              : null,
          title: Text(
            'Cuestionario de Salud',
            style: TextStyle(
              color: QuestionnaireTheme.textPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            // Botón de ayuda
            IconButton(
              icon: Icon(
                Icons.help_outline,
                color: QuestionnaireTheme.getCategoryColor(questionCategory)
                    .withOpacity(0.7),
              ),
              onPressed: () {
                _showHelpDialog(context, questionCategory);
              },
            ),
            // Botón de configuración de rendimiento
            IconButton(
              icon: Icon(
                Icons.settings,
                color: QuestionnaireTheme.getCategoryColor(questionCategory)
                    .withOpacity(0.7),
              ),
              onPressed: () {
                _showPerformanceSettingsDialog(context);
              },
            ),
          ],
        ),
        body: state.isCompleted
            ? _buildCompletionScreen(context)
            : _buildQuestionScreen(context, questionCategory),
        // Botones de navegación en la parte inferior
        bottomNavigationBar: !state.isCompleted
            ? _buildNavigationButtons(questionCategory, isLastQuestion)
            : null,
      ),
    );
  }

  // Controlador de animación para las transiciones
  final _animationController = QuestionAnimationController();

  // Pantalla de cuestionario completado
  Widget _buildCompletionScreen(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Center(
      child: SequentialAnimator(
        children: [
          // Icono de finalización con animación de check
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.green[50],
              shape: BoxShape.circle,
            ),
            child: CheckmarkDrawAnimation(
              key: ValueKey(_checkmarkCounter),
              color: Colors.green,
              size: 80,
              duration: const Duration(milliseconds: 800),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '¡Cuestionario completado!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Gracias por completar tu evaluación de salud inicial.\nAhora podremos personalizar tu experiencia.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: QuestionnaireTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 40),
          Container(
            // width: media.width * 0.6,
            margin: EdgeInsets.symmetric(horizontal: media.width * 0.2),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 25),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                if (!mounted) return;

                // Mostrar indicador de carga
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                try {
                  // Intentar completar el cuestionario y guardar las respuestas
                  await ref
                      .read(questionsProvider.notifier)
                      .completeQuestionnaire();

                  if (!mounted) return;

                  // Cerrar el diálogo de carga
                  Navigator.pop(context);

                  // Navegar al dashboard
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const DashboardScreen(),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;

                  // Cerrar el diálogo de carga
                  Navigator.pop(context);

                  // Mostrar error al usuario
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Error al guardar las respuestas: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              },
              child: const Text('Finalizar'),
            ),
          ),
        ],
      ),
    );
  }

  // Pantalla del cuestionario en curso
  Widget _buildQuestionScreen(BuildContext context, QuestionCategory category) {
    // Envolver el widget de la pregunta en animaciones
    return AnimatedQuestionCard(
      direction: _lastTransitionDirection,
      animationController: _animationController,
      child: const QuestionWidgetUpdated().makeAdaptive(category),
    );
  }

  // Construir los botones de navegación inferiores
  Widget _buildNavigationButtons(
      QuestionCategory category, bool isLastQuestion) {
    final state = ref.watch(questionsProvider);
    final color = QuestionnaireTheme.getCategoryColor(category);
    final adjustedIndex =
        state.currentQuestionIndex < 0 ? 0 : state.currentQuestionIndex;
    final currentQuestion = adjustedIndex < questionsList.length
        ? questionsList[adjustedIndex]
        : questionsList[0]; // Usar la primera pregunta como fallback
    final hasResponse = state.answers.containsKey(currentQuestion.id);

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
          // Botón de regreso
          state.currentQuestionIndex > 0
              ? OutlinedButton.icon(
                  onPressed: _navigateBack,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Anterior'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    side: BorderSide(color: color),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
              : const SizedBox(
                  width: 100), // Espaciador si estamos en la primera pregunta

          // Botón de continuar
          ElevatedButton.icon(
            onPressed: hasResponse ? () => _navigateForward() : null,
            icon: Icon(isLastQuestion ? Icons.check : Icons.arrow_forward),
            label: Text(isLastQuestion ? 'Finalizar' : 'Siguiente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              disabledForegroundColor: Colors.grey[500],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Navegar a la pregunta anterior con animación
  void _navigateBack() {
    setState(() {
      _lastTransitionDirection = QuestionTransitionDirection.right;
    });
    ref.read(questionsProvider.notifier).goBack();
  }

  // Navegar a la siguiente pregunta con animación
  void _navigateForward({bool skipQuestion = false}) {
    final state = ref.watch(questionsProvider);
    final currentIndex =
        state.currentQuestionIndex < 0 ? 0 : state.currentQuestionIndex;

    if (currentIndex >= questionsList.length) {
      return; // Evitar navegar si estamos fuera de rango
    }

    final currentQuestion = questionsList[currentIndex];

    setState(() {
      _lastTransitionDirection = QuestionTransitionDirection.left;
    });

    if (skipQuestion) {
      // Como no existe un método skipQuestion, vamos a enviar una respuesta null/vacía
      // o usar un valor por defecto según el tipo de pregunta
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
      // Si ya hay una respuesta, avanzamos a la siguiente pregunta
      final answer = state.answers[currentQuestion.id];
      ref
          .read(questionsProvider.notifier)
          .answerQuestion(currentQuestion.id, answer);
    }
  }

  // Mostrar diálogo de ayuda contextualizada
  void _showHelpDialog(BuildContext context, QuestionCategory category) {
    final color = QuestionnaireTheme.getCategoryColor(category);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(category.icon, color: color),
            const SizedBox(width: 8),
            Text(
              'Ayuda con la pregunta',
              style: TextStyle(
                color: QuestionnaireTheme.textPrimaryColor,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: const Text(
          'Esta pregunta nos ayuda a personalizar tu experiencia en la aplicación. '
          'Todas tus respuestas son confidenciales y sólo se utilizarán para mejorar '
          'las recomendaciones que te ofrecemos.',
          style: TextStyle(
            color: QuestionnaireTheme.textSecondaryColor,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Entendido',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // Mostrar diálogo de configuración de rendimiento
  void _showPerformanceSettingsDialog(BuildContext context) {
    final state = ref.read(questionsProvider);
    final animationsEnabled = ref.read(animationsEnabledProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuración de rendimiento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Modo de bajo rendimiento'),
              subtitle: const Text(
                  'Reduce el uso de recursos para dispositivos más lentos'),
              value: state.isLowPerformanceMode,
              onChanged: (value) {
                ref
                    .read(questionsProvider.notifier)
                    .setLowPerformanceMode(value);
                Navigator.of(context).pop();
              },
            ),
            SwitchListTile(
              title: const Text('Animaciones'),
              subtitle: const Text('Habilitar o deshabilitar animaciones'),
              value: animationsEnabled,
              onChanged: (value) {
                ref.read(animationsEnabledProvider.notifier).state = value;
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // Determinar la categoría según el tipo de pregunta
  QuestionCategory _getQuestionCategory(Question question) {
    if (question.id.contains('pathology') ||
        question.id.contains('digestive') ||
        question.id.contains('cardiovascular')) {
      return QuestionCategory.general;
    } else if (question.id.contains('diet') ||
        question.id.contains('nutrition') ||
        question.id.contains('eat') ||
        question.id.contains('food') ||
        question.id.contains('protein') ||
        question.id.contains('meal')) {
      return QuestionCategory.nutrition;
    } else if (question.id.contains('sleep') ||
        question.id.contains('bed') ||
        question.id.contains('wake')) {
      return QuestionCategory.sleep;
    } else if (question.id.contains('activity') ||
        question.id.contains('exercise')) {
      return QuestionCategory.activity;
    } else if (question.id.contains('medication') ||
        question.id.contains('treatment')) {
      return QuestionCategory.medication;
    } else if (question.id.contains('mood') ||
        question.id.contains('feeling')) {
      return QuestionCategory.mood;
    } else if (question.id.contains('bathroom') ||
        question.id.contains('water_intake')) {
      return QuestionCategory.digestive;
    }

    // Categoría por defecto
    return QuestionCategory.general;
  }
}

// Animación de checkmark para la pantalla de finalización
class CheckmarkDrawAnimation extends StatefulWidget {
  final Color color;
  final double size;
  final Duration duration;
  final VoidCallback? onComplete;

  const CheckmarkDrawAnimation({
    Key? key,
    required this.color,
    this.size = 32.0,
    this.duration = const Duration(milliseconds: 600),
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
        curve: Curves.easeInOutCubic, // Curva más suave para la animación
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _CheckmarkPainter(
            color: widget.color,
            progress: _animation.value,
          ),
        );
      },
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
    // Configurar el trazo para el check
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0 // Volver al grosor original
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    // Puntos del check mark ajustados para quedar dentro del círculo
    final startPoint = Offset(size.width * 0.45, size.height * 0.50);
    final midPoint = Offset(size.width * 0.48, size.height * 0.65);
    final endPoint = Offset(size.width * 0.55, size.height * 0.30);

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
      final secondSegmentEnd =
          Offset.lerp(midPoint, endPoint, secondSegmentProgress)!;

      path.lineTo(secondSegmentEnd.dx, secondSegmentEnd.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
