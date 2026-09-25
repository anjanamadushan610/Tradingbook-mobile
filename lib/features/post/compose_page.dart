import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/di/service_locator.dart';
import '../../core/utils/image_prep.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/feedback.dart';
import '../../data/models/community.dart';
import '../../data/models/post.dart';
import '../../data/repositories/community_repository.dart';
import '../../data/repositories/media_repository.dart';
import '../../data/repositories/post_repository.dart';
import '../auth/session_cubit.dart';
import 'widgets/post_menu.dart';

/// Where a post is published. Personal posts go to platform review; group
/// posts to the group's moderators first; page posts straight to platform
/// review.
sealed class _Target {
  const _Target();
}

class _Personal extends _Target {
  const _Personal();
}

class _ToGroup extends _Target {
  const _ToGroup(this.group);
  final Group group;
}

class _ToPage extends _Target {
  const _ToPage(this.page);
  final CommunityPage page;
}

class ComposePage extends StatefulWidget {
  const ComposePage({super.key, this.groupId, this.pageId});

  final String? groupId;
  final String? pageId;

  @override
  State<ComposePage> createState() => _ComposePageState();
}

class _ComposePageState extends State<ComposePage> {
  final _caption = TextEditingController();
  _Target _target = const _Personal();
  PostVisibility _visibility = PostVisibility.public;
  String _language = 'en';
  final List<File> _images = [];
  File? _video;
  String? _step;
  double? _progress;
  List<Group> _groups = const [];
  List<CommunityPage> _pages = const [];

  static const _languages = {'en': 'English', 'si': 'සිංහල', 'ta': 'தமிழ்'};

  @override
  void initState() {
    super.initState();
    _caption.addListener(() => setState(() {}));
    _loadTargets();
  }

  Future<void> _loadTargets() async {
    final repo = sl<CommunityRepository>();
    try {
      final (groups, pages) = await (repo.myGroups(limit: 100), repo.myPages(limit: 50)).wait;
      if (!mounted) return;
      setState(() {
        _groups = groups.items;
        _pages = pages.items;
        if (widget.groupId != null) {
          final g = _groups.where((g) => g.id == widget.groupId).firstOrNull;
          if (g != null) _target = _ToGroup(g);
        } else if (widget.pageId != null) {
          final p = _pages.where((p) => p.id == widget.pageId).firstOrNull;
          if (p != null) _target = _ToPage(p);
        }
      });
    } catch (_) {
      // Posting personally still works without the lists.
    }
  }

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  bool get _busy => _step != null;

  bool get _canPost =>
      !_busy && (_caption.text.trim().isNotEmpty) && _caption.text.length <= 5000;

  Future<void> _pickImages() async {
    try {
      final files = await ImagePrep.pickMany(limit: 10 - _images.length);
      if (files.isEmpty) return;
      setState(() {
        _video = null;
        _images.addAll(files.take(10 - _images.length));
      });
    } catch (e) {
      if (mounted) Toast.show(context, 'Couldn\'t open your photos.', error: true);
    }
  }

  Future<void> _takePhoto() async {
    try {
      final file = await ImagePrep.pickOne(source: ImageSource.camera);
      if (file == null || _images.length >= 10) return;
      setState(() {
        _video = null;
        _images.add(file);
      });
    } catch (_) {
      if (mounted) Toast.show(context, 'Couldn\'t open the camera.', error: true);
    }
  }

  Future<void> _pickVideo() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() {
      _images.clear();
      _video = File(picked.path);
    });
  }

  Future<void> _submit() async {
    if (!_canPost) return;
    FocusScope.of(context).unfocus();
    final posts = sl<PostRepository>();
    final media = sl<MediaRepository>();
    final type = _video != null
        ? PostType.video
        : _images.isNotEmpty
            ? PostType.image
            : PostType.text;
    final target = _target;
    try {
      setState(() => _step = 'Creating post…');
      final draft = await posts.createDraft(
        type: type,
        caption: _caption.text,
        // Community posts take their audience from the community.
        visibility: target is _Personal ? _visibility : PostVisibility.public,
        language: _language,
        imageCount: _images.length,
      );
      if (type == PostType.image) {
        setState(() => _step = 'Uploading ${_images.length} image${_images.length == 1 ? '' : 's'}…');
        await media.uploadPostImages(
          postId: draft.id,
          files: _images,
          onProgress: (p) => mounted ? setState(() => _progress = p) : null,
        );
      } else if (type == PostType.video) {
        setState(() => _step = 'Uploading video…');
        await media.uploadPostVideo(
          postId: draft.id,
          file: _video!,
          contentType: 'video/mp4',
          onProgress: (p) => mounted ? setState(() => _progress = p) : null,
        );
      }
      setState(() {
        _step = 'Submitting…';
        _progress = null;
      });
      switch (target) {
        case _Personal():
          // Video posts enter review automatically once transcoding finishes.
          if (type != PostType.video) await posts.submitForReview(draft.id);
        case _ToGroup(:final group):
          await posts.submitToGroup(group.id, draft.id);
        case _ToPage(:final page):
          await posts.submitToPage(page.id, draft.id);
      }
      if (!mounted) return;
      Toast.show(context, switch (target) {
        _ToGroup() => 'Sent to the group\'s moderators for approval.',
        _ => 'Posted! It\'ll appear once our moderators approve it.',
      });
      context.pop(true);
    } catch (e) {
      if (mounted) Toast.error(context, e);
    } finally {
      if (mounted) {
        setState(() {
          _step = null;
          _progress = null;
        });
      }
    }
  }

  Future<void> _chooseTarget() async {
    final picked = await showModalBottomSheet<_Target>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        final me = ctx.read<SessionCubit>().user;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          builder: (_, controller) => ListView(
            controller: controller,
            children: [
              ListTile(
                leading: AppAvatar(url: me?.avatarUrl, name: me?.displayName, size: 36),
                title: const Text('Your profile'),
                subtitle: const Text('Personal post'),
                onTap: () => Navigator.pop(ctx, const _Personal()),
              ),
              if (_pages.isNotEmpty) const _SheetHeader('Pages you manage'),
              for (final p in _pages)
                ListTile(
                  leading: AppAvatar(url: p.avatarUrl, name: p.name, size: 36, square: true),
                  title: Text(p.name),
                  onTap: () => Navigator.pop(ctx, _ToPage(p)),
                ),
              if (_groups.isNotEmpty) const _SheetHeader('Your groups'),
              for (final g in _groups)
                ListTile(
                  leading: AppAvatar(url: g.avatarUrl, name: g.name, size: 36, square: true),
                  title: Text(g.name),
                  subtitle: Text(g.isPrivate ? 'Private group' : 'Public group'),
                  onTap: () => Navigator.pop(ctx, _ToGroup(g)),
                ),
            ],
          ),
        );
      },
    );
    if (picked != null) setState(() => _target = picked);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final me = context.select((SessionCubit s) => s.state.userOrNull);
    final (String targetName, String? targetAvatar, bool squareAvatar) = switch (_target) {
      _Personal() => (me?.displayName ?? 'You', me?.avatarUrl, false),
      _ToGroup(:final group) => (group.name, group.avatarUrl, true),
      _ToPage(:final page) => (page.name, page.avatarUrl, true),
    };

    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close_rounded),
            onPressed: _busy ? null : () => context.pop(),
          ),
          title: const Text('Create post'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton(
                onPressed: _canPost ? _submit : null,
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Post'),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            if (_busy)
              LinearProgressIndicator(value: _progress, minHeight: 3),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      AppAvatar(url: targetAvatar, name: targetName, size: 44, square: squareAvatar),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: _busy || (_groups.isEmpty && _pages.isEmpty) ? null : _chooseTarget,
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      targetName,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.titleLarge.copyWith(color: cs.onSurface),
                                    ),
                                  ),
                                  if (_groups.isNotEmpty || _pages.isNotEmpty)
                                    const Icon(Icons.arrow_drop_down_rounded),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                if (_target is _Personal)
                                  _Chip(
                                    icon: visibilityIcon(_visibility),
                                    label: _visibility.label,
                                    onTap: _busy ? null : _chooseVisibility,
                                  ),
                                _Chip(
                                  icon: Icons.translate_rounded,
                                  label: _languages[_language]!,
                                  onTap: _busy ? null : _chooseLanguage,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _caption,
                    enabled: !_busy,
                    autofocus: true,
                    maxLines: null,
                    minLines: 6,
                    maxLength: 5000,
                    textCapitalization: TextCapitalization.sentences,
                    style: AppTextStyles.bodyLarge.copyWith(fontSize: 17, color: cs.onSurface),
                    decoration: const InputDecoration(
                      hintText: 'What\'s your read on the market? Use #tags like #BTC',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                  ),
                  if (_images.isNotEmpty) _imageGrid(),
                  if (_video != null)
                    ListTile(
                      leading: const Icon(Icons.videocam_rounded),
                      title: Text(_video!.uri.pathSegments.last, overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        tooltip: 'Remove video',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: _busy ? null : () => setState(() => _video = null),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    'Every post is reviewed by moderators before it goes live. '
                    'Share analysis, not financial advice.',
                    style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5))),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Add photos',
                      onPressed: _busy || _images.length >= 10 ? null : _pickImages,
                      icon: const Icon(Icons.photo_library_outlined, color: AppColors.bullish),
                    ),
                    IconButton(
                      tooltip: 'Take photo',
                      onPressed: _busy || _images.length >= 10 ? null : _takePhoto,
                      icon: const Icon(Icons.photo_camera_outlined, color: AppColors.info),
                    ),
                    if (AppConfig.videoUploadsEnabled && _target is! _ToGroup)
                      IconButton(
                        tooltip: 'Add video',
                        onPressed: _busy ? null : _pickVideo,
                        icon: const Icon(Icons.videocam_outlined, color: AppColors.bearish),
                      ),
                    const Spacer(),
                    if (_images.isNotEmpty)
                      Text('${_images.length}/10', style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant)),
                    const SizedBox(width: 8),
                    if (_step != null)
                      Text(_step!, style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant)),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _images.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemBuilder: (_, i) => Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(_images[i], fit: BoxFit.cover, cacheWidth: 400),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: _busy ? null : () => setState(() => _images.removeAt(i)),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _chooseVisibility() async {
    final v = await showModalBottomSheet<PostVisibility>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final v in PostVisibility.values)
              ListTile(
                leading: Icon(visibilityIcon(v)),
                title: Text(v.label),
                subtitle: Text(visibilityHint(v)),
                trailing: v == _visibility ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
                onTap: () => Navigator.pop(ctx, v),
              ),
          ],
        ),
      ),
    );
    if (v != null) setState(() => _visibility = v);
  }

  Future<void> _chooseLanguage() async {
    final l = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final e in _languages.entries)
              ListTile(
                title: Text(e.value),
                trailing: e.key == _language ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
                onTap: () => Navigator.pop(ctx, e.key),
              ),
          ],
        ),
      ),
    );
    if (l != null) setState(() => _language = l);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(label, style: AppTextStyles.labelMedium.copyWith(color: cs.onSurface)),
            Icon(Icons.arrow_drop_down_rounded, size: 18, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          text.toUpperCase(),
          style: AppTextStyles.labelMedium.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
}
