import '../../domain/entities/doctor_notification.dart';

class DoctorNotificationDto {
  const DoctorNotificationDto({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.createdAt,
    required this.isUnread,
    this.deepLinkRoute,
  });

  factory DoctorNotificationDto.fromJson(Map<String, dynamic> json) {
    return DoctorNotificationDto(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isUnread: json['is_unread'] as bool? ?? true,
      deepLinkRoute: json['deep_link_route'] as String?,
    );
  }

  final String id;
  final String type;
  final String title;
  final String subtitle;
  final DateTime createdAt;
  final bool isUnread;
  final String? deepLinkRoute;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'subtitle': subtitle,
        'created_at': createdAt.toIso8601String(),
        'is_unread': isUnread,
        'deep_link_route': deepLinkRoute,
      };

  DoctorNotification toEntity() {
    return DoctorNotification(
      id: id,
      type: switch (type) {
        'appointmentConfirmed' => NotificationType.appointmentConfirmed,
        'labReportReady' => NotificationType.labReportReady,
        'reminder' => NotificationType.reminder,
        _ => NotificationType.newBookingRequest,
      },
      title: title,
      subtitle: subtitle,
      createdAt: createdAt,
      isUnread: isUnread,
      deepLinkRoute: deepLinkRoute,
    );
  }
}
