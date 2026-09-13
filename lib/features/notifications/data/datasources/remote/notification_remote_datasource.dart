import 'package:dio/dio.dart';
import 'package:med_super/core/constants/api_paths.dart';
import 'package:med_super/features/notifications/data/models/app_notification_dto.dart';

class NotificationRemoteDatasource {
  NotificationRemoteDatasource(this._dio, {required this.isProvider});

  final Dio _dio;
  final bool isProvider;

  Future<NotificationListPageDto> list({
    bool unreadOnly = false,
    String? cursor,
    int? limit,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.notifications,
      queryParameters: {
        if (unreadOnly) 'unreadOnly': true,
        if (cursor != null) 'cursor': cursor,
        if (limit != null) 'limit': limit,
      },
    );
    return NotificationListPageDto.fromJson(
      response.data ?? const <String, dynamic>{},
      isProvider: isProvider,
    );
  }

  Future<void> markRead(String id) async {
    await _dio.patch<Map<String, dynamic>>(
      '${ApiPaths.notifications}/$id/read',
    );
  }
}
