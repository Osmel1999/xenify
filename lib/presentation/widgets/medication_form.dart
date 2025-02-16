import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:xenify/domain/entities/medication.dart';

class MedicationForm extends StatefulWidget {
  final Function(Medication) onAddMedication;
  final List<Medication> medications;

  const MedicationForm({
    super.key,
    required this.onAddMedication,
    required this.medications,
  });

  @override
  State<MedicationForm> createState() => _MedicationFormState();
}

class _MedicationFormState extends State<MedicationForm> {
  final _nameController = TextEditingController();
  final _hoursController = TextEditingController();
  bool _isIndefinite = true;
  DateTime? _endDate;
  TimeOfDay _nextDose = TimeOfDay.now(); // Nueva variable

  void _resetForm() {
    _nameController.clear();
    _hoursController.clear();
    setState(() {
      _isIndefinite = true;
      _endDate = null;
      _nextDose = TimeOfDay.now(); // Reiniciar la hora de la próxima dosis
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Medications List
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
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],

        // Add Medication Form
        Row(
          children: [
            // Medication Name
            Expanded(
              child: TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del medicamento',
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Interval Hours
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

            // Duration Type
            DropdownButton<bool>(
              value: _isIndefinite,
              items: const [
                DropdownMenuItem(
                  value: true,
                  child: Text('Indefinido'),
                ),
                DropdownMenuItem(
                  value: false,
                  child: Text('Hasta'),
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

        // End Date Picker (if not indefinite)
        if (!_isIndefinite) ...[
          const SizedBox(height: 8),
          FormBuilderDateTimePicker(
            name: 'endDate',
            inputType: InputType.date,
            initialValue: _endDate,
            onChanged: (value) => setState(() => _endDate = value),
          ),
        ],

        // Nuevo selector de hora para la siguiente dosis
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

        // Add Button
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isEmpty || _hoursController.text.isEmpty) {
              return;
            }

            if (!_isIndefinite && _endDate == null) {
              return;
            }

            // Crear DateTime para la próxima dosis
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
              nextDose: nextDose, // Agregar la próxima dosis
            );

            widget.onAddMedication(medication);
            _resetForm();
          },
          child: const Text('Agregar Medicamento'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hoursController.dispose();
    super.dispose();
  }
}
