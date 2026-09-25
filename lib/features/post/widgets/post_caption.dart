import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/routes.dart';

/// Caption with tappable #hashtags (→ search) and a "more" toggle for long
/// text. Plain text only — captions are never interpreted as markup.
class PostCaption extends StatefulWidget {
  const PostCaption({super.key, required this.text, this.collapsedLength = 280});

  final String text;
  final int? collapsedLength;

  @override
  State<PostCaption> createState() => _PostCaptionState();
}

class _PostCaptionState extends State<PostCaption> {
  bool _expanded = false;
  final _recognizers = <TapGestureRecognizer>[];

  // Letters/digits/underscore plus combining marks, so Sinhala and Tamil tags
  // work (same rule as the backend's trending-topics extractor).
  static final _tag = RegExp(r'#[\p{L}\p{M}\p{N}_]+', unicode: true);

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final limit = widget.collapsedLength;
    final long = limit != null && widget.text.length > limit;
    final shown = long && !_expanded ? '${widget.text.substring(0, limit).trimRight()}…' : widget.text;

    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final base = AppTextStyles.bodyLarge.copyWith(color: cs.onSurface, height: 1.45);
    final tagStyle = base.copyWith(
      color: dark ? AppColors.primaryLight : AppColors.primary,
      fontWeight: FontWeight.w600,
    );
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in _tag.allMatches(shown)) {
      if (m.start > last) spans.add(TextSpan(text: shown.substring(last, m.start)));
      final tag = m.group(0)!;
      final r = TapGestureRecognizer()
        ..onTap = () => context.push(Routes.search(tag));
      _recognizers.add(r);
      spans.add(TextSpan(text: tag, style: tagStyle, recognizer: r));
      last = m.end;
    }
    if (last < shown.length) spans.add(TextSpan(text: shown.substring(last)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(TextSpan(style: base, children: spans)),
        if (long)
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _expanded ? 'Show less' : 'See more',
                style: AppTextStyles.titleSmall.copyWith(color: tagStyle.color),
              ),
            ),
          ),
      ],
    );
  }
}
