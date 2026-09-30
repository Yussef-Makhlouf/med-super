import 'package:dio/dio.dart';
import 'package:med_super/core/constants/api_paths.dart';
import 'package:med_super/features/notifications/data/models/app_notification_dto.dart';
import 'package:med_super/features/notifications/data/models/notification_preference_dto.dart';
import 'package:med_super/features/notifications/domain/entities/notification_preference.dart';

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

  Future<List<NotificationPreference>> getPreferences() async {
    final response = await _dio.get<List<dynamic>>(
      ApiPaths.notificationPreferences,
    );
    final rows = response.data;
    if (rows == null) {
      throw const FormatException('Missing notification preferences');
    }

    final preferences = <NotificationPreference>[];
    final seenKeys = <String>{};
    for (final row in rows) {
      if (row is! Map<String, dynamic>) {
        throw const FormatException('Malformed notification preference row');
      }
      final preference = NotificationPreferenceDto.fromJson(row).toEntity();
      final key = '${preference.tier}:${preference.channel}';
      if (!seenKeys.add(key)) {
        throw const FormatException('Duplicate notification preference row');
      }
      preferences.add(preference);
    }
    if (preferences.length != 8) {
      throw const FormatException('Incomplete notification preferences');
    }
    return List.unmodifiable(preferences);
  }

  Future<void> updatePreferences(
    List<NotificationPreference> preferences,
  ) async {
    await _dio.put<void>(
      ApiPaths.notificationPreferences,
      data: {
        'preferences': preferences
            .map(NotificationPreferenceDto.fromEntity)
            .map((dto) => dto.toJson())
            .toList(growable: false),
      },
    );
  }
}
