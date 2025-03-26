import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:xenify/domain/entities/question.dart';
import 'package:xenify/domain/entities/medication.dart';
import 'package:xenify/domain/entities/family_condition.dart';
import 'package:xenify/domain/entities/location_data.dart';
import 'package:xenify/presentation/providers/questionnaire_provider.dart';
import 'package:xenify/presentation/theme/questionnaire_theme.dart';
import 'package:xenify/presentation/widgets/questionnaire/progress_bar_widget.dart';
import 'package:xenify/presentation/widgets/medication_form.dart';
import 'package:xenify/presentation/widgets/family_history_form.dart';
import 'package:xenify/presentation/widgets/questionnaire/location_progress_animation.dart';

class QuestionWidgetUpdated extends ConsumerWidget {
  const QuestionWidgetUpdated({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(questionsProvider);
    final currentQuestion = questionsList[state.currentQuestionIndex];
    final viewInsets = MediaQuery.of(context).viewInsets;
    final isKeyboardVisible = viewInsets.bottom > 0;

    final questionCategory = _getQuestionCategory(currentQuestion);
    final progress = (state.currentQuestionIndex + 1) / questionsList.length;
    final progressText =
        "${state.currentQuestionIndex + 1}/${questionsList.length}";

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: QuestionnaireProgressBar(
                progress: progress,
                category: questionCategory,
                progressText: progressText,
              ),
            ),
            _buildQuestionCard(
              context,
              currentQuestion,
              ref,
              questionCategory,
              isKeyboardVisible,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(
    BuildContext context,
    Question question,
    WidgetRef ref,
    QuestionCategory category,
    bool isKeyboardVisible,
  ) {
    final state = ref.watch(questionsProvider);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: QuestionnaireTheme.getCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: QuestionnaireTheme.headerHeight,
            decoration:
                QuestionnaireTheme.getCategoryHeaderDecoration(category),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              // Usar el texto personalizado si está disponible
              state.currentQuestionText ?? question.text,
              style: QuestionnaireTheme.questionTextStyle,
              textAlign: TextAlign.left,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildInputField(context, question, ref, category),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    BuildContext context,
    Question question,
    WidgetRef ref,
    QuestionCategory category,
  ) {
    final categoryColor = QuestionnaireTheme.getCategoryColor(category);
    final state = ref.watch(questionsProvider);
    final currentAnswer = state.answers[question.id];

    switch (question.type) {
      case QuestionType.location:
        return FutureBuilder<LocationData?>(
          future: _getCurrentLocation(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
                    ),
                    const SizedBox(height: 16),
                    const Text('Obteniendo ubicación...'),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                snapshot.error.toString(),
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildButton(
                    text: 'Reintentar',
                    onPressed: () => ref
                        .read(questionsProvider.notifier)
                        .updateAnswer(question.id, null),
                    color: categoryColor,
                  ),
                ],
              );
            }

            // Si ya existe una respuesta (al retroceder), mostrarla
            if (currentAnswer != null && currentAnswer is LocationData) {
              return Column(
                children: [
                  const LocationProgressAnimation(),
                  const SizedBox(height: 16),

                  // Mostrar información de la ubicación ya guardada
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.green[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'País: ${currentAnswer.country}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Ciudad: ${currentAnswer.city}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            if (snapshot.hasData) {
              final locationData = snapshot.data!;

              // Actualizar la respuesta pero no avanzar
              Future.microtask(() {
                ref
                    .read(questionsProvider.notifier)
                    .updateAnswer(question.id, locationData);
              });

              return Column(
                children: [
                  const LocationProgressAnimation(),
                  const SizedBox(height: 16),

                  // Mostrar información de la ubicación
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.green[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'País: ${locationData.country}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Ciudad: ${locationData.city}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return _buildButton(
              text: 'Obtener ubicación',
              onPressed: () => ref
                  .read(questionsProvider.notifier)
                  .updateAnswer(question.id, null),
              color: categoryColor,
            );
          },
        );

      case QuestionType.yesNo:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildButton(
              text: 'Sí',
              onPressed: () {
                // Actualizamos el estado Y avanzamos automáticamente
                ref
                    .read(questionsProvider.notifier)
                    .answerQuestion(question.id, true);
              },
              color: categoryColor,
              isSelected: currentAnswer == true,
            ),
            const SizedBox(height: 16),
            _buildButton(
              text: 'No',
              onPressed: () {
                // Actualizamos el estado Y avanzamos automáticamente
                ref
                    .read(questionsProvider.notifier)
                    .answerQuestion(question.id, false);
              },
              color: categoryColor,
              isPrimary: false,
              isSelected: currentAnswer == false,
            ),
          ],
        );

      case QuestionType.text:
        return FormBuilder(
          autovalidateMode: AutovalidateMode.disabled,
          child: FormBuilderTextField(
            name: question.id,
            initialValue: currentAnswer as String?,
            decoration: InputDecoration(
              hintText: question.hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              if (value != null) {
                // Actualizamos el estado sin avanzar a la siguiente pregunta
                ref
                    .read(questionsProvider.notifier)
                    .updateAnswer(question.id, value);
              }
            },
          ),
        );

      case QuestionType.number:
        return FormBuilder(
          autovalidateMode: AutovalidateMode.disabled,
          child: FormBuilderTextField(
            name: question.id,
            initialValue: currentAnswer?.toString(),
            decoration: InputDecoration(
              hintText: question.hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              if (value != null) {
                final numValue = int.tryParse(value) ?? double.tryParse(value);
                if (numValue != null) {
                  // Actualizamos el estado sin avanzar a la siguiente pregunta
                  ref
                      .read(questionsProvider.notifier)
                      .updateAnswer(question.id, numValue);
                }
              }
            },
          ),
        );

      case QuestionType.time:
        // Para resolver el problema de datos compartidos, usamos el ID como name para el campo
        final key =
            GlobalKey<FormBuilderState>(); // Clave única para cada formulario

        return FormBuilder(
          key: key,
          autovalidateMode: AutovalidateMode.disabled,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: categoryColor.withOpacity(0.5)),
              color: Colors.white,
            ),
            child: FormBuilderDateTimePicker(
              name:
                  question.id, // Usar el ID como nombre para evitar colisiones
              inputType: InputType.time,
              format: DateFormat('HH:mm'),
              decoration: InputDecoration(
                labelText: 'Seleccione una hora',
                labelStyle: TextStyle(color: categoryColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              initialValue: currentAnswer as DateTime?,
              initialTime: const TimeOfDay(hour: 7, minute: 0),
              onChanged: (value) {
                if (value != null) {
                  // Actualizamos la respuesta pero no continuamos automáticamente
                  Future.microtask(() {
                    ref
                        .read(questionsProvider.notifier)
                        .updateAnswer(question.id, value);
                  });
                }
              },
            ),
          ),
        );

      case QuestionType.date:
        final key = GlobalKey<FormBuilderState>();

        return FormBuilder(
          key: key,
          autovalidateMode: AutovalidateMode.disabled,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: categoryColor.withOpacity(0.5)),
              color: Colors.white,
            ),
            child: FormBuilderDateTimePicker(
              name: question.id, // Usar ID como nombre para evitar colisiones
              inputType: InputType.date,
              format: DateFormat('dd/MM/yyyy'),
              decoration: InputDecoration(
                labelText: 'Seleccione una fecha',
                labelStyle: TextStyle(color: categoryColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              initialValue: currentAnswer as DateTime?,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              onChanged: (value) {
                if (value != null) {
                  // Actualizamos sin continuar automáticamente
                  Future.microtask(() {
                    ref
                        .read(questionsProvider.notifier)
                        .updateAnswer(question.id, value);
                  });
                }
              },
            ),
          ),
        );

      case QuestionType.select:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...question.options!.map((option) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: _buildButton(
                    text: option,
                    onPressed: () {
                      // Solo actualizamos el estado, no avanzamos
                      ref
                          .read(questionsProvider.notifier)
                          .updateAnswer(question.id, option);
                    },
                    color: categoryColor,
                    isPrimary: false,
                    isSelected: currentAnswer == option,
                  ),
                )),
          ],
        );

      case QuestionType.multiSelect:
        final List<String> selectedOptions =
            (currentAnswer as List<String>?) ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...question.options!.map((option) => Container(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selectedOptions.contains(option)
                          ? categoryColor
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: CheckboxListTile(
                    title: Text(option),
                    value: selectedOptions.contains(option),
                    onChanged: (bool? value) {
                      // Esta actualización es segura porque responde a una acción del usuario
                      List<String> newSelection = List.from(selectedOptions);
                      if (value == true) {
                        newSelection.add(option);
                      } else {
                        newSelection.remove(option);
                      }
                      ref
                          .read(questionsProvider.notifier)
                          .updateAnswer(question.id, newSelection);
                    },
                    activeColor: categoryColor,
                  ),
                )),
          ],
        );

      case QuestionType.medication:
        // Obtener medicamentos actuales del estado
        final medications = (currentAnswer as List<Medication>?) ?? [];

        return MedicationForm(
          medications: medications,
          onAddMedication: (medication) {
            ref.read(questionsProvider.notifier).addMedication(medication);
          },
          onDeleteMedication: (index) {
            ref.read(questionsProvider.notifier).deleteMedication(index);
          },
        );

      case QuestionType.familyHistory:
        // Obtener condiciones familiares del estado
        final conditions = (currentAnswer as List<FamilyCondition>?) ?? [];

        return FamilyHistoryForm(
          conditions: conditions,
          onUpdate: (updatedConditions) {
            ref
                .read(questionsProvider.notifier)
                .updateFamilyConditions(updatedConditions);
          },
        );

      case QuestionType.dietaryOptions:
        // Similar a multiSelect pero con opciones específicas de dieta
        final List<String> selectedOptions =
            (currentAnswer as List<String>?) ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...question.options!.map((option) => Container(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selectedOptions.contains(option)
                          ? categoryColor
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: CheckboxListTile(
                    title: Text(option),
                    value: selectedOptions.contains(option),
                    onChanged: (bool? value) {
                      List<String> newSelection = List.from(selectedOptions);
                      if (value == true) {
                        newSelection.add(option);
                      } else {
                        newSelection.remove(option);
                      }
                      ref
                          .read(questionsProvider.notifier)
                          .updateAnswer(question.id, newSelection);
                    },
                    activeColor: categoryColor,
                  ),
                )),
          ],
        );

      case QuestionType.frequencySelect:
        // Preparamos los datos necesarios para mostrar la pregunta de frecuencia
        final currentProtein = state.currentProtein;

        if (currentProtein == null) {
          return const Center(
            child: Text('Error: No hay proteína seleccionada'),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...question.options!.map((frequency) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: _buildButton(
                    text: frequency,
                    onPressed: () {
                      final proteinFrequency = {
                        'protein': currentProtein,
                        'frequency': frequency,
                      };

                      // Obtener las frecuencias existentes
                      final currentFrequencies =
                          (state.answers['protein_frequencies']
                                  as List<Map<String, String>>?) ??
                              [];

                      // Actualizar con la nueva frecuencia
                      final updatedFrequencies = [
                        ...currentFrequencies,
                        proteinFrequency as Map<String, String>,
                      ];

                      // Actualizar ambos valores
                      ref.read(questionsProvider.notifier).updateAnswer(
                          'protein_frequencies', updatedFrequencies);

                      // Avanzar a la siguiente pregunta
                      ref
                          .read(questionsProvider.notifier)
                          .answerQuestion(question.id, proteinFrequency);
                    },
                    color: categoryColor,
                    isPrimary: false,
                  ),
                )),
          ],
        );

      default:
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Text('Tipo de pregunta no implementado: ${question.type}'),
        );
    }
  }

  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
    required Color color,
    bool isPrimary = true,
    bool isSelected = false,
  }) {
    // Ajustar los colores basados en si está seleccionado
    final backgroundColor = isSelected
        ? isPrimary
            ? color
            : color.withOpacity(0.1)
        : isPrimary
            ? color
            : Colors.white;

    final textColor = isSelected
        ? isPrimary
            ? Colors.white
            : color
        : isPrimary
            ? Colors.white
            : color;

    final borderColor = isSelected ? color : color.withOpacity(0.5);

    return SizedBox(
      width: double.infinity,
      child: isPrimary
          ? ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: backgroundColor,
                foregroundColor: textColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side:
                      BorderSide(color: borderColor, width: isSelected ? 2 : 1),
                ),
              ),
              child: Text(text),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: textColor,
                backgroundColor: backgroundColor,
                side: BorderSide(color: borderColor, width: isSelected ? 2 : 1),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(text),
            ),
    );
  }

  Future<LocationData?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Los servicios de ubicación están desactivados. Por favor, actívalos en la configuración de tu dispositivo.';
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Se requieren permisos de ubicación para continuar';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Los permisos de ubicación están permanentemente denegados. Por favor, actívalos en la configuración de tu dispositivo.';
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isEmpty) {
      throw 'No se pudo determinar la ubicación';
    }

    final placemark = placemarks.first;
    return LocationData(
      country: placemark.country ?? 'Desconocido',
      city: placemark.locality ??
          placemark.subAdministrativeArea ??
          'Desconocido',
      neighborhood: placemark.subLocality,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  QuestionCategory _getQuestionCategory(Question question) {
    // Preguntas relacionadas con la alimentación
    if (question.id.contains('diet') ||
        question.id.contains('nutrition') ||
        question.id.contains('food') ||
        question.id.contains('protein') ||
        question.id.contains('gluten') ||
        question.id.contains('meal') ||
        question.id.contains('breakfast') ||
        question.id.contains('lunch') ||
        question.id.contains('dinner') ||
        question.id.contains('vegetarian') ||
        question.id.contains('omnivore') ||
        question.id.contains('vegetables')) {
      return QuestionCategory.nutrition;
    }

    // Preguntas médicas/patológicas
    if (question.id.contains('pathology') ||
        question.id.contains('condition') ||
        question.id.contains('diagnosis')) {
      return QuestionCategory.general;
    }

    return QuestionCategory.general;
  }
}
