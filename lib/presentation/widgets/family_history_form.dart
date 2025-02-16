import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:xenify/domain/entities/family_condition.dart';

class FamilyHistoryForm extends StatefulWidget {
  final Function(List<FamilyCondition>) onUpdate;
  final List<FamilyCondition> conditions;

  const FamilyHistoryForm({
    super.key,
    required this.onUpdate,
    required this.conditions,
  });

  @override
  State<FamilyHistoryForm> createState() => _FamilyHistoryFormState();
}

class _FamilyHistoryFormState extends State<FamilyHistoryForm> {
  final _conditionController = TextEditingController();
  String? _selectedRelative;
  final ScrollController _scrollController = ScrollController();

  final List<String> _relatives = [
    'Padre',
    'Madre',
    'Hermano/a',
    'Hijo/a',
    'Abuelo/a paterno/a',
    'Abuelo/a materno/a',
    'Nieto/a',
    'Tío/a paterno/a',
    'Tío/a materno/a',
    'Suegro/a',
    'Yerno/Nuera',
    'Cuñado/a',
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.conditions.isNotEmpty) ...[
                SizedBox(
                  height: math.min(200, widget.conditions.length * 80.0),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: widget.conditions.length,
                    itemBuilder: (context, index) {
                      final condition = widget.conditions[index];
                      return Card(
                        child: ListTile(
                          title: Text(condition.condition),
                          subtitle: Text(condition.relative),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              final updatedConditions =
                                  List<FamilyCondition>.from(widget.conditions)
                                    ..removeAt(index);
                              widget.onUpdate(updatedConditions);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextFormField(
                  controller: _conditionController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Enfermedad',
                    hintText: 'Ej: Diabetes Tipo 2',
                    border: OutlineInputBorder(),
                  ),
                  onTap: () {
                    // Dar tiempo para que el teclado aparezca
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (_scrollController.hasClients) {
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: DropdownButtonFormField<String>(
                  value: _selectedRelative,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Familiar',
                    border: OutlineInputBorder(),
                  ),
                  items: _relatives.map((relative) {
                    return DropdownMenuItem(
                      value: relative,
                      child: Text(relative),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRelative = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_conditionController.text.isEmpty ||
                        _selectedRelative == null) {
                      return;
                    }

                    final newCondition = FamilyCondition(
                      condition: _conditionController.text,
                      relative: _selectedRelative!,
                    );

                    final updatedConditions = [
                      ...widget.conditions,
                      newCondition
                    ];
                    widget.onUpdate(updatedConditions);

                    _conditionController.clear();
                    setState(() {
                      _selectedRelative = null;
                    });

                    // Ocultar el teclado después de agregar
                    FocusScope.of(context).unfocus();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar Condición'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _conditionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
