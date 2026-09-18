import 'package:med_super/features/notifications/domain/entities/app_notification.dart';
import 'package:med_super/features/notifications/domain/utils/notification_deep_link.dart';

class AppNotificationDto {
  const AppNotificationDto({
    required this.id,
    required this.templateCode,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isUnread,
    this.data,
    this.deepLinkRoute,
  });

  factory AppNotificationDto.fromJson(
    Map<String, dynamic> json, {
    required bool isProvider,
  }) {
    final data = json['data'];
    final templateCode =
        (json['templateCode'] ?? json['template_code']) as String? ?? '';
    final parsedData = data is Map<String, dynamic> ? data : null;

    return AppNotificationDto(
      id: json['id'] as String,
      templateCode: templateCode,
      title: json['title'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(
        (json['createdAt'] ?? json['created_at']) as String,
      ),
      isUnread: json['readAt'] == null && json['read_at'] == null,
      data: parsedData,
      deepLinkRoute: notificationDeepLink(
        templateCode: templateCode,
        data: parsedData,
        isProvider: isProvider,
      ),
    );
  }

  final String id;
  final String templateCode;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isUnread;
  final Map<String, dynamic>? data;
  final String? deepLinkRoute;

  AppNotification toEntity() => AppNotification(
    id: id,
    templateCode: templateCode,
    title: title,
    body: body,
    createdAt: createdAt,
    isUnread: isUnread,
    data: data,
    deepLinkRoute: deepLinkRoute,
  );
}

class NotificationListPageDto {
  const NotificationListPageDto({
    required this.items,
    required this.nextCursor,
  });

  factory NotificationListPageDto.fromJson(
    Map<String, dynamic> json, {
    required bool isProvider,
  }) {
    final rawItems =
        (json['notifications'] as List<dynamic>? ??
            json['items'] as List<dynamic>? ??
            const []);
    return NotificationListPageDto(
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map((row) => AppNotificationDto.fromJson(row, isProvider: isProvider))
          .toList(),
      nextCursor: (json['nextCursor'] ?? json['next_cursor']) as String?,
    );
  }

  final List<AppNotificationDto> items;
  final String? nextCursor;

  NotificationListPage toEntity() => NotificationListPage(
    items: items.map((dto) => dto.toEntity()).toList(),
    nextCursor: nextCursor,
  );
}
