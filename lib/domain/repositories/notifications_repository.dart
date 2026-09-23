import '../entities/notification.dart';

abstract class NotificationsRepository {
  Future<({List<AppNotification> items, String? nextCursor})> getNotifications({
    String? cursor,
    int limit = 20,
  });
  Future<bool> markAsRead(List<String> notificationIds);
  Future<bool> markAllAsRead();
  Future<int> getUnreadCount();
}
