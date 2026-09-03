enum NotificationType {
  newBookingRequest,
  appointmentConfirmed,
  labReportReady,
  reminder,
}

class DoctorNotification {
  const DoctorNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.createdAt,
    required this.isUnread,
    this.deepLinkRoute,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String subtitle;
  final DateTime createdAt;
  final bool isUnread;
  final String? deepLinkRoute;

  DoctorNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? subtitle,
    DateTime? createdAt,
    bool? isUnread,
    String? deepLinkRoute,
  }) {
    return DoctorNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      createdAt: createdAt ?? this.createdAt,
      isUnread: isUnread ?? this.isUnread,
      deepLinkRoute: deepLinkRoute ?? this.deepLinkRoute,
    );
  }
}
