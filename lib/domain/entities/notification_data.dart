class NotificationData {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledDate;
  final String type; // 'medication', 'supplement', 'reminder', 'post_meal'
  final Map<String, dynamic>? payload;
  final Duration? repeatInterval; // Nuevo campo para notificaciones periódicas
  final String? notificationChannel; // Nuevo campo para especificar el canal

  NotificationData({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
    required this.type,
    this.payload,
    this.repeatInterval,
    this.notificationChannel,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'scheduledDate': scheduledDate.toIso8601String(),
      'type': type,
      'payload': payload,
      'repeatInterval': repeatInterval?.inSeconds,
      'notificationChannel': notificationChannel,
    };
  }

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      scheduledDate: DateTime.parse(json['scheduledDate']),
      type: json['type'],
      payload: json['payload'],
      repeatInterval: json['repeatInterval'] != null
          ? Duration(seconds: json['repeatInterval'])
          : null,
      notificationChannel: json['notificationChannel'],
    );
  }
}
