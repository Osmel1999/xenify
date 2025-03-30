import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzl;
import 'package:xenify/data/provider_container.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String MEDICATION_CHANNEL = 'medication_channel';

  late final tz.Location _local;

  NotificationService._() {
    tzl.initializeTimeZones();
    _local = tz.getLocation('America/Bogota');
  }

  Future<void> initialize() async {
    try {
      print('🔔 Inicializando servicio de notificaciones...');
      // tzl.initializeTimeZones();

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
      // Primero cancelar notificaciones existentes
      await cancelMedicationNotifications(medicationName, startDate);

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

      final now = DateTime.now();

      // Calcular cuántas dosis diarias hay
      final dosesPerDay = 24 ~/ intervalHours;

      // Para cada dosis diaria
      for (var i = 0; i < dosesPerDay; i++) {
        // Calcular la hora de esta dosis
        var doseTime = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
          startDate.hour + (i * intervalHours),
          startDate.minute,
        );

        // Si la hora ya pasó hoy, ajustar para que empiece desde hoy
        if (doseTime.isBefore(now)) {
          doseTime = DateTime(
            now.year,
            now.month,
            now.day,
            doseTime.hour,
            doseTime.minute,
          );
        }

        // Crear ID único para esta dosis específica
        final doseId =
            "${medicationName}_${doseTime.hour}_${doseTime.minute}".hashCode;

        print('🔔 Programando dosis para $medicationName:');
        print('- Hora: ${doseTime.hour}:${doseTime.minute}');

        // Programar notificación recurrente
        await _notifications.zonedSchedule(
          doseId,
          '¡Hora de tu medicamento!',
          'Es momento de tomar $medicationName',
          tz.TZDateTime.from(doseTime, tz.local),
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents:
              endDate == null ? DateTimeComponents.time : null,
        );

        print('✅ Notificación programada con ID: $doseId');
        if (endDate != null) {
          print('- Hasta: ${endDate.toString()}');
        } else {
          print('- Repetición: Diaria');
        }
      }
    } catch (e) {
      print('Error scheduling medication notifications: $e');
      rethrow;
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> _cancelDailyNotifications() async {
    try {
      print('🔄 Cancelando notificaciones diarias existentes');
      // Cancelar usando los IDs fijos
      await _notifications.cancel(9001); // ID matutino
      await _notifications.cancel(9002); // ID nocturno
      print('✅ Notificaciones diarias canceladas');
    } catch (e) {
      print('❌ Error cancelando notificaciones diarias: $e');
      rethrow;
    }
  }

  Future<void> cancelMedicationNotifications(
      String medicationName, DateTime startDate) async {
    try {
      print('🔄 Cancelando notificaciones existentes para: $medicationName');

      // Cancelar todas las notificaciones pendientes
      await _notifications.cancelAll();

      print('✅ Todas las notificaciones canceladas');
    } catch (e) {
      print('❌ Error cancelando notificaciones de medicamentos: $e');
      rethrow;
    }
  }

  bool _isValidTime(DateTime time) {
    return time.year > 1 &&
        time.hour >= 0 &&
        time.hour < 24 &&
        time.minute >= 0 &&
        time.minute < 60;
  }

  Future<void> scheduleWakeAndSleepNotifications(
      DateTime wakeUpTime, DateTime sleepTime) async {
    try {
      if (!_isValidTime(wakeUpTime) || !_isValidTime(sleepTime)) {
        throw Exception('Horarios de despertar o dormir inválidos');
      }

      print('🔔 Programando notificaciones diarias matutinas y nocturnas');

      const androidDetails = AndroidNotificationDetails(
        MEDICATION_CHANNEL,
        'Notificaciones Diarias',
        channelDescription: 'Notificaciones para recordatorios diarios',
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

      // Cancelar notificaciones existentes antes de programar nuevas
      await _cancelDailyNotifications();

      // Crear DateTime con la fecha actual y la hora especificada
      final now = DateTime.now();
      final todayWakeUpTime = DateTime(
        now.year,
        now.month,
        now.day,
        wakeUpTime.hour,
        wakeUpTime.minute,
      );

      // Notificación matutina (30 minutos después de despertar)
      final wakeNotificationTime =
          todayWakeUpTime.add(const Duration(minutes: 30));

      await _notifications.zonedSchedule(
        9001, // ID fijo para notificación matutina
        'Buenos días',
        '¡Te deseamos un excelente día!, me gustaría saber cómo te sientes!',
        tz.TZDateTime.from(wakeNotificationTime, _local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents:
            DateTimeComponents.time, // Hacer recurrente diariamente
      );

      print('✅ Notificación matutina programada:');
      print('- ID: 9001');
      print(
          '- Hora: ${wakeNotificationTime.hour}:${wakeNotificationTime.minute}');

      // Crear DateTime con la fecha actual y la hora de dormir
      final todaySleepTime = DateTime(
        now.year,
        now.month,
        now.day,
        sleepTime.hour,
        sleepTime.minute,
      );

      // Notificación nocturna (30 minutos antes de dormir)
      final sleepNotificationTime =
          todaySleepTime.subtract(const Duration(minutes: 30));

      await _notifications.zonedSchedule(
        9002, // ID fijo para notificación nocturna
        'Buenas noches',
        '¡Que descanses! me gustaría saber cómo te sentiste hoy!',
        tz.TZDateTime.from(sleepNotificationTime, _local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      print('✅ Notificación nocturna programada:');
      print('- ID: 9002');
      print(
          '- Hora: ${sleepNotificationTime.hour}:${sleepNotificationTime.minute}');
    } catch (e) {
      print('❌ Error programando notificaciones de despertar y dormir: $e');
      rethrow;
    }
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
