# Xenify - Aplicación de Salud Integral

## Descripción

Xenify es una aplicación móvil de salud integral desarrollada en Flutter que tiene como objetivo ayudar a los usuarios a gestionar y monitorear su salud de manera holística. La aplicación está diseñada para atender dos perfiles principales de usuarios:

1. **Usuarios Patológicos (P)**: Personas que tienen condiciones médicas diagnosticadas, están bajo tratamiento o tienen antecedentes familiares de enfermedades que requieren monitoreo preventivo.
2. **Usuarios Saludables (S)**: Personas que buscan mejorar su estilo de vida, optimizar su bienestar físico y mental, y desarrollar hábitos más saludables.

## Características Principales

- Sistema de seguimiento integral que monitorea condiciones de salud, métricas diarias y hábitos
- Registro de bienestar diario (estado de ánimo, niveles de energía, calidad del sueño)
- Monitoreo detallado de alimentación e hidratación
- Seguimiento digestivo completo
- Sistema de recomendaciones personalizado integrado con productos 4life
- Sistema de notificaciones para medicamentos y hábitos

## Tecnología

- **Framework**: Flutter 3.6+
- **Lenguaje**: Dart 3.6+
- **Gestión de estado**: Riverpod
- **Bases de datos locales**: SharedPreferences, SQLite
- **Notificaciones**: flutter_local_notifications
- **Formularios**: flutter_form_builder
- **Visualización de datos**: fl_chart, percent_indicator
- **Geolocalización**: geolocator, geocoding

## Requisitos del Sistema

- Flutter SDK 3.6 o superior
- Dart 3.6 o superior
- Android SDK o iOS SDK
- Dispositivo o emulador con Android 5.0+ o iOS 10.0+

## Instalación

1. Clona el repositorio:
   ```
   git clone https://github.com/tuusuario/xenify.git
   ```

2. Navega al directorio del proyecto:
   ```
   cd xenify
   ```

3. Instala las dependencias:
   ```
   flutter pub get
   ```

4. Ejecuta la aplicación:
   ```
   flutter run
   ```

## Estructura del Proyecto

```
lib/
├── data/
│   ├── local_storage.dart
│   ├── notification_service.dart
│   └── repositories/
│       └── ...
├── domain/
│   ├── entities/
│   │   ├── family_condition.dart
│   │   ├── location_data.dart
│   │   ├── meal_notification_config.dart
│   │   ├── medication.dart
│   │   ├── notification_data.dart
│   │   ├── question.dart
│   │   └── questionnaire_state.dart
│   └── services/
│       └── ...
├── presentation/
│   ├── providers/
│   │   ├── notification_provider.dart
│   │   ├── questionnaire_provider.dart
│   │   └── notifiers/
│   │       └── questionnaire_notifier.dart
│   ├── screens/
│   │   ├── dashboard_screen.dart
│   │   ├── home_screen.dart
│   │   └── questionnaire_screen.dart
│   └── widgets/
│       ├── question_widget.dart
│       ├── medication_form.dart
│       ├── family_history_form.dart
│       ├── dashboard/
│       │   ├── header_widget.dart
│       │   ├── wellbeing_card_widget.dart
│       │   ├── metrics_row_widget.dart
│       │   ├── hydration_card_widget.dart
│       │   ├── meal_tracking_card_widget.dart
│       │   ├── digestive_health_card_widget.dart
│       │   ├── medication_reminder_card_widget.dart
│       │   └── bottom_navigation_widget.dart
│       └── common/
│           ├── nutrient_row_widget.dart
│           ├── nutrient_column_widget.dart
│           ├── symptom_chip_widget.dart
│           ├── wellbeing_indicator_widget.dart
│           └── circular_percent_indicator_widget.dart
└── main.dart
```

## Flujo de la Aplicación

1. **Inicio**: El usuario abre la aplicación y es dirigido a la pantalla de bienvenida.
2. **Cuestionario Inicial**: Si es la primera vez, el usuario completa un cuestionario inicial para personalizar la experiencia.
3. **Dashboard**: La pantalla principal muestra un resumen de las métricas de salud del usuario.
4. **Seguimiento diario**: El usuario puede registrar sus métricas diarias (comidas, hidratación, estado de ánimo, etc.).
5. **Notificaciones**: La aplicación envía recordatorios para medicamentos y seguimiento post-comidas.

## Plan de Desarrollo

El desarrollo se está realizando en fases:

1. **Fase 1 (MVP)**:
   - Cuestionario inicial básico
   - Sistema de notificaciones para medicamentos
   - Registro diario básico
   - Almacenamiento local

2. **Fase 2 (Actual)**:
   - Sistema completo de notificaciones
   - Registro detallado de alimentación
   - Análisis básico de patrones
   - Dashboard principal

3. **Fase 3 (Próxima)**:
   - Sistema de recomendaciones
   - Integración con 4life
   - Visualización avanzada de datos
   - Exportación de datos
   - Integración de APIs de IA para recomendaciones científicas

4. **Fase 4 (Futura)**:
   - Características avanzadas de análisis
   - Mejoras en UX/UI
   - Optimizaciones de rendimiento
   - Funcionalidades adicionales basadas en feedback

## Contribución

Si deseas contribuir al proyecto, por favor:

1. Haz un fork del repositorio
2. Crea una rama para tu característica (`git checkout -b feature/amazing-feature`)
3. Haz commit de tus cambios (`git commit -m 'Add some amazing feature'`)
4. Haz push a la rama (`git push origin feature/amazing-feature`)
5. Abre un Pull Request

## Licencia

Este proyecto está licenciado bajo [LICENCIA] - ver el archivo LICENSE.md para más detalles.

## Contacto

[Tu Nombre] - [tu.email@ejemplo.com]

Link del proyecto: [https://github.com/tuusuario/xenify](https://github.com/tuusuario/xenify)