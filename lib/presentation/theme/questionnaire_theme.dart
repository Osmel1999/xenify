import 'package:flutter/material.dart';

/// Tema para los cuestionarios de la aplicación Xenify.
/// Define colores, estilos de texto y dimensiones consistentes para todos los cuestionarios.
class QuestionnaireTheme {
  // Colores por categoría
  static const Map<QuestionCategory, Color> categoryColors = {
    QuestionCategory.general: Color(0xFF4A90E2), // Azul
    QuestionCategory.nutrition: Color(0xFF4CAF50), // Verde
    QuestionCategory.sleep: Color(0xFF9C73E1), // Púrpura suave
    QuestionCategory.activity: Color(0xFFFF9800), // Naranja
    QuestionCategory.medication: Color(0xFFE57373), // Rojo suave
    QuestionCategory.mood: Color(0xFFFFD54F), // Amarillo cálido
    QuestionCategory.digestive: Color(0xFF7986CB), // Índigo
  };

  // Variaciones por momento del día
  static const Map<DayTime, List<Color>> daytimeColors = {
    DayTime.morning: [
      Color(0xFFE3F2FD), // Azul muy claro
      Color(0xFFB3E5FC), // Azul claro
      Color(0xFF81D4FA), // Cian claro
    ],
    DayTime.noon: [
      Color(0xFFFFF8E1), // Amarillo muy claro
      Color(0xFFFFECB3), // Amarillo claro
      Color(0xFFFFE082), // Naranja claro
    ],
    DayTime.evening: [
      Color(0xFFE8EAF6), // Púrpura muy claro
      Color(0xFFC5CAE9), // Púrpura claro
      Color(0xFF9FA8DA), // Azul oscuro suave
    ],
  };

  // Colores base
  static const Color backgroundColor = Color(0xFFF5F7FA); // Fondo principal
  static const Color cardBackgroundColor = Colors.white; // Fondo de tarjetas
  static const Color textPrimaryColor = Color(0xFF333333); // Texto principal
  static const Color textSecondaryColor = Color(0xFF555555); // Texto secundario
  static const Color textTertiaryColor = Color(0xFF777777); // Texto terciario
  static const Color disabledColor =
      Color(0xFFE0E0E0); // Elementos deshabilitados

  // Estilos de tipografía
  static const TextStyle questionTextStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
    height: 1.5,
  );

  static const TextStyle optionTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textSecondaryColor,
    height: 1.5,
  );

  static const TextStyle secondaryTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textTertiaryColor,
    height: 1.5,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    height: 1.5,
  );

  // Dimensiones y espaciado
  static const double cardBorderRadius = 12.0;
  static const double cardPadding = 24.0;
  static const double optionsSpacing = 16.0;
  static const double headerHeight = 6.0;
  static const double iconSize = 24.0;
  static const double smallIconSize = 20.0;
  static const double cardElevation = 2.0;
  static const double progressBarHeight = 6.0;
  static const double touchTargetSize = 44.0;

  // Duración de animaciones
  static const Duration transitionDuration = Duration(milliseconds: 350);
  static const Duration microinteractionDuration = Duration(milliseconds: 150);

  // Decoraciones
  static BoxDecoration getCardDecoration() {
    return BoxDecoration(
      color: cardBackgroundColor,
      borderRadius: BorderRadius.circular(cardBorderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // Obtener el color principal basado en la categoría de la pregunta
  static Color getCategoryColor(QuestionCategory category) {
    return categoryColors[category] ??
        categoryColors[QuestionCategory.general]!;
  }

  // Obtener el color de fondo basado en el momento del día
  static Color getDaytimeBackgroundColor(DayTime daytime) {
    final colors = daytimeColors[daytime] ?? daytimeColors[DayTime.noon]!;
    return colors[0]; // Color más claro para fondos
  }

  // Obtener el color de acento basado en el momento del día
  static Color getDaytimeAccentColor(DayTime daytime) {
    final colors = daytimeColors[daytime] ?? daytimeColors[DayTime.noon]!;
    return colors[2]; // Color más intenso para acentos
  }

  // Obtener decoración para el header de la tarjeta de pregunta
  static BoxDecoration getCategoryHeaderDecoration(QuestionCategory category) {
    final color = getCategoryColor(category);
    return BoxDecoration(
      color: color,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(cardBorderRadius),
        topRight: Radius.circular(cardBorderRadius),
      ),
    );
  }
}

/// Categorías de preguntas para agrupar y dar estilo según el tema
enum QuestionCategory {
  general, // Preguntas generales de salud
  nutrition, // Alimentación y nutrición
  sleep, // Sueño y descanso
  activity, // Actividad física
  medication, // Medicamentos y tratamientos
  mood, // Estado de ánimo
  digestive, // Salud digestiva
}

/// Momentos del día para adaptar la UI según la hora
enum DayTime {
  morning, // Mañana (5:00 - 11:59)
  noon, // Mediodía y tarde (12:00 - 17:59)
  evening, // Noche (18:00 - 4:59)
}

/// Extensión para determinar el momento del día basado en la hora actual
extension DayTimeExtension on DateTime {
  DayTime get dayTime {
    final hour = this.hour;
    if (hour >= 5 && hour < 12) {
      return DayTime.morning;
    } else if (hour >= 12 && hour < 18) {
      return DayTime.noon;
    } else {
      return DayTime.evening;
    }
  }
}

/// Extensión para obtener iconos según la categoría de pregunta
extension CategoryIconExtension on QuestionCategory {
  IconData get icon {
    switch (this) {
      case QuestionCategory.general:
        return Icons.health_and_safety;
      case QuestionCategory.nutrition:
        return Icons.restaurant;
      case QuestionCategory.sleep:
        return Icons.bedtime;
      case QuestionCategory.activity:
        return Icons.directions_run;
      case QuestionCategory.medication:
        return Icons.medication;
      case QuestionCategory.mood:
        return Icons.mood;
      case QuestionCategory.digestive:
        return Icons.water_drop;
    }
  }
}
