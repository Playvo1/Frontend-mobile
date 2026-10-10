/// One entry in the notification inbox, as `GET /notifications` returns it.
///
/// TODO(api): the shape is a best guess — the endpoint has not been shared.
/// Confirm the field names; they are all read in [AppNotification.fromJson].
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.createdAt,
    this.isRead = false,
  });

  final int id;
  final String title;
  final String body;

  /// One of [NotificationType]; decides the icon and colour.
  final String type;

  final DateTime? createdAt;
  final bool isRead;

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final String? raw = json['created_at'] as String?;
    return AppNotification(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? json['message'] as String? ?? '',
      type: json['type'] as String? ?? NotificationType.general,
      createdAt: raw == null ? null : DateTime.tryParse(raw),
      isRead: json['is_read'] as bool? ?? json['read'] as bool? ?? false,
    );
  }
}

/// The kinds the inbox draws differently.
class NotificationType {
  NotificationType._();

  static const String bookingConfirmed = 'booking_confirmed';
  static const String bookingReminder = 'booking_reminder';
  static const String offer = 'offer';
  static const String matchFinished = 'match_finished';
  static const String general = 'general';
}
