import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xenify/data/notification_service.dart';

final notificationServiceProvider = Provider((ref) => NotificationService());
