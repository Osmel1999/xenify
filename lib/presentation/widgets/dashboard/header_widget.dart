import 'package:flutter/material.dart';
import 'package:xenify/presentation/widgets/common/wellbeing_indicator_widget.dart';

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¡Hola, Arlette!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Viernes, 2 marzo',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          Spacer(),
          WellbeingIndicatorCompactWidget(
              '8.5h', Icons.bedtime, Theme.of(context).primaryColor),
          WellbeingIndicatorCompactWidget('70%', Icons.battery_5_bar_rounded,
              Theme.of(context).primaryColor.withOpacity(0.7)),
          WellbeingIndicatorCompactWidget('Bueno', Icons.sentiment_satisfied,
              Theme.of(context).primaryColor),
        ],
      ),
    );
  }
}
