import 'package:flutter/material.dart';

// Widget para indicadores de bienestar en formato columna
class WellbeingIndicatorWidget extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const WellbeingIndicatorWidget({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 28,
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// Widget para indicadores de bienestar en formato compacto (utilizado en el header)
class WellbeingIndicatorCompactWidget extends StatelessWidget {
  final String value;
  final IconData icon;
  final Color color;

  const WellbeingIndicatorCompactWidget(
    this.value,
    this.icon,
    this.color, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
