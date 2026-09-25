import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/di/service_locator.dart';
import '../../core/network/api_exception.dart';
import '../../core/paging/paged_cubit.dart';
import '../../core/paging/paged_list_view.dart';
import '../../core/router/routes.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/net_image.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models/community.dart';
import '../../data/models/moderation.dart';
import '../../data/models/post.dart';
import '../../data/repositories/community_repository.dart';
import '../auth/session_cubit.dart';
import '../post/widgets/post_card.dart';
import '../report/report_sheet.dart';

class PageDetailPage extends StatefulWidget {
  const PageDetailPage({super.key, required this.pageId});

  final String pageId;

  @override
  State<PageDetailPage> createState() => _PageDetailPageState();
}

class _PageDetailPageState extends State<PageDetailPage> {
  final _repo = sl<CommunityRepository>();
  late Future<CommunityPage> _page = _repo.page(widget.pageId);
  late final _feed = PagedCubit<Post>((c) => _repo.pageFeed(widget.pageId, cursor: c), keyOf: (p) => p.id);
  bool? _following;
  PageRole? _myRole;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _repo.isFollowingPage(widget.pageId).then((f) {
      if (mounted) setState(() => _following = f);
    }).catchError((_) {
      if (mounted) setState(() => _following = false);
    });
    final me = context.read<SessionCubit>().user?.id;
    _repo.pageRoles(widget.pageId).then((roles) {
      final mine = roles.where((r) => r.userId == me).firstOrNull;
      if (mounted) setState(() => _myRole = mine?.role);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _feed.close();
    super.dispose();
  }

  Future<void> _toggleFollow() async {
    final was = _following ?? false;
    setState(() {
      _busy = true;
      _following = !was;
    });
    try {
      was ? await _repo.unfollowPage(widget.pageId) : await _repo.followPage(widget.pageId);
      setState(() => _page = _repo.page(widget.pageId));
    } catch (e) {
      if (mounted) {
        setState(() => _following = was);
        Toast.error(context, e);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _menu(String action, CommunityPage p) async {
    switch (action) {
      case 'share':
        await SharePlus.instance.share(ShareParams(text: '${p.name} on TradingBook\n${AppConfig.channelUrl(p.id)}'));
      case 'report':
        await showReportSheet(context, target: ReportTarget.page, targetId: p.id);
      case 'delete':
        final ok = await confirmDialog(
          context,
          title: 'Delete ${p.name}?',
          message: 'This permanently removes the page, its team and followers. This can\'t be undone.',
          confirmLabel: 'Delete page',
          destructive: true,
        );
        if (!ok || !mounted) return;
        final done = await guard(context, () => _repo.deletePage(p.id), success: 'Page deleted');
        if (done && mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CommunityPage>(
      future: _page,
      builder: (context, snap) {
        if (snap.hasError) {
          final e = snap.error;
          return Scaffold(
            appBar: AppBar(),
            body: e is ApiException && e.isNotFound
                ? const EmptyView(icon: Icons.flag_outlined, title: 'Page not found', message: 'It may have been deleted.')
                : ErrorView(error: e, onRetry: () => setState(() => _page = _repo.page(widget.pageId))),
          );
        }
        final page = snap.data;
        if (page == null) return Scaffold(appBar: AppBar(), body: const LoadingView());
        final manager = _myRole != null;
        return Scaffold(
          appBar: AppBar(
            title: Text(page.name),
            actions: [
              PopupMenuButton<String>(
                onSelected: (a) => _menu(a, page),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'share', child: Text('Share page')),
                  if (!manager) const PopupMenuItem(value: 'report', child: Text('Report page')),
                  if (_myRole == PageRole.owner) const PopupMenuItem(value: 'delete', child: Text('Delete page')),
                ],
              ),
            ],
          ),
          floatingActionButton: manager
              ? FloatingActionButton.extended(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  onPressed: () async {
                    final posted = await context.push<bool>(Routes.compose(pageId: page.id));
                    if (posted == true) _feed.refresh();
                  },
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Post as page'),
                )
              : null,
          body: PagedListView<Post>(
            cubit: _feed,
            onRefresh: () async => setState(() => _page = _repo.page(widget.pageId)),
            headerSlivers: [
              SliverToBoxAdapter(
                child: _PageHeader(
                  page: page,
                  actions: [
                    if (_myRole != PageRole.owner)
                      AppButton.small(
                        label: _following == true ? 'Following' : 'Follow',
                        style: _following == true ? AppButtonStyle.outlined : AppButtonStyle.primary,
                        isLoading: _busy,
                        onPressed: _following == null ? null : _toggleFollow,
                      ),
                    if (_myRole == PageRole.owner || _myRole == PageRole.admin) ...[
                      AppButton.small(
                        label: 'Edit',
                        icon: Icons.settings_outlined,
                        style: AppButtonStyle.subtle,
                        onPressed: () async {
                          await context.push(Routes.editPage(page.id));
                          setState(() => _page = _repo.page(widget.pageId));
                        },
                      ),
                      AppButton.small(
                        label: 'Team',
                        icon: Icons.badge_outlined,
                        style: AppButtonStyle.subtle,
                        onPressed: () => context.push(Routes.pageTeam(page.id)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            itemBuilder: (_, p, _) => PostCard(
              key: ValueKey(p.id),
              post: p,
              contextType: 'page',
              onDeleted: () => _feed.removeWhere((x) => x.id == p.id),
            ),
            empty: const EmptyView(icon: Icons.article_outlined, title: 'No posts yet'),
          ),
        );
      },
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.page, required this.actions});

  final CommunityPage page;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: cs.surface,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 170,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  bottom: 36,
                  child: page.coverUrl == null
                      ? Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient))
                      : NetImage(url: page.coverUrl!),
                ),
                Positioned(
                  left: 16,
                  bottom: 0,
                  child: AppAvatar(
                    url: page.avatarUrl,
                    name: page.name,
                    size: 76,
                    square: true,
                    borderColor: dark ? AppColors.darkSurface : Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(page.name, style: AppTextStyles.headlineLarge.copyWith(color: cs.onSurface)),
                const SizedBox(height: 4),
                Text(
                  '${Fmt.count(page.followerCount)} follower${page.followerCount == 1 ? '' : 's'}',
                  style: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant),
                ),
                if (page.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(page.description, style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface)),
                ],
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: actions),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
