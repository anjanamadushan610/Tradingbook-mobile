import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/entities/notification.dart';
import '../../../../domain/repositories/notifications_repository.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationsRepository _repository;

  NotificationsCubit({required NotificationsRepository repository})
      : _repository = repository,
        super(NotificationsInitial());

  Future<void> loadNotifications({bool refresh = false}) async {
    try {
      if (state is NotificationsLoading && !refresh) return;

      String? currentCursor;
      List<AppNotification> currentItems = [];
      int currentUnread = 0;

      if (!refresh && state is NotificationsLoaded) {
        final loaded = state as NotificationsLoaded;
        currentCursor = loaded.nextCursor;
        currentItems = loaded.notifications;
        currentUnread = loaded.unreadCount;
        // If we don't have a nextCursor and we're not refreshing, we're at the end
        if (currentCursor == null && currentItems.isNotEmpty) return;
      } else {
        emit(NotificationsLoading());
      }

      final results = await Future.wait([
        _repository.getNotifications(cursor: refresh ? null : currentCursor, limit: 20),
        _repository.getUnreadCount(),
      ]);

      final fetchResult = results[0] as ({List<AppNotification> items, String? nextCursor});
      final unreadCount = results[1] as int;

      final newItems = refresh 
          ? fetchResult.items 
          : [...currentItems, ...fetchResult.items];

      emit(NotificationsLoaded(
        notifications: List.from(newItems),
        unreadCount: unreadCount,
        nextCursor: fetchResult.nextCursor,
      ));
    } catch (e) {
      emit(NotificationsError(e.toString()));
    }
  }

  Future<void> markAsRead(String notificationId) async {
    if (state is! NotificationsLoaded) return;
    
    final loadedState = state as NotificationsLoaded;
    
    // Optimistic update
    final updatedNotifications = loadedState.notifications.map((n) {
      if (n.id == notificationId && !n.isRead) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    
    final newUnreadCount = (loadedState.unreadCount > 0) ? loadedState.unreadCount - 1 : 0;
    
    emit(loadedState.copyWith(
      notifications: updatedNotifications,
      unreadCount: newUnreadCount,
    ));

    try {
      await _repository.markAsRead([notificationId]);
    } catch (e) {
      // Revert if needed (omitted for brevity, could refetch)
      loadNotifications(refresh: true);
    }
  }

  Future<void> markAllAsRead() async {
    if (state is! NotificationsLoaded) return;
    
    final loadedState = state as NotificationsLoaded;
    
    // Optimistic update
    final updatedNotifications = loadedState.notifications.map((n) {
      return n.copyWith(isRead: true);
    }).toList();
    
    emit(loadedState.copyWith(
      notifications: updatedNotifications,
      unreadCount: 0,
    ));

    try {
      await _repository.markAllAsRead();
    } catch (e) {
      loadNotifications(refresh: true);
    }
  }
}
