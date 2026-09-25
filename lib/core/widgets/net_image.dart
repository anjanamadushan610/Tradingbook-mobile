import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Cached network image with an optional second URL to try on failure (a
/// WebP variant that isn't generated yet → the original upload).
class NetImage extends StatefulWidget {
  const NetImage({
    super.key,
    required this.url,
    this.fallbackUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholderColor,
    this.memCacheWidth,
  });

  final String url;
  final String? fallbackUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Color? placeholderColor;

  /// Decode at this width to save memory in lists.
  final int? memCacheWidth;

  @override
  State<NetImage> createState() => _NetImageState();
}

class _NetImageState extends State<NetImage> {
  bool _useFallback = false;

  @override
  void didUpdateWidget(NetImage old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) _useFallback = false;
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.placeholderColor ??
        Theme.of(context).colorScheme.surfaceContainerHighest;
    final url = _useFallback && widget.fallbackUrl != null ? widget.fallbackUrl! : widget.url;
    return CachedNetworkImage(
      imageUrl: url,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      memCacheWidth: widget.memCacheWidth,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (_, _) => Container(color: bg),
      errorWidget: (_, _, _) {
        if (!_useFallback && widget.fallbackUrl != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _useFallback = true);
          });
          return Container(color: bg);
        }
        return Container(
          color: bg,
          alignment: Alignment.center,
          child: Icon(
            Icons.broken_image_outlined,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        );
      },
    );
  }
}
