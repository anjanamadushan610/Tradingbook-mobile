import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/di/service_locator.dart';
import '../../core/paging/paged_cubit.dart';
import '../../core/paging/paged_list_view.dart';
import '../../core/router/routes.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/user_builder.dart';
import '../../data/models/moderation.dart';
import '../../data/repositories/moderation_repository.dart';

class ModerationAuditPage extends StatefulWidget {
  const ModerationAuditPage({super.key});

  @override
  State<ModerationAuditPage> createState() => _ModerationAuditPageState();
}

class _ModerationAuditPageState extends State<ModerationAuditPage> {
  late final _log = PagedCubit<AuditEntry>((c) => sl<ModerationRepository>().audit(cursor: c), keyOf: (e) => e.id);

  @override
  void dispose() {
    _log.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Audit log')),
      body: PagedListView<AuditEntry>(
        cubit: _log,
        skeletonHeight: 70,
        separated: true,
        itemBuilder: (_, e, _) {
          final approved = e.action == 'approved';
          return ListTile(
            onTap: () => context.push(Routes.post(e.postId)),
            leading: Icon(
              approved ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: approved ? AppColors.success : AppColors.error,
            ),
            title: UserBuilder(
              userId: e.moderatorId,
              builder: (_, u) => Text(
                '${u?.displayName ?? 'Moderator'} ${e.action} a post',
                style: AppTextStyles.titleSmall.copyWith(color: cs.onSurface),
              ),
            ),
            subtitle: Text(
              '${e.stage} stage · ${e.previousStatus} → ${e.newStatus} · ${Fmt.relative(e.createdAt)}'
              '${e.reason == null ? '' : '\n"${e.reason}"'}',
              style: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant),
            ),
            isThreeLine: e.reason != null,
          );
        },
        empty: const EmptyView(icon: Icons.history_rounded, title: 'No moderation actions yet'),
      ),
    );
  }
}
