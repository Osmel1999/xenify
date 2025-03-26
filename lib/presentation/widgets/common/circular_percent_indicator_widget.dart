import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class CustomCircularPercentIndicator extends StatelessWidget {
  final double percent;
  final double radius;
  final double lineWidth;
  final Color progressColor;
  final Color backgroundColor;
  final Widget center;

  const CustomCircularPercentIndicator({
    Key? key,
    required this.percent,
    this.radius = 45.0,
    this.lineWidth = 8.0,
    required this.progressColor,
    required this.backgroundColor,
    required this.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircularPercentIndicator(
      radius: radius,
      lineWidth: lineWidth,
      percent: percent,
      center: center,
      progressColor: progressColor,
      backgroundColor: backgroundColor,
      circularStrokeCap: CircularStrokeCap.round,
      animation: true,
      animationDuration: 1000,
    );
  }
}

// Versión con texto para mostrar el porcentaje
class CircularPercentWithTextIndicator extends StatelessWidget {
  final double percent;
  final double radius;
  final double lineWidth;
  final Color progressColor;
  final Color backgroundColor;
  final String text;
  final TextStyle? textStyle;

  const CircularPercentWithTextIndicator({
    Key? key,
    required this.percent,
    this.radius = 45.0,
    this.lineWidth = 8.0,
    required this.progressColor,
    required this.backgroundColor,
    required this.text,
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final style = textStyle ??
        TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: progressColor,
        );

    return CircularPercentIndicator(
      radius: radius,
      lineWidth: lineWidth,
      percent: percent,
      center: Text(
        text,
        style: style,
      ),
      progressColor: progressColor,
      backgroundColor: backgroundColor,
      circularStrokeCap: CircularStrokeCap.round,
      animation: true,
      animationDuration: 1000,
    );
  }
}

// Versión con icono
class CircularPercentWithIconIndicator extends StatelessWidget {
  final double percent;
  final double radius;
  final double lineWidth;
  final Color progressColor;
  final Color backgroundColor;
  final IconData icon;
  final Color iconColor;
  final double iconSize;

  const CircularPercentWithIconIndicator({
    Key? key,
    required this.percent,
    this.radius = 45.0,
    this.lineWidth = 8.0,
    required this.progressColor,
    required this.backgroundColor,
    required this.icon,
    required this.iconColor,
    this.iconSize = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircularPercentIndicator(
      radius: radius,
      lineWidth: lineWidth,
      percent: percent,
      center: Icon(
        icon,
        color: iconColor,
        size: iconSize,
      ),
      progressColor: progressColor,
      backgroundColor: backgroundColor,
      circularStrokeCap: CircularStrokeCap.round,
      animation: true,
      animationDuration: 1000,
    );
  }
}
