import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzl;
import 'package:xenify/data/provider_container.dart';
import 'package:xenify/domain/entities/meal_notification_config.dart';
import 'package:xenify/domain/entities/daily_questionnaire_type.dart';
import 'package:xenify/presentation/providers/daily_questionnaire_provider.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String MEDICATION_CHANNEL = 'medication_channel';
  static const String POST_MEAL_CHANNEL = 'post_meal_channel';
  static const String DAILY_QUESTIONNAIRE_CHANNEL =
      'daily_questionnaire_channel';
  static const String MORNING_QUESTIONNAIRE_CHANNEL =
      'morning_questionnaire_channel';
  static const String EVENING_QUESTIONNAIRE_CHANNEL =
      'evening_questionnaire_channel';

  NotificationService._();

  Future<void> initialize() async {
    try {
      print('🔔 Inicializando servicio de notificaciones...');

      tzl.initializeTimeZones();

      // Configuración para Android
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // Configuración simplificada para iOS
      const iosSettings = DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
        defaultPresentAlert: true,
        defaultPresentBadge: true,
        defaultPresentSound: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          print('🔔 Notificación clickeada: ${details.payload}');
        },
      );

      // Solicitar permisos explícitamente para iOS
      if (Platform.isIOS) {
        print('🔔 Solicitando permisos de iOS...');
        final bool? granted = await _notifications
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
              critical: true,
            );
        print('🔔 Permisos de iOS otorgados: $granted');
      }

      print('🔔 Servicio de notificaciones inicializado correctamente');
      await scheduleAllDailyQuestionnaires();
    } catch (e) {
      print('❌ Error inicializando notificaciones: $e');
      rethrow;
    }
  }

  Future<void> scheduleMedicationNotifications(
    String medicationName,
    DateTime startDate,
    DateTime? endDate,
    int intervalHours,
  ) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        MEDICATION_CHANNEL,
        'Medication Reminders',
        channelDescription: 'Notifications for medication reminders',
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound('medication_alert'),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'medication_alert',
        interruptionLevel: InterruptionLevel.active,
        categoryIdentifier: MEDICATION_CHANNEL,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final baseId =
          "${medicationName.hashCode}${startDate.millisecondsSinceEpoch}"
              .hashCode;

      if (endDate == null) {
        // Para medicaciones indefinidas, programamos las próximas 24 horas * 7 días
        final now = DateTime.now();
        DateTime scheduleTime = now;

        // Calcular la primera notificación
        if (startDate.isAfter(now)) {
          scheduleTime = startDate;
        } else {
          // Encontrar el próximo horario basado en el intervalo
          final hoursSinceStart = now.difference(startDate).inHours;
          final nextInterval =
              ((hoursSinceStart / intervalHours).ceil() * intervalHours);
          scheduleTime = startDate.add(Duration(hours: nextInterval));
        }

        // Programar las próximas notificaciones (7 días)
        for (var i = 0; i < (24 * 7 / intervalHours).ceil(); i++) {
          if (scheduleTime.isAfter(now)) {
            final notificationId = baseId + i;

            await _notifications.zonedSchedule(
              notificationId,
              '¡Hora de tu medicamento!',
              'Es momento de tomar $medicationName',
              tz.TZDateTime.from(scheduleTime, tz.local),
              notificationDetails,
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              matchDateTimeComponents: DateTimeComponents.time,
            );
          }
          scheduleTime = scheduleTime.add(Duration(hours: intervalHours));
        }

        // Programar una notificación para recordar reprogramar en 6 días
        final reminderDate = now.add(const Duration(days: 6));
        await _notifications.zonedSchedule(
          baseId + 999999,
          'Actualización de recordatorios',
          'Hace tiempo no registras tu dosis de $medicationName',
          tz.TZDateTime.from(reminderDate, tz.local),
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } else {
        // El código existente para medicaciones con fecha de fin
        var currentDate = startDate;
        var counter = 0;

        while (currentDate.isBefore(endDate)) {
          if (currentDate.isAfter(DateTime.now())) {
            await _notifications.zonedSchedule(
              baseId + counter,
              '¡Hora de tu medicamento!',
              'Es momento de tomar $medicationName',
              tz.TZDateTime.from(currentDate, tz.local),
              notificationDetails,
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
            );
          }
          currentDate = currentDate.add(Duration(hours: intervalHours));
          counter++;
        }
      }
    } catch (e) {
      print('Error scheduling medication notifications: $e');
      rethrow;
    }
  }

  Future<void> schedulePostMealNotifications(
      List<MealNotificationConfig> mealConfigs) async {
    try {
      var androidDetails = AndroidNotificationDetails(
        POST_MEAL_CHANNEL,
        'Post-meal Reminders',
        channelDescription: 'Notifications for post-meal reminders',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 300, 100, 300]),
        sound: const RawResourceAndroidNotificationSound('medication_alert'),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'medication_alert',
        interruptionLevel: InterruptionLevel.active,
        categoryIdentifier: POST_MEAL_CHANNEL,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final now = DateTime.now();

      for (var config in mealConfigs) {
        if (!config.isEnabled) continue;

        final timeComponents = config.time.split(':');
        final hour = int.parse(timeComponents[0]);
        final minute = int.parse(timeComponents[1]);

        // Crear el ID base para las notificaciones de esta comida
        final baseId = "${config.mealType}_${config.time}".hashCode;

        // Programar para los próximos 7 días
        for (var i = 0; i < 7; i++) {
          var scheduleDate = DateTime(
            now.year,
            now.month,
            now.day + i,
            hour,
            minute,
          );

          // Si la hora ya pasó hoy, comenzar desde mañana
          if (i == 0 && scheduleDate.isBefore(now)) {
            continue;
          }

          await _notifications.zonedSchedule(
            baseId + i,
            'Registro Post-${_getMealName(config.mealType)}',
            '¿Cómo te sientes después de tu ${_getMealName(config.mealType)}?',
            tz.TZDateTime.from(scheduleDate, tz.local),
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
          );
        }

        // Programar recordatorio para reprogramar en 6 días
        final reminderDate = now.add(const Duration(days: 6));
        await _notifications.zonedSchedule(
          baseId + 999999,
          'Actualización de recordatorios',
          'Hace tiempo no registras tu post-${_getMealName(config.mealType)}',
          tz.TZDateTime.from(reminderDate, tz.local),
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (e) {
      print('❌ Error programando notificaciones post-comida: $e');
      rethrow;
    }
  }

  String _getMealName(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return 'desayuno';
      case 'lunch':
        return 'almuerzo';
      case 'dinner':
        return 'cena';
      default:
        return 'comida';
    }
  }

  Future<void> cancelMealNotifications(String mealType) async {
    final notificationId = "${mealType}_notification".hashCode;
    await _notifications.cancel(notificationId);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> cancelMedicationNotifications(
      String medicationName, DateTime startDate) async {
    try {
      final baseId =
          "${medicationName.hashCode}${startDate.millisecondsSinceEpoch}"
              .hashCode;
      await _notifications.cancel(baseId);

      // Cancelar todas las notificaciones posibles en un rango de 30 días
      for (var i = 0; i < 720; i++) {
        await _notifications.cancel(baseId + i);
      }
    } catch (e) {
      print('❌ Error cancelando notificaciones de medicamentos: $e');
      rethrow;
    }
  }

  // Programar notificaciones para todos los cuestionarios diarios
  Future<void> scheduleAllDailyQuestionnaires() async {
    // Programar cuestionario de sueño para las 7:00 AM
    await scheduleDailyQuestionnaireNotification(
        DailyQuestionnaireType.sleep,
        7, // hora
        0, // minuto
        'Cuestionario de sueño',
        '¿Cómo dormiste anoche? Completa tu cuestionario matutino.');

    // Programar cuestionario matutino para las 9:00 AM
    await scheduleDailyQuestionnaireNotification(
        DailyQuestionnaireType.morning,
        9, // hora
        0, // minuto
        'Cuestionario matutino',
        '¡Buenos días! Completa tu cuestionario de la mañana.');

    // Programar cuestionario de tarde para las 15:00 PM
    await scheduleDailyQuestionnaireNotification(
        DailyQuestionnaireType.afternoon,
        15, // hora
        0, // minuto
        'Cuestionario de tarde',
        '¿Cómo va tu día? Completa tu cuestionario de la tarde.');

    // Programar cuestionario nocturno para las 20:00 PM
    await scheduleDailyQuestionnaireNotification(
        DailyQuestionnaireType.evening,
        20, // hora
        0, // minuto
        'Cuestionario nocturno',
        'Antes de terminar el día, completa tu cuestionario nocturno.');
  }

  // Programar una notificación para un cuestionario diario específico
  Future<void> scheduleDailyQuestionnaireNotification(
    DailyQuestionnaireType type,
    int hour,
    int minute,
    String title,
    String body,
  ) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        DAILY_QUESTIONNAIRE_CHANNEL,
        'Cuestionarios Diarios',
        channelDescription:
            'Notificaciones para los cuestionarios diarios de salud',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Calcular la hora para la notificación (hoy o mañana)
      final now = DateTime.now();
      var scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // Si la hora ya pasó hoy, programar para mañana
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // Crear payload con información del tipo de cuestionario
      final payload = NotificationData(
        id: type.hashCode,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        type: 'daily_questionnaire_${type.toString().split('.').last}',
      ).toJson();

      // Programar notificación repetitiva diaria
      await _notifications.zonedSchedule(
        type.hashCode,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents:
            DateTimeComponents.time, // Repite diariamente a la misma hora
        payload: jsonEncode(payload),
      );

      print(
          '🔔 Notificación de cuestionario ${type.toString()} programada para las $hour:$minute');
    } catch (e) {
      print('❌ Error programando notificación de cuestionario: $e');
      rethrow;
    }
  }

  void activateDailyQuestionnaire(DailyQuestionnaireType type) {
    print('🔔 Activando cuestionario de tipo: ${type.toString()}');

    // Acceder al provider desde fuera del árbol de widgets usando el contenedor global
    providerContainer
        .read(dailyQuestionnaireStateProvider.notifier)
        .showQuestionnaire(type);
  }
}

class NotificationData {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledDate;
  final String type;

  NotificationData({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'scheduledDate': scheduledDate.toIso8601String(),
        'type': type,
      };
}
