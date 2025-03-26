import 'package:flutter/material.dart';
import 'package:xenify/presentation/widgets/common/nutrient_column_widget.dart';

class MealTrackingCardWidget extends StatelessWidget {
  const MealTrackingCardWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: Color(0xFFFFDAD4), // Tono rosado para el card de comidas
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 18,
                      child: Icon(
                        Icons.show_chart,
                        color: Colors.grey[800],
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Desayuno',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 16,
                      child: Icon(
                        Icons.add,
                        color: Colors.grey[800],
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 16,
                      child: Icon(
                        Icons.edit,
                        color: Colors.grey[800],
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '350 calorías',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                NutrientColumnWidget(title: 'Proteínas', value: '62.5'),
                NutrientColumnWidget(title: 'Grasas', value: '23.6'),
                NutrientColumnWidget(title: 'Carbos', value: '45.7'),
                NutrientColumnWidget(title: 'RDC', value: '14%'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
