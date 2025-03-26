import 'package:flutter/material.dart';

class LocationProgressAnimation extends StatefulWidget {
  // Eliminar el onCompleted callback
  // En lugar de llamar automáticamente a completado,
  // mostraremos la ubicación y esperaremos que el usuario presione "Continuar"

  const LocationProgressAnimation({
    Key? key,
  }) : super(key: key);

  @override
  State<LocationProgressAnimation> createState() =>
      _LocationProgressAnimationState();
}

class _LocationProgressAnimationState extends State<LocationProgressAnimation> {
  bool _isCompleted = false;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(seconds: 2),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        final isComplete = value >= 1.0;
        final color = isComplete ? Colors.green : Colors.blue;

        if (isComplete && !_isCompleted) {
          _isCompleted = true;
          // Ya no llamamos al callback automáticamente
        }

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 100,
                  width: 100,
                  child: CircularProgressIndicator(
                    value: value,
                    strokeWidth: 8,
                    color: color,
                    backgroundColor: color.withOpacity(0.2),
                  ),
                ),
                if (isComplete)
                  const Icon(
                    Icons.check,
                    color: Colors.green,
                    size: 40,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              isComplete ? 'Ubicación detectada' : 'Analizando ubicación...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        );
      },
    );
  }
}
