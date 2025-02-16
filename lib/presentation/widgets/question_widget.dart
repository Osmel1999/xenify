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
import 'package:xenify/presentation/widgets/medication_form.dart';
import 'package:xenify/presentation/widgets/family_history_form.dart';

class QuestionWidget extends ConsumerWidget {
  const QuestionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(questionsProvider);
    final currentQuestion = questionsList[state.currentQuestionIndex];
    final viewInsets = MediaQuery.of(context).viewInsets;
    final isKeyboardVisible = viewInsets.bottom > 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 32, // 32 es el padding total
                maxHeight: double.infinity,
              ),
              child: Column(
                mainAxisAlignment: isKeyboardVisible
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (currentQuestion.type != QuestionType.frequencySelect)
                    Text(
                      currentQuestion.text,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                  SizedBox(height: isKeyboardVisible ? 16 : 32),
                  _buildInputField(context, currentQuestion, ref),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputField(
      BuildContext context, Question question, WidgetRef ref) {
    switch (question.type) {
      case QuestionType.yesNo:
        return Column(
          children: [
            ElevatedButton(
              onPressed: () => _submitAnswer(ref, question.id, true),
              child: const Text('Sí'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _submitAnswer(ref, question.id, false),
              child: const Text('No'),
            ),
          ],
        );

      case QuestionType.text:
        return FormBuilder(
          child: Column(
            children: [
              FormBuilderTextField(
                name: question.id,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: question.hint,
                ),
                onSubmitted: (value) => _submitAnswer(ref, question.id, value),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _submitAnswer(ref, question.id, ''),
                child: const Text('Continuar'),
              ),
            ],
          ),
        );

      case QuestionType.familyHistory:
        final conditions = (ref
                .watch(questionsProvider)
                .answers['family_conditions'] as List<FamilyCondition>?) ??
            [];

        return Column(
          children: [
            FamilyHistoryForm(
              conditions: conditions,
              onUpdate: (updatedConditions) {
                ref
                    .read(questionsProvider.notifier)
                    .updateFamilyConditions(updatedConditions);
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _submitAnswer(ref, question.id, conditions),
              child: const Text('Continuar'),
            ),
          ],
        );

      case QuestionType.medication:
        final medications = (ref.watch(questionsProvider).answers['medications']
                as List<Medication>?) ??
            [];

        return Column(
          children: [
            MedicationForm(
              medications: medications,
              onAddMedication: (medication) {
                ref.read(questionsProvider.notifier).addMedication(medication);
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _submitAnswer(ref, question.id, medications),
              child: const Text('Continuar'),
            ),
          ],
        );

      case QuestionType.number:
        return FormBuilder(
          child: Column(
            children: [
              FormBuilderTextField(
                name: question.id,
                keyboardType: TextInputType.number,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: question.hint,
                ),
                onSubmitted: (value) =>
                    _submitAnswer(ref, question.id, int.tryParse(value ?? '')),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _submitAnswer(ref, question.id, null),
                child: const Text('Continuar'),
              ),
            ],
          ),
        );

      case QuestionType.select:
        return Column(
          children: [
            ...question.options!.map((option) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ElevatedButton(
                    onPressed: () => _submitAnswer(ref, question.id, option),
                    child: Text(option),
                  ),
                )),
          ],
        );

      case QuestionType.multiSelect:
        final List<String> selectedOptions = (ref
                .watch(questionsProvider)
                .answers[question.id] as List<String>?) ??
            [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...question.options!.map((option) => Card(
                  child: CheckboxListTile(
                    title: Text(option),
                    value: selectedOptions.contains(option),
                    onChanged: (bool? value) {
                      List<String> newSelection = List.from(selectedOptions);
                      if (value == true) {
                        if (!newSelection.contains(option)) {
                          newSelection.add(option);
                        }
                      } else {
                        newSelection.remove(option);
                      }
                      ref
                          .read(questionsProvider.notifier)
                          .updateAnswer(question.id, newSelection);
                    },
                  ),
                )),
            const SizedBox(height: 16),
            if (selectedOptions.isNotEmpty || !question.isRequired)
              ElevatedButton(
                onPressed: () {
                  _submitAnswer(ref, question.id, selectedOptions);
                },
                child: const Text('Continuar'),
              ),
          ],
        );

      case QuestionType.date:
        return Column(
          children: [
            FormBuilderDateTimePicker(
              name: question.id,
              inputType: InputType.date,
              format: DateFormat('dd/MM/yyyy'),
              decoration: const InputDecoration(
                labelText: 'Seleccione una fecha',
              ),
              onChanged: (value) => _submitAnswer(ref, question.id, value),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _submitAnswer(ref, question.id, null),
              child: const Text('Continuar'),
            ),
          ],
        );

      case QuestionType.location:
        return FutureBuilder<LocationData?>(
          future: _getCurrentLocation(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Column(
                children: [
                  const Text(
                      'No se pudo obtener la ubicación. Por favor, verifica los permisos de ubicación.'),
                  ElevatedButton(
                    onPressed: () => _submitAnswer(ref, question.id, null),
                    child: const Text('Continuar sin ubicación'),
                  ),
                ],
              );
            }

            if (snapshot.hasData) {
              final location = snapshot.data!;
              return Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('País: ${location.country}'),
                          Text('Ciudad: ${location.city}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _submitAnswer(ref, question.id, location),
                    child: const Text('Confirmar ubicación'),
                  ),
                ],
              );
            }

            return const Text('No se pudo obtener la ubicación');
          },
        );

      case QuestionType.dietaryOptions:
        final selectedOptions = (ref
                .watch(questionsProvider)
                .answers[question.id] as List<String>?) ??
            [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...question.options!.map((option) => Card(
                  child: CheckboxListTile(
                    title: Text(option),
                    value: selectedOptions.contains(option),
                    onChanged: (bool? value) {
                      List<String> newSelection = List.from(selectedOptions);
                      if (value == true) {
                        if (!newSelection.contains(option)) {
                          newSelection.add(option);
                        }
                      } else {
                        newSelection.remove(option);
                      }
                      ref
                          .read(questionsProvider.notifier)
                          .updateAnswer(question.id, newSelection);
                    },
                  ),
                )),
            const SizedBox(height: 16),
            if (selectedOptions.isNotEmpty || !question.isRequired)
              ElevatedButton(
                onPressed: () {
                  _submitAnswer(ref, question.id, selectedOptions);
                },
                child: const Text('Continuar'),
              ),
          ],
        );

      case QuestionType.frequencySelect:
        final state = ref.watch(questionsProvider);
        final currentProtein = state.currentProtein;

        if (currentProtein == null) {
          return const Center(
              child: Text('Error: No hay proteína seleccionada'));
        }

        // Creamos directamente el texto de la pregunta
        final questionText =
            '¿Cuántas veces a la semana consumes ${currentProtein.toLowerCase()}?';

        print('Current protein: $currentProtein');

        return Column(
          children: [
            Text(
              questionText,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ...question.options!.map((frequency) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ElevatedButton(
                    onPressed: () {
                      final proteinFrequency = {
                        'protein': currentProtein,
                        'frequency': frequency,
                      };

                      // Actualizar las frecuencias existentes
                      final currentFrequencies =
                          (state.answers['protein_frequencies']
                                  as List<Map<String, String>>?) ??
                              [];

                      final updatedFrequencies = [
                        ...currentFrequencies,
                        proteinFrequency as Map<String, String>,
                      ];

                      // Guardar las frecuencias actualizadas
                      ref.read(questionsProvider.notifier).updateAnswer(
                            'protein_frequencies',
                            updatedFrequencies,
                          );

                      // Continuar con la siguiente pregunta
                      _submitAnswer(ref, question.id, proteinFrequency);
                    },
                    child: Text(frequency),
                  ),
                )),
          ],
        );
    }
  }

  void _submitAnswer(WidgetRef ref, String questionId, dynamic answer) {
    ref.read(questionsProvider.notifier).answerQuestion(questionId, answer);
  }

  // Método para obtener la ubicación actual
  Future<LocationData?> _getCurrentLocation() async {
    try {
      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      // Obtener posición
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Obtener detalles de la ubicación
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
}
