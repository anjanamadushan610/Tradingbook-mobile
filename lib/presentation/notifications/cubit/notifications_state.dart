import 'package:equatable/equatable.dart';
import '../../../../domain/entities/notification.dart';

abstract class NotificationsState extends Equatable {
  const NotificationsState();

  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {}

class NotificationsLoading extends NotificationsState {}

class NotificationsLoaded extends NotificationsState {
  final List<AppNotification> notifications;
  final int unreadCount;
  final String? nextCursor;

  const NotificationsLoaded({
    required this.notifications,
    required this.unreadCount,
    this.nextCursor,
  });

  NotificationsLoaded copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
    String? nextCursor,
  }) {
    return NotificationsLoaded(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      nextCursor: nextCursor ?? this.nextCursor,
    );
  }

  @override
  List<Object?> get props => [notifications, unreadCount, nextCursor];
}

class NotificationsError extends NotificationsState {
  final String message;

  const NotificationsError(this.message);

  @override
  List<Object?> get props => [message];
}
