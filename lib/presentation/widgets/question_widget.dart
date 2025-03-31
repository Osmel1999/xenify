import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:xenify/domain/entities/question.dart';
import 'package:xenify/domain/entities/medication.dart';
import 'package:xenify/domain/entities/family_condition.dart';
import 'package:xenify/domain/entities/location_data.dart';
import 'package:xenify/presentation/providers/questionnaire_provider.dart';
import 'package:xenify/presentation/theme/questionnaire_theme.dart';
import 'package:xenify/presentation/widgets/medication_form.dart';
import 'package:xenify/presentation/widgets/family_history_form.dart';

// Constantes para accesibilidad
const double _minTouchTargetSize =
    44.0; // Tamaño mínimo para objetivos táctiles según WCAG
const double _minFontSize = 14.0; // Tamaño mínimo de fuente para legibilidad
const double _minSpacing = 8.0; // Espaciado mínimo entre elementos interactivos

/// Asegura que el color tenga suficiente contraste para accesibilidad
Color _ensureAccessibleColor(Color color) {
  final luminance =
      (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
  if (luminance > 0.6) {
    final darkerColor = HSLColor.fromColor(color)
        .withLightness(
            (HSLColor.fromColor(color).lightness - 0.2).clamp(0.0, 1.0))
        .toColor();
    return darkerColor;
  }
  return color;
}

/// Determina el color de texto adecuado (blanco/negro) basado en contraste
Color _getAccessibleTextColor(Color backgroundColor) {
  final luminance = backgroundColor.computeLuminance();
  return luminance > 0.5 ? Colors.black : Colors.white;
}

/// Determina la categoría de la pregunta para aplicar colores temáticos
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
  } else if (question.id.contains('mood') || question.id.contains('feeling')) {
    return QuestionCategory.mood;
  } else if (question.id.contains('bathroom') ||
      question.id.contains('water_intake')) {
    return QuestionCategory.digestive;
  }
  return QuestionCategory.general;
}

/// Genera etiquetas de accesibilidad descriptivas para lectores de pantalla
String _generateAccessibilityLabel(Question question,
    {bool isSelected = false}) {
  String baseLabel = question.text;

  // Añadir contexto adicional según el tipo de pregunta
  switch (question.type) {
    case QuestionType.yesNo:
      return '$baseLabel. Seleccione Sí o No.';
    case QuestionType.select:
    case QuestionType.multiSelect:
      return '$baseLabel. ${question.type == QuestionType.multiSelect ? 'Puede seleccionar múltiples opciones.' : 'Seleccione una opción.'}';
    case QuestionType.date:
      return '$baseLabel. Seleccione una fecha.';
    case QuestionType.time:
      return '$baseLabel. Seleccione una hora.';
    default:
      return baseLabel;
  }
}

class QuestionWidget extends ConsumerWidget {
  const QuestionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(questionsProvider);
    final currentQuestion = questionsList[state.currentQuestionIndex];
    final viewInsets = MediaQuery.of(context).viewInsets;
    final isKeyboardVisible = viewInsets.bottom > 0;

    final questionCategory = _getQuestionCategory(currentQuestion);
    final categoryColor = QuestionnaireTheme.getCategoryColor(questionCategory);
    final semanticLabel =
        'Pregunta ${state.currentQuestionIndex + 1} de ${questionsList.length}';

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 32,
                maxHeight: double.infinity,
              ),
              child: Semantics(
                label: semanticLabel,
                hint: 'Responda la pregunta para continuar',
                container: true,
                child: Column(
                  mainAxisAlignment: isKeyboardVisible
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ExcludeSemantics(
                      excluding: false,
                      child: Text(
                        currentQuestion.text,
                        style: const TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                        semanticsLabel:
                            _generateAccessibilityLabel(currentQuestion),
                      ),
                    ),
                    SizedBox(height: isKeyboardVisible ? 16 : 32),
                    _buildInputField(
                        context, currentQuestion, ref, categoryColor),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputField(
      BuildContext context, Question question, WidgetRef ref, Color color) {
    final accessibleColor = _ensureAccessibleColor(color);
    final textColor = _getAccessibleTextColor(accessibleColor);

    switch (question.type) {
      case QuestionType.yesNo:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: _minTouchTargetSize,
              child: ElevatedButton(
                onPressed: () => _submitAnswer(ref, question.id, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accessibleColor,
                  foregroundColor: textColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Semantics(
                  button: true,
                  label: 'Responder Sí a: ${question.text}',
                  enabled: true,
                  onTapHint: 'Seleccionar Sí',
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Sí',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: _minTouchTargetSize,
              child: OutlinedButton(
                onPressed: () => _submitAnswer(ref, question.id, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accessibleColor,
                  side: BorderSide(color: accessibleColor, width: 2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Semantics(
                  button: true,
                  label: 'Responder No a: ${question.text}',
                  enabled: true,
                  onTapHint: 'Seleccionar No',
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cancel_outlined, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'No',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );

      case QuestionType.select:
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: question.options!.length,
          itemBuilder: (context, index) {
            final option = question.options![index];
            return Padding(
              padding: const EdgeInsets.only(bottom: _minSpacing),
              child: Semantics(
                button: true,
                label: 'Opción: $option',
                enabled: true,
                onTapHint: 'Seleccionar esta opción',
                child: InkWell(
                  onTap: () => _submitAnswer(ref, question.id, option),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: _minTouchTargetSize,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: accessibleColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: accessibleColor.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            option,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: accessibleColor,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );

      case QuestionType.multiSelect:
        return _buildMultiSelectInput(question, ref, accessibleColor);

      case QuestionType.text:
        return FormBuilder(
          child: Column(
            children: [
              Semantics(
                label: 'Campo de entrada para ${question.text}',
                hint: question.hint ?? 'Introduzca su respuesta',
                textField: true,
                child: FormBuilderTextField(
                  name: question.id,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: _minFontSize),
                  decoration: InputDecoration(
                    hintText: question.hint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: (value) =>
                      _submitAnswer(ref, question.id, value),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: _minTouchTargetSize,
                child: ElevatedButton(
                  onPressed: () => _submitAnswer(ref, question.id, ''),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accessibleColor,
                    foregroundColor: textColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Continuar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

      case QuestionType.number:
        return FormBuilder(
          child: Column(
            children: [
              Semantics(
                label: 'Campo de entrada para ${question.text}',
                hint: question.hint ?? 'Introduzca su respuesta',
                textField: true,
                child: FormBuilderTextField(
                  name: question.id,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: _minFontSize),
                  decoration: InputDecoration(
                    hintText: question.hint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: (value) =>
                      _submitAnswer(ref, question.id, value),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: _minTouchTargetSize,
                child: ElevatedButton(
                  onPressed: () => _submitAnswer(ref, question.id, null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accessibleColor,
                    foregroundColor: textColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Continuar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

      case QuestionType.date:
        return Column(
          children: [
            Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                      primary: accessibleColor,
                    ),
              ),
              child: Semantics(
                label: 'Selector de fecha para ${question.text}',
                hint: 'Toque para abrir el selector',
                child: FormBuilderDateTimePicker(
                  name: question.id,
                  inputType: InputType.date,
                  format: DateFormat('dd/MM/yyyy'),
                  decoration: InputDecoration(
                    labelText: 'Seleccione una fecha',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) => _submitAnswer(ref, question.id, value),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: _minTouchTargetSize,
              child: ElevatedButton(
                onPressed: () => _submitAnswer(ref, question.id, null),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accessibleColor,
                  foregroundColor: textColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Continuar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );

      case QuestionType.time:
        return Column(
          children: [
            Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                      primary: accessibleColor,
                    ),
              ),
              child: Semantics(
                label: 'Selector de hora para ${question.text}',
                hint: 'Toque para abrir el selector',
                child: FormBuilderDateTimePicker(
                  name: question.id,
                  inputType: InputType.time,
                  format: DateFormat('HH:mm'),
                  decoration: InputDecoration(
                    labelText: 'Seleccione una hora',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (DateTime? value) {
                    if (value != null) {
                      // Enviar el DateTime tal cual, será normalizado en el notifier
                      _submitAnswer(ref, question.id, value);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: _minTouchTargetSize,
              child: ElevatedButton(
                onPressed: () => _submitAnswer(ref, question.id, null),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accessibleColor,
                  foregroundColor: textColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Continuar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );

      case QuestionType.location:
        return _buildLocationInput(question, ref, accessibleColor);

      case QuestionType.dietaryOptions:
        return _buildDietaryOptionsInput(question, ref, accessibleColor);

      case QuestionType.medication:
        return _buildMedicationInput(question, ref, accessibleColor);

      case QuestionType.familyHistory:
        return _buildFamilyHistoryInput(question, ref, accessibleColor);

      default:
        return const Text('Tipo de pregunta no soportado');
    }
  }

  void _submitAnswer(WidgetRef ref, String questionId, dynamic answer) {
    ref.read(questionsProvider.notifier).answerQuestion(questionId, answer);
  }

  Future<LocationData?> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return LocationData(
          country: place.country ?? 'Desconocido',
          city: place.locality ?? place.subAdministrativeArea ?? 'Desconocido',
          neighborhood: place.subLocality,
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }
    } catch (e) {
      print('Error getting location: $e');
    }
    return null;
  }

  Widget _buildMultiSelectInput(Question question, WidgetRef ref, Color color) {
    final List<String> selectedOptions =
        (ref.watch(questionsProvider).answers[question.id] as List<String>?) ??
            [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: question.options!.length,
          itemBuilder: (context, index) {
            final option = question.options![index];
            final isSelected = selectedOptions.contains(option);

            return Padding(
              padding: const EdgeInsets.only(bottom: _minSpacing),
              child: Semantics(
                toggled: isSelected,
                label: 'Opción: $option',
                hint: isSelected ? 'Seleccionado' : 'No seleccionado',
                child: Container(
                  height: _minTouchTargetSize,
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? color : Colors.grey[400]!,
                      width: 1.5,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      List<String> newSelection = List.from(selectedOptions);
                      if (!isSelected) {
                        newSelection.add(option);
                      } else {
                        newSelection.remove(option);
                      }
                      ref
                          .read(questionsProvider.notifier)
                          .updateAnswer(question.id, newSelection);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: isSelected,
                              onChanged: (bool? value) {
                                List<String> newSelection =
                                    List.from(selectedOptions);
                                if (value == true) {
                                  newSelection.add(option);
                                } else {
                                  newSelection.remove(option);
                                }
                                ref
                                    .read(questionsProvider.notifier)
                                    .updateAnswer(question.id, newSelection);
                              },
                              activeColor: color,
                              checkColor: Colors.black,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                                fontWeight: isSelected
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        if (selectedOptions.isNotEmpty || !question.isRequired)
          SizedBox(
            width: double.infinity,
            height: _minTouchTargetSize,
            child: ElevatedButton(
              onPressed: () => _submitAnswer(ref, question.id, selectedOptions),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Continuar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMedicationInput(Question question, WidgetRef ref, Color color) {
    // Implementation of _buildMedicationInput method
    return const Text('Medication input not implemented');
  }

  Widget _buildFamilyHistoryInput(
      Question question, WidgetRef ref, Color color) {
    // Implementation of _buildFamilyHistoryInput method
    return const Text('Family history input not implemented');
  }

  Widget _buildLocationInput(Question question, WidgetRef ref, Color color) {
    // Implementation of _buildLocationInput method
    return const Text('Location input not implemented');
  }

  Widget _buildDietaryOptionsInput(
      Question question, WidgetRef ref, Color color) {
    // Implementation of _buildDietaryOptionsInput method
    return const Text('Dietary options input not implemented');
  }
}
