import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/entities/notification.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../widgets/app_avatar.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  int _filterIndex = 0;
  final _filters = ['All', 'Mentions', 'Trades'];

  @override
  void initState() {
    super.initState();
    // Fetch notifications on init if not already loaded/loading
    context.read<NotificationsCubit>().loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildHeader(),
            _buildFilterTabs(),
            Expanded(
              child: BlocBuilder<NotificationsCubit, NotificationsState>(
                builder: (context, state) {
                  if (state is NotificationsLoading && state is! NotificationsLoaded) {
                    return _buildLoadingState();
                  } else if (state is NotificationsError) {
                    return Center(child: Text(state.message, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)));
                  } else if (state is NotificationsLoaded) {
                    final notifications = _getFilteredNotifications(state.notifications);
                    
                    if (notifications.isEmpty) {
                      return _buildEmptyState();
                    }

                    return RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => context.read<NotificationsCubit>().loadNotifications(refresh: true),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notification = notifications[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _NotificationTile(
                              notification: notification,
                              onTap: () {
                                if (!notification.isRead) {
                                  context.read<NotificationsCubit>().markAsRead(notification.id);
                                }
                              },
                            ),
                          );
                        },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<AppNotification> _getFilteredNotifications(List<AppNotification> all) {
    // Implement simple filtering based on _filterIndex
    if (_filterIndex == 1) { // Mentions
      return all.where((n) => n.type == NotificationType.comment).toList();
    } else if (_filterIndex == 2) { // Trades
      return all.where((n) => n.type == NotificationType.pagePost || n.type == NotificationType.postApproved).toList();
    }
    return all;
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Row(
            children: [
               Icon(Icons.bar_chart_rounded, color: AppColors.success, size: 28),
               const SizedBox(width: 6),
               Text('TradingBook', style: AppTextStyles.headlineSmall.copyWith(
                 color: const Color(0xFF00647C),
                 fontWeight: FontWeight.bold,
               )),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF475569)),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Color(0xFF475569)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Row(
            children: [
              Text('Notifications', style: AppTextStyles.headlineMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              )),
              BlocBuilder<NotificationsCubit, NotificationsState>(
                builder: (context, state) {
                  int unreadCount = 0;
                  if (state is NotificationsLoaded) {
                    unreadCount = state.unreadCount;
                  }
                  
                  if (unreadCount > 0) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00647C),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              context.read<NotificationsCubit>().markAllAsRead();
            },
            child: Row(
              children: [
                const Icon(Icons.done_all_rounded,
                    size: 16, color: Color(0xFF00647C)),
                const SizedBox(width: 4),
                Text('Mark all read',
                    style: AppTextStyles.titleSmall
                        .copyWith(color: const Color(0xFF00647C), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: _filters.asMap().entries.map((entry) {
          final isSelected = entry.key == _filterIndex;
          return GestureDetector(
            onTap: () {
              setState(() {
                _filterIndex = entry.key;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF00647C) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected ? null : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                entry.value,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 12, width: 120, color: Colors.grey.withValues(alpha: 0.2)),
                      const SizedBox(height: 8),
                      Container(height: 12, width: double.infinity, color: Colors.grey.withValues(alpha: 0.2)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: AppTextStyles.titleMedium.copyWith(color: const Color(0xFF64748B), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'When you get notifications, they\'ll show up here.',
            style: AppTextStyles.bodyMedium.copyWith(color: const Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  String _formatTimeAgo(int createdAt) {
    // Ensure we handle milliseconds. If it's a 10-digit number, it's seconds.
    final timestampStr = createdAt.toString();
    final isSeconds = timestampStr.length <= 10;
    final date = DateTime.fromMillisecondsSinceEpoch(isSeconds ? createdAt * 1000 : createdAt);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 1) {
      return '${difference.inDays}d';
    } else if (difference.inDays == 1) {
      return '1d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  bool get _hasAction => notification.type == NotificationType.newFollower || notification.type == NotificationType.groupJoin;
  
  String get _actionLabel {
    if (notification.type == NotificationType.newFollower) return 'Follow back';
    if (notification.type == NotificationType.groupJoin) return 'Join conversation →';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: notification.isRead ? null : Border.all(color: const Color(0xFF00647C).withValues(alpha: 0.2), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAvatarOrIcon(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(notification.actorName,
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            )),
                      ),
                      Text(_formatTimeAgo(notification.createdAt), style: AppTextStyles.caption.copyWith(color: const Color(0xFF94A3B8))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(notification.message,
                      style: AppTextStyles.bodyMedium.copyWith(color: const Color(0xFF64748B))),
                  
                  if (_hasAction) ...[
                    const SizedBox(height: 12),
                    if (notification.type == NotificationType.groupJoin)
                       GestureDetector(
                         onTap: (){},
                         child: Text(_actionLabel, style: AppTextStyles.labelMedium.copyWith(color: const Color(0xFF00647C), fontWeight: FontWeight.bold)),
                       )
                    else
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                         decoration: BoxDecoration(
                           color: const Color(0xFF00647C),
                           borderRadius: BorderRadius.circular(20),
                         ),
                         child: Text(_actionLabel,
                             style: AppTextStyles.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                       ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarOrIcon() {
    if (notification.actorAvatarUrl != null || notification.actorName.isNotEmpty) {
      // Use AppAvatar which handles initials fallback automatically if imageUrl is null
      return Stack(
        children: [
          AppAvatar(imageUrl: notification.actorAvatarUrl, name: notification.actorName, size: 48),
          Positioned(
            bottom: -2, right: -2,
            child: _buildBadge(),
          ),
        ],
      );
    } else {
      IconData mainIcon;
      Color bgColor;
      Color iconColor;
      
      switch (notification.type) {
        case NotificationType.like:
          mainIcon = Icons.favorite_rounded;
          bgColor = const Color(0xFFFCE8E8); // Light red
          iconColor = const Color(0xFFDC2626); // Red
          break;
        case NotificationType.groupJoin:
          mainIcon = Icons.groups_rounded;
          bgColor = const Color(0xFFE0E7FF); // Light indigo
          iconColor = const Color(0xFF3730A3); // Indigo
          break;
        case NotificationType.postApproved:
        case NotificationType.postRejected:
          mainIcon = Icons.notifications_none_rounded;
          bgColor = const Color(0xFFE0F2FE); // Light sky blue
          iconColor = const Color(0xFF0369A1); // Sky blue
          break;
        default:
          mainIcon = Icons.info_outline_rounded;
          bgColor = const Color(0xFFF1F5F9);
          iconColor = const Color(0xFF475569);
      }

      return Stack(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(mainIcon, size: 24, color: iconColor),
          ),
          if (notification.type == NotificationType.postApproved || notification.type == NotificationType.postRejected) 
             Positioned(
              bottom: -2, right: -2,
              child: _buildBadge(),
            ),
        ],
      );
    }
  }

  Widget _buildBadge() {
    IconData badgeIcon;
    Color badgeBg;
    
    switch (notification.type) {
      case NotificationType.newFollower:
        badgeIcon = Icons.person_add_rounded;
        badgeBg = const Color(0xFF00647C); // Blue
        break;
      case NotificationType.comment:
        badgeIcon = Icons.chat_bubble_rounded;
        badgeBg = const Color(0xFF94A3B8); // Gray
        break;
      case NotificationType.pagePost:
        badgeIcon = Icons.show_chart_rounded;
        badgeBg = const Color(0xFF00647C); // Blue
        break;
      case NotificationType.postApproved:
      case NotificationType.postRejected:
        badgeIcon = Icons.trending_up_rounded;
        badgeBg = const Color(0xFF00647C); // Blue
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      width: 20, height: 20,
      decoration: BoxDecoration(
        color: badgeBg, 
        shape: BoxShape.circle, 
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Icon(badgeIcon, size: 10, color: Colors.white),
    );
  }
}
