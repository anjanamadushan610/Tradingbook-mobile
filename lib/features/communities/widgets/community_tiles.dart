import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/routes.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../data/models/community.dart';

class GroupTile extends StatelessWidget {
  const GroupTile({super.key, required this.group, this.trailing});

  final Group group;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      onTap: () => context.push(Routes.group(group.id)),
      leading: AppAvatar(url: group.avatarUrl, name: group.name, size: 48, square: true),
      title: Text(group.name, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: AppTextStyles.titleMedium.copyWith(color: cs.onSurface)),
      subtitle: Row(
        children: [
          Icon(group.isPrivate ? Icons.lock_outline_rounded : Icons.public_rounded,
              size: 13, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '${group.isPrivate ? 'Private' : 'Public'} · ${Fmt.count(group.memberCount)} member${group.memberCount == 1 ? '' : 's'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
    );
  }
}

class PageTile extends StatelessWidget {
  const PageTile({super.key, required this.page, this.trailing});

  final CommunityPage page;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      onTap: () => context.push(Routes.page(page.id)),
      leading: AppAvatar(url: page.avatarUrl, name: page.name, size: 48, square: true),
      title: Text(page.name, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: AppTextStyles.titleMedium.copyWith(color: cs.onSurface)),
      subtitle: Text(
        '${Fmt.count(page.followerCount)} follower${page.followerCount == 1 ? '' : 's'}'
        '${page.description.isNotEmpty ? ' · ${page.description}' : ''}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
    );
  }
}

/// Compact card for horizontal discovery rails.
class CommunityCard extends StatelessWidget {
  const CommunityCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.avatarUrl,
    required this.coverUrl,
    required this.onTap,
    this.icon,
  });

  final String name;
  final String subtitle;
  final String? avatarUrl;
  final String? coverUrl;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 168,
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.only(right: 10),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  image: coverUrl == null
                      ? null
                      : DecorationImage(image: NetworkImage(coverUrl!), fit: BoxFit.cover),
                ),
              ),
              Transform.translate(
                offset: const Offset(12, -20),
                child: AppAvatar(
                  url: avatarUrl,
                  name: name,
                  size: 44,
                  square: true,
                  borderColor: dark ? AppColors.darkSurface : Colors.white,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Transform.translate(
                  offset: const Offset(0, -12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleMedium.copyWith(color: cs.onSurface)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (icon != null) ...[
                            Icon(icon, size: 12, color: cs.onSurfaceVariant),
                            const SizedBox(width: 3),
                          ],
                          Expanded(
                            child: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
