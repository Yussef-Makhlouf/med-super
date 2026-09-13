/// A row from `GET /v1/notifications` — self-scoped to the caller.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.templateCode,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isUnread,
    this.data,
    this.deepLinkRoute,
  });

  final String id;
  final String templateCode;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isUnread;
  final Map<String, dynamic>? data;
  final String? deepLinkRoute;

  AppNotification copyWith({
    String? id,
    String? templateCode,
    String? title,
    String? body,
    DateTime? createdAt,
    bool? isUnread,
    Map<String, dynamic>? data,
    String? deepLinkRoute,
  }) {
    return AppNotification(
      id: id ?? this.id,
      templateCode: templateCode ?? this.templateCode,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      isUnread: isUnread ?? this.isUnread,
      data: data ?? this.data,
      deepLinkRoute: deepLinkRoute ?? this.deepLinkRoute,
    );
  }
}

class NotificationListPage {
  const NotificationListPage({required this.items, required this.nextCursor});

  final List<AppNotification> items;
  final String? nextCursor;

  bool get hasMore => nextCursor != null;
}
