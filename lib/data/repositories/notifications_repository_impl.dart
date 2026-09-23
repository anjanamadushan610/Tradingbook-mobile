import '../../core/constants/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../models/notification_model.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final DioClient _client;

  NotificationsRepositoryImpl({required DioClient client}) : _client = client;

  @override
  Future<({List<AppNotification> items, String? nextCursor})>
      getNotifications({String? cursor, int limit = 20}) async {
    final params = <String, dynamic>{'limit': limit};
    if (cursor != null) params['cursor'] = cursor;

    final response = await _client.get(
      ApiEndpoints.notifications,
      queryParameters: params,
    );
    final data = response.data as Map<String, dynamic>;
    final items = (data['items'] as List)
        .map((e) =>
            NotificationModel.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
    return (items: items, nextCursor: data['nextCursor'] as String?);
  }

  @override
  Future<bool> markAsRead(List<String> notificationIds) async {
    final response = await _client.post(
      ApiEndpoints.notificationsRead,
      data: {'notificationIds': notificationIds},
    );
    return (response.data as Map<String, dynamic>)['success'] as bool;
  }

  @override
  Future<bool> markAllAsRead() async {
    final response = await _client.post(ApiEndpoints.notificationsReadAll);
    return (response.data as Map<String, dynamic>)['success'] as bool;
  }

  @override
  Future<int> getUnreadCount() async {
    final response = await _client.get(ApiEndpoints.notificationsUnreadCount);
    return (response.data as Map<String, dynamic>)['count'] as int;
  }
}
