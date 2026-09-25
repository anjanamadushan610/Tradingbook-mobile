import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/routes.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/user_builder.dart';
import '../../../data/models/user.dart';
import 'follow_button.dart';

/// A person in a list. Give it a [user] when the list already carries
/// profiles, or just a [userId] (follow lists, members) to hydrate lazily.
class UserTile extends StatelessWidget {
  UserTile({
    super.key,
    this.user,
    String? userId,
    this.subtitle,
    this.trailing,
    this.showFollow = true,
    this.followInitial,
  }) : userId = userId ?? user?.id ?? '';

  final UserProfile? user;
  final String userId;
  final String? subtitle;
  final Widget? trailing;
  final bool showFollow;
  final bool? followInitial;

  @override
  Widget build(BuildContext context) {
    if (user != null) return _tile(context, user);
    return UserBuilder(userId: userId, builder: _tile);
  }

  Widget _tile(BuildContext context, UserProfile? u) {
    final cs = Theme.of(context).colorScheme;
    final name = u?.displayName ?? 'Trader';
    final sub = subtitle ??
        (u == null
            ? null
            : u.followerCount != null
                ? '${Fmt.count(u.followerCount!)} followers${u.bio.isNotEmpty ? ' · ${u.bio}' : ''}'
                : (u.bio.isNotEmpty ? u.bio : null));
    return ListTile(
      onTap: () => context.push(Routes.user(userId)),
      leading: AppAvatar(url: u?.avatarUrl, name: name, size: 44),
      title: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.titleMedium.copyWith(color: cs.onSurface),
      ),
      subtitle: sub == null
          ? null
          : Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant),
            ),
      trailing: trailing ?? (showFollow ? FollowButton(userId: userId, initial: followInitial) : null),
    );
  }
}
