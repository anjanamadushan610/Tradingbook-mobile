import 'package:flutter/material.dart';

import '../../../core/utils/media_urls.dart';
import '../../../core/widgets/net_image.dart';
import '../../../data/models/post.dart';

/// Image carousel (1–10 images) or the video placeholder. Tapping an image
/// opens the zoomable full-screen viewer.
class PostMedia extends StatefulWidget {
  const PostMedia({super.key, required this.post});

  final Post post;

  @override
  State<PostMedia> createState() => _PostMediaState();
}

class _PostMediaState extends State<PostMedia> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final refs = post.mediaRefs.where((r) => r != 'pending').toList();
    if (refs.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;

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
    final cacheWidth = (width * MediaQuery.devicePixelRatioOf(context)).round();
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: refs.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => GestureDetector(
              onTap: () => openImageViewer(context, refs, i),
              child: NetImage(
                url: MediaUrls.image(refs[i]),
                fallbackUrl: MediaUrls.original(refs[i]),
                fit: BoxFit.cover,
                memCacheWidth: cacheWidth,
              ),
            ),
          ),
          if (refs.length > 1) ...[
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_index + 1}/${refs.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < refs.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _index ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _index ? Colors.white : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [BoxShadow(color: cs.shadow.withValues(alpha: 0.3), blurRadius: 2)],
                      ),
                    ),
                ],
              ),
            ),
          ],
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
