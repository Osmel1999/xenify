import 'package:flutter/material.dart';

class SymptomChipWidget extends StatelessWidget {
  final String symptom;
  final MaterialColor color;

  const SymptomChipWidget({
    Key? key,
    required this.symptom,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: color[700],
          ),
          const SizedBox(width: 6),
          Text(
            symptom,
            style: TextStyle(
              color: color[800],
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
