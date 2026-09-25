import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/di/service_locator.dart';
import '../../core/paging/paged_cubit.dart';
import '../../core/paging/paged_list_view.dart';
import '../../core/router/routes.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/user_builder.dart';
import '../../data/models/moderation.dart';
import '../../data/repositories/moderation_repository.dart';

/// Reports filed by users. Moderators open the target, act on it through the
/// normal tools, then resolve or dismiss the report.
class ModerationReportsPage extends StatefulWidget {
  const ModerationReportsPage({super.key});

  @override
  State<ModerationReportsPage> createState() => _ModerationReportsPageState();
}

class _ModerationReportsPageState extends State<ModerationReportsPage> {
  final _repo = sl<ModerationRepository>();
  String _status = 'open';
  late PagedCubit<ContentReport> _reports = _build();

  PagedCubit<ContentReport> _build() =>
      PagedCubit<ContentReport>((c) => _repo.reports(status: _status, cursor: c), keyOf: (r) => r.id);

  @override
  void dispose() {
    _reports.close();
    super.dispose();
  }

  String? _routeFor(ContentReport r) => switch (r.targetType) {
        'post' => Routes.post(r.targetId),
        'user' => Routes.user(r.targetId),
        'group' => Routes.group(r.targetId),
        'page' => Routes.page(r.targetId),
        _ => null,
      };

  Future<void> _resolve(ContentReport r, String status) async {
    final ok = await guard(context, () => _repo.resolveReport(r.id, status: status),
        success: status == 'resolved' ? 'Marked resolved' : 'Dismissed');
    if (ok) _reports.removeWhere((x) => x.id == r.id);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('User reports')),
      body: PagedListView<ContentReport>(
        key: ValueKey(_status),
        cubit: _reports,
        skeletonHeight: 90,
        separated: true,
        headerSlivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'open', label: Text('Open')),
                  ButtonSegment(value: 'resolved', label: Text('Resolved')),
                  ButtonSegment(value: 'dismissed', label: Text('Dismissed')),
                ],
                selected: {_status},
                onSelectionChanged: (s) {
                  _reports.close();
                  setState(() {
                    _status = s.first;
                    _reports = _build();
                  });
                },
              ),
            ),
          ),
        ],
        itemBuilder: (_, r, _) {
          final reason = ReportReason.values.where((x) => x.wire == r.reason).firstOrNull?.label ?? r.reason;
          final route = _routeFor(r);
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(r.targetType.toUpperCase(),
                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.error)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(reason, style: AppTextStyles.titleMedium.copyWith(color: cs.onSurface))),
                    Text(Fmt.relative(r.createdAt), style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
                if (r.details != null) ...[
                  const SizedBox(height: 6),
                  Text(r.details!, style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface)),
                ],
                const SizedBox(height: 4),
                UserBuilder(
                  userId: r.reporterId,
                  builder: (_, u) => Text('Reported by ${u?.displayName ?? 'a user'}',
                      style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant)),
                ),
                Row(
                  children: [
                    if (route != null)
                      TextButton.icon(
                        onPressed: () => context.push(route),
                        icon: const Icon(Icons.open_in_new_rounded, size: 16),
                        label: const Text('Open'),
                      ),
                    const Spacer(),
                    if (_status == 'open') ...[
                      TextButton(onPressed: () => _resolve(r, 'dismissed'), child: const Text('Dismiss')),
                      FilledButton(onPressed: () => _resolve(r, 'resolved'), child: const Text('Resolved')),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
        empty: const EmptyView(icon: Icons.flag_outlined, title: 'No reports here'),
      ),
    );
  }
}
