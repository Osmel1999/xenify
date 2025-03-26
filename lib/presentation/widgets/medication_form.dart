import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:xenify/domain/entities/medication.dart';

class MedicationForm extends StatefulWidget {
  final Function(Medication) onAddMedication;
  final List<Medication> medications;
  final Function(int)?
      onDeleteMedication; // Nuevo parámetro para manejar eliminación

  const MedicationForm({
    super.key,
    required this.onAddMedication,
    required this.medications,
    this.onDeleteMedication, // Agregamos el callback de eliminación
  });

  @override
  State<MedicationForm> createState() => _MedicationFormState();
}

class _MedicationFormState extends State<MedicationForm> {
  final _nameController = TextEditingController();
  final _hoursController = TextEditingController();
  bool _isIndefinite = false; // Cambiado a false por defecto
  DateTime? _endDate;
  TimeOfDay _nextDose = TimeOfDay.now();

  void _resetForm() {
    _nameController.clear();
    _hoursController.clear();
    setState(() {
      _isIndefinite = false; // Reiniciar a false
      _endDate = null;
      _nextDose = TimeOfDay.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Formulario de medicación',
      hint: 'Introduzca detalles del medicamento',
      child: Column(
        children: [
          // Lista de medicamentos
          if (widget.medications.isNotEmpty) ...[
            ListView.builder(
              shrinkWrap: true,
              itemCount: widget.medications.length,
              itemBuilder: (context, index) {
                final medication = widget.medications[index];
                return Card(
                  child: ListTile(
                    title: Text(medication.name),
                    subtitle: Text(
                      'Cada ${medication.intervalHours} horas - ' +
                          (medication.isIndefinite
                              ? 'Indefinido'
                              : 'Hasta: ${medication.endDate?.toString().split(' ')[0]}'),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        if (widget.onDeleteMedication != null) {
                          widget.onDeleteMedication!(index);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],

          // Formulario para agregar medicamento
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del medicamento',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 100,
                child: TextFormField(
                  controller: _hoursController,
                  decoration: const InputDecoration(
                    labelText: 'Horas',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<bool>(
                value: _isIndefinite,
                items: const [
                  DropdownMenuItem(
                    value: false,
                    child: Text('Hasta'),
                  ),
                  DropdownMenuItem(
                    value: true,
                    child: Text('Indefinido'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _isIndefinite = value!;
                    if (_isIndefinite) {
                      _endDate = null;
                    }
                  });
                },
              ),
            ],
          ),

          if (!_isIndefinite) ...[
            const SizedBox(height: 8),
            FormBuilderDateTimePicker(
              name: 'endDate',
              inputType: InputType.date,
              initialValue: _endDate,
              onChanged: (value) => setState(() => _endDate = value),
            ),
          ],

          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Próxima dosis: '),
              TextButton(
                onPressed: () async {
                  final TimeOfDay? time = await showTimePicker(
                    context: context,
                    initialTime: _nextDose,
                  );
                  if (time != null) {
                    setState(() {
                      _nextDose = time;
                    });
                  }
                },
                child: Text(
                  '${_nextDose.hour.toString().padLeft(2, '0')}:${_nextDose.minute.toString().padLeft(2, '0')}',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // Validar campos obligatorios
              String? errorMessage;
              if (_nameController.text.isEmpty) {
                errorMessage = 'El nombre del medicamento es obligatorio';
              } else if (_hoursController.text.isEmpty) {
                errorMessage = 'El intervalo de horas es obligatorio';
              } else if (!_isIndefinite && _endDate == null) {
                errorMessage = 'La fecha de fin es obligatoria';
              } else if (_nextDose == null) {
                errorMessage = 'La próxima dosis es obligatoria';
              }

              if (errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(errorMessage)),
                );
                return;
              }

              final now = DateTime.now();
              final nextDose = DateTime(
                now.year,
                now.month,
                now.day,
                _nextDose.hour,
                _nextDose.minute,
              );

              final medication = Medication(
                name: _nameController.text,
                intervalHours: int.parse(_hoursController.text),
                isIndefinite: _isIndefinite,
                endDate: _endDate,
                nextDose: nextDose,
              );

              widget.onAddMedication(medication);
              _resetForm();
            },
            icon: const Icon(Icons.add),
            label: const Text('Agregar Medicamento'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hoursController.dispose();
    super.dispose();
  }
}
