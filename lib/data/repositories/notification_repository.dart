import '../../core/network/api_client.dart';
import '../../core/network/paginated.dart';
import '../models/notification.dart';

class NotificationRepository {
  NotificationRepository(this._api);

  final ApiClient _api;

  Future<Paginated<AppNotification>> list({String? cursor}) async {
    final json = await _api.get<Json>(
      '/api/notifications',
      query: {'cursor': cursor, 'limit': 30},
    );
    return Paginated.fromJson(json, AppNotification.fromJson);
  }

  Future<int> unreadCount() async {
    final json = await _api.get<Json>('/api/notifications/unread-count');
    return (json['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> markRead(List<String> ids) =>
      _api.post<Json>('/api/notifications/read', body: {'notificationIds': ids});

  Future<void> markAllRead() => _api.post<Json>('/api/notifications/read-all');

  /// Registers this device's FCM token so the backend can push while the app
  /// is closed. Best-effort: the in-app socket still works without it.
  Future<void> registerPushToken(String token, {required String platform}) =>
      _api.post<Json>(
        '/api/v1/me/push-tokens',
        body: {'token': token, 'platform': platform},
      );

  Future<void> unregisterPushToken(String token) =>
      _api.delete<Json>('/api/v1/me/push-tokens', body: {'token': token});
}
