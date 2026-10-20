import 'package:flutter/material.dart';

import '../../../core/utils/media_urls.dart';
import '../../../core/widgets/net_image.dart';
import '../../../data/models/post.dart';

/// A single image, a collage (2, 3, or 2×2 with a "+N" tile for more), or the
/// video placeholder. Tapping an image opens the zoomable full-screen viewer
/// at that image, where every image can be swiped.
class PostMedia extends StatelessWidget {
  const PostMedia({super.key, required this.post});

  final Post post;

  static const _gap = 2.0;

  @override
  Widget build(BuildContext context) {
    final refs = post.mediaRefs.where((r) => r != 'pending').toList();
    if (refs.isEmpty) return const SizedBox.shrink();

    if (post.type == PostType.video) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_circle_outline_rounded, color: Colors.white, size: 56),
              const SizedBox(height: 8),
              Text('Video', style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
            ],
          ),
        ),
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    Widget tile(int i, {double share = 1, int more = 0}) => _Tile(
          ref: refs[i],
          cacheWidth: (width * share * dpr).round(),
          more: more,
          onTap: () => openImageViewer(context, refs, i),
        );

    // ClipRRect with top-only radius so the image blends into the card top corners.
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: switch (refs.length) {
        1 => AspectRatio(aspectRatio: 4 / 3, child: tile(0)),
        2 => AspectRatio(
            aspectRatio: 4 / 3,
            child: _row([tile(0, share: .5), tile(1, share: .5)]),
          ),
        3 => AspectRatio(
            aspectRatio: 1,
            child: _row([
              tile(0, share: .5),
              _column([tile(1, share: .5), tile(2, share: .5)]),
            ]),
          ),
        _ => AspectRatio(
            aspectRatio: 1,
            child: _column([
              _row([tile(0, share: .5), tile(1, share: .5)]),
              _row([tile(2, share: .5), tile(3, share: .5, more: refs.length - 4)]),
            ]),
          ),
      },
    );
  }

  static Widget _row(List<Widget> children) => Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: _gap),
            Expanded(child: children[i]),
          ],
        ],
      );

  static Widget _column(List<Widget> children) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: _gap),
            Expanded(child: children[i]),
          ],
        ],
      );
}

class _Tile extends StatelessWidget {
  const _Tile({required this.ref, required this.cacheWidth, required this.onTap, this.more = 0});

  final String ref;
  final int cacheWidth;
  final VoidCallback onTap;

  /// Images beyond the four shown; drawn as a "+N" overlay when > 0.
  final int more;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          NetImage(
            url: MediaUrls.image(ref),
            fallbackUrl: MediaUrls.original(ref),
            fit: BoxFit.cover,
            memCacheWidth: cacheWidth,
          ),
          if (more > 0)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              alignment: Alignment.center,
              child: Text(
                '+$more',
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

void openImageViewer(BuildContext context, List<String> refs, int initial) {
  Navigator.of(context, rootNavigator: true).push(PageRouteBuilder<void>(
    opaque: false,
    barrierColor: Colors.black,
    pageBuilder: (_, _, _) => _ImageViewer(refs: refs, initial: initial),
    transitionsBuilder: (_, anim, _, child) => FadeTransition(opacity: anim, child: child),
  ));
}

class _ImageViewer extends StatefulWidget {
  const _ImageViewer({required this.refs, required this.initial});

  final List<String> refs;
  final int initial;

  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewer> {
  late final _controller = PageController(initialPage: widget.initial);
  late int _index = widget.initial;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: widget.refs.length > 1 ? Text('${_index + 1} / ${widget.refs.length}') : null,
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.refs.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) => InteractiveViewer(
          maxScale: 5,
          child: Center(
            child: NetImage(
              url: MediaUrls.image(widget.refs[i], ImageVariant.full),
              fallbackUrl: MediaUrls.original(widget.refs[i]),
              fit: BoxFit.contain,
              placeholderColor: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
