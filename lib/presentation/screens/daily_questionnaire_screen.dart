import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xenify/domain/entities/daily_questionnaire.dart';
import 'package:xenify/presentation/providers/daily_questionnaire_provider.dart';

class DailyQuestionnaireScreen extends ConsumerWidget {
  const DailyQuestionnaireScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionnaire = ref.watch(currentQuestionnaireProvider);

    if (questionnaire == null) {
      return const Center(
        child: Text('No hay cuestionarios pendientes en este momento'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(questionnaire.isMorning
            ? 'Cuestionario Matutino'
            : 'Cuestionario Nocturno'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuestionnaireContent(context, ref, questionnaire),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionnaireContent(
      BuildContext context, WidgetRef ref, DailyQuestionnaire questionnaire) {
    final morningQuestionnaire = ref
        .read(dailyQuestionnaireServiceProvider)
        .getTodayQuestionnaire(QuestionnaireType.morning);
    final needsMorningQuestions = questionnaire.isMorning ||
        (morningQuestionnaire?.isCompleted ?? false) == false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (needsMorningQuestions) ...[
          _buildRatingQuestion(
            context,
            ref,
            'Calidad del sueño',
            questionnaire.sleepQuality,
            (value) => ref
                .read(currentQuestionnaireProvider.notifier)
                .updateAnswers(sleepQuality: value),
          ),
          const SizedBox(height: 16),
          _buildRatingQuestion(
            context,
            ref,
            'Nivel de energía al despertar',
            questionnaire.energyLevel,
            (value) => ref
                .read(currentQuestionnaireProvider.notifier)
                .updateAnswers(energyLevel: value),
          ),
        ],
        const SizedBox(height: 16),
        _buildRatingQuestion(
          context,
          ref,
          questionnaire.isMorning
              ? 'Estado de ánimo al despertar'
              : 'Estado de ánimo durante el día',
          questionnaire.mood,
          (value) => ref
              .read(currentQuestionnaireProvider.notifier)
              .updateAnswers(mood: value),
        ),
        const SizedBox(height: 24),
        Text(
          'Registro de Baño',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        _buildBathroomEntrySection(context, ref, questionnaire),
        const SizedBox(height: 24),
        Text(
          'Registro de Comidas',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        _buildMealsSection(context, ref, questionnaire),
        const SizedBox(height: 32),
        Center(
          child: ElevatedButton(
            onPressed: _canComplete(questionnaire)
                ? () => _completeQuestionnaire(ref)
                : null,
            child: const Text('Completar Cuestionario'),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingQuestion(
    BuildContext context,
    WidgetRef ref,
    String title,
    int? currentValue,
    Function(int) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            5,
            (index) => _buildRatingButton(
              context,
              index + 1,
              currentValue,
              onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingButton(
    BuildContext context,
    int value,
    int? currentValue,
    Function(int) onChanged,
  ) {
    final isSelected = value == currentValue;
    return InkWell(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          border: Border.all(
            color: Theme.of(context).primaryColor,
          ),
        ),
        child: Text(
          value.toString(),
          style: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildBathroomEntrySection(
    BuildContext context,
    WidgetRef ref,
    DailyQuestionnaire questionnaire,
  ) {
    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: questionnaire.bathroomEntries.length,
          itemBuilder: (context, index) {
            final entry = questionnaire.bathroomEntries[index];
            return ListTile(
              title: Text(entry.type == BathroomType.urination
                  ? 'Orina'
                  : 'Defecación'),
              subtitle: Text(
                  'Color: ${entry.color}, Consistencia: ${entry.consistency}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  final newEntries =
                      List<BathroomEntry>.from(questionnaire.bathroomEntries)
                        ..removeAt(index);
                  ref
                      .read(currentQuestionnaireProvider.notifier)
                      .updateAnswers(bathroomEntries: newEntries);
                },
              ),
            );
          },
        ),
        ElevatedButton(
          onPressed: () => _showBathroomEntryDialog(context, ref),
          child: const Text('Agregar Registro'),
        ),
      ],
    );
  }

  void _showBathroomEntryDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _BathroomEntryDialog(
        onSave: (entry) {
          final currentQuestionnaire = ref.read(currentQuestionnaireProvider);
          if (currentQuestionnaire != null) {
            final newEntries =
                List<BathroomEntry>.from(currentQuestionnaire.bathroomEntries)
                  ..add(entry);
            ref
                .read(currentQuestionnaireProvider.notifier)
                .updateAnswers(bathroomEntries: newEntries);
          }
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Widget _buildMealsSection(
    BuildContext context,
    WidgetRef ref,
    DailyQuestionnaire questionnaire,
  ) {
    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: questionnaire.meals.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(questionnaire.meals[index]),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  final newMeals = List<String>.from(questionnaire.meals)
                    ..removeAt(index);
                  ref
                      .read(currentQuestionnaireProvider.notifier)
                      .updateAnswers(meals: newMeals);
                },
              ),
            );
          },
        ),
        ElevatedButton(
          onPressed: () => _showAddMealDialog(context, ref),
          child: const Text('Agregar Comida'),
        ),
      ],
    );
  }

  void _showAddMealDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Comida'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Describe tu comida',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final currentQuestionnaire =
                    ref.read(currentQuestionnaireProvider);
                if (currentQuestionnaire != null) {
                  final newMeals = List<String>.from(currentQuestionnaire.meals)
                    ..add(controller.text);
                  ref
                      .read(currentQuestionnaireProvider.notifier)
                      .updateAnswers(meals: newMeals);
                }
                Navigator.of(context).pop();
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  bool _canComplete(DailyQuestionnaire questionnaire) {
    return questionnaire.sleepQuality != null &&
        questionnaire.energyLevel != null &&
        questionnaire.mood != null &&
        questionnaire.meals.isNotEmpty;
  }

  void _completeQuestionnaire(WidgetRef ref) {
    ref.read(currentQuestionnaireProvider.notifier).completeQuestionnaire();
  }
}

class _BathroomEntryDialog extends StatefulWidget {
  final Function(BathroomEntry) onSave;

  const _BathroomEntryDialog({required this.onSave});

  @override
  _BathroomEntryDialogState createState() => _BathroomEntryDialogState();
}

class _BathroomEntryDialogState extends State<_BathroomEntryDialog> {
  BathroomType _type = BathroomType.urination;
  final _colorController = TextEditingController();
  final _consistencyController = TextEditingController();
  bool _didFloat = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo Registro'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<BathroomType>(
              value: _type,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _type = value);
                }
              },
              items: const [
                DropdownMenuItem(
                  value: BathroomType.urination,
                  child: Text('Orina'),
                ),
                DropdownMenuItem(
                  value: BathroomType.defecation,
                  child: Text('Defecación'),
                ),
              ],
            ),
            TextField(
              controller: _colorController,
              decoration: const InputDecoration(labelText: 'Color'),
            ),
            TextField(
              controller: _consistencyController,
              decoration: const InputDecoration(labelText: 'Consistencia'),
            ),
            if (_type == BathroomType.defecation)
              CheckboxListTile(
                title: const Text('¿Flotó?'),
                value: _didFloat,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _didFloat = value);
                  }
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            if (_colorController.text.isNotEmpty &&
                _consistencyController.text.isNotEmpty) {
              widget.onSave(BathroomEntry(
                type: _type,
                color: _colorController.text,
                consistency: _consistencyController.text,
                didFloat: _type == BathroomType.defecation ? _didFloat : false,
                timestamp: DateTime.now(),
              ));
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _colorController.dispose();
    _consistencyController.dispose();
    super.dispose();
  }
}
