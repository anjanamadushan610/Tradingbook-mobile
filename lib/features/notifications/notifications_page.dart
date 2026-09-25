import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/di/service_locator.dart';
import '../../core/paging/paged_cubit.dart';
import '../../core/paging/paged_list_view.dart';
import '../../core/router/routes.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/user_builder.dart';
import '../../data/models/notification.dart';
import '../../data/repositories/notification_repository.dart';
import 'notification_center.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _repo = sl<NotificationRepository>();
  late final _list = PagedCubit<AppNotification>((c) => _repo.list(cursor: c), keyOf: (n) => n.id);
  StreamSubscription<AppNotification>? _live;

  @override
  void initState() {
    super.initState();
    _live = context.read<NotificationCenter>().incoming.listen(_list.prepend);
  }

  @override
  void dispose() {
    _live?.cancel();
    _list.close();
    super.dispose();
  }

  Future<void> _open(AppNotification n) async {
    if (!n.isRead) {
      _list.replaceWhere((x) => x.id == n.id, (x) => x.markRead());
      context.read<NotificationCenter>().markedRead(1);
      _repo.markRead([n.id]).catchError((_) {});
    }
    final route = _routeFor(n);
    if (route != null) context.push(route);
  }

  String? _routeFor(AppNotification n) {
    switch (n.type) {
      case 'post_rejected':
        return Routes.myPosts;
      case 'new_follower':
        return Routes.user(n.actorId);
      case 'group_join':
      case 'role_change':
        if (n.groupId != null) return Routes.group(n.groupId!);
        if (n.pageId != null) return Routes.page(n.pageId!);
    }
    if (n.postId != null) return Routes.post(n.postId!);
    if (n.groupId != null) return Routes.group(n.groupId!);
    if (n.pageId != null) return Routes.page(n.pageId!);
    if (n.actorId.isNotEmpty) return Routes.user(n.actorId);
    return null;
  }

  Future<void> _markAll() async {
    final ok = await guard(context, _repo.markAllRead);
    if (!ok || !mounted) return;
    context.read<NotificationCenter>().allRead();
    _list.replaceWhere((_) => true, (n) => n.markRead());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(onPressed: _markAll, child: const Text('Mark all read')),
        ],
      ),
      body: PagedListView<AppNotification>(
        cubit: _list,
        skeletonHeight: 70,
        onRefresh: () => context.read<NotificationCenter>().refreshUnread(),
        itemBuilder: (_, n, _) => _NotificationTile(notification: n, onTap: () => _open(n)),
        empty: const EmptyView(
          icon: Icons.notifications_none_rounded,
          title: 'You\'re all caught up',
          message: 'Likes, comments, new followers and moderation updates show up here.',
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  static (IconData, Color) _iconFor(String type) => switch (type) {
        'like' || 'comment_like' => (Icons.thumb_up_alt_rounded, AppColors.info),
        'comment' => (Icons.mode_comment_rounded, AppColors.primary),
        'new_follower' => (Icons.person_add_alt_1_rounded, AppColors.primaryLight),
        'post_approved' => (Icons.check_circle_rounded, AppColors.success),
        'post_rejected' => (Icons.cancel_rounded, AppColors.error),
        'group_join' => (Icons.groups_rounded, AppColors.warning),
        'role_change' => (Icons.admin_panel_settings_rounded, AppColors.warning),
        'page_post' => (Icons.flag_rounded, AppColors.primary),
        _ => (Icons.notifications_rounded, AppColors.primary),
      };

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final cs = Theme.of(context).colorScheme;
    final (icon, color) = _iconFor(n.type);
    return Material(
      color: n.isRead ? Colors.transparent : AppColors.primary.withValues(alpha: 0.06),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  UserBuilder(
                    userId: n.actorId,
                    builder: (_, u) => AppAvatar(url: u?.avatarUrl, name: u?.displayName ?? n.actorName, size: 44),
                  ),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(color: cs.surface, shape: BoxShape.circle),
                      child: Icon(icon, size: 16, color: color),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.message.isNotEmpty ? n.message : n.actorName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: cs.onSurface,
                        fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(Fmt.relative(n.createdAt), style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              if (!n.isRead)
                Container(
                  margin: const EdgeInsets.only(top: 6, left: 8),
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
