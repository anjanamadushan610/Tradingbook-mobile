import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/routes.dart';

/// Caption with tappable #hashtags (→ search), clickable web links (→ browser),
/// and a line-based 'Read more' / 'Show less' toggle for long text.
///
/// Uses [LayoutBuilder] and [TextPainter] to determine true visual overflow
/// without splitting URLs, hashtags, or Unicode characters in half.
class PostCaption extends StatefulWidget {
  const PostCaption({
    super.key,
    required this.text,
    this.maxLines = 4,
    @Deprecated('Use maxLines instead') this.collapsedLength,
  });

  final String text;
  final int maxLines;
  final int? collapsedLength;

  @override
  State<PostCaption> createState() => _PostCaptionState();
}

class _PostCaptionState extends State<PostCaption> {
  bool _expanded = false;
  final _recognizers = <TapGestureRecognizer>[];

  // Matches either:
  // 1) URLs: https://..., http://..., or www....
  // 2) Hashtags: #word, supporting Unicode combining marks (Sinhala, Tamil, etc.)
  static final _tokenRegex = RegExp(
    r'''(https?:\/\/[^\s<]+[^<.,:;"')\]\s]|(?<![\w@])www\.[^\s<]+[^<.,:;"')\]\s]|#[\p{L}\p{M}\p{N}_]+)''',
    caseSensitive: false,
    unicode: true,
  );

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _openUrl(String raw) async {
    var url = raw.trim();
    if (url.toLowerCase().startsWith('www.')) {
      url = 'https://$url';
    }
    final uri = Uri.tryParse(url);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        // Fallback or ignore unhandled schemes
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    final base = AppTextStyles.bodyLarge.copyWith(
      color: cs.onSurface,
      height: 1.45,
      letterSpacing: -0.1, // Figma: tighter tracking for post body readability
    );
    final linkColor = dark ? AppColors.primaryLight : AppColors.primary;
    final tagStyle = base.copyWith(
      color: linkColor,
      fontWeight: FontWeight.w600,
    );
    final urlStyle = base.copyWith(
      color: linkColor,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: linkColor.withOpacity(0.4),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: base),
          textDirection: Directionality.of(context),
          maxLines: widget.maxLines,
        )..layout(maxWidth: constraints.maxWidth);

        final exceeds = textPainter.didExceedMaxLines;
        final isCollapsed = exceeds && !_expanded;

        for (final r in _recognizers) {
          r.dispose();
        }
        _recognizers.clear();

        final spans = <InlineSpan>[];
        var last = 0;

        for (final m in _tokenRegex.allMatches(widget.text)) {
          if (m.start > last) {
            spans.add(TextSpan(text: widget.text.substring(last, m.start)));
          }
          final token = m.group(0)!;

          if (token.startsWith('#')) {
            // Hashtag tap -> search
            final r = TapGestureRecognizer()
              ..onTap = () => context.push(Routes.search(token));
            _recognizers.add(r);
            spans.add(TextSpan(text: token, style: tagStyle, recognizer: r));
          } else {
            // Web link tap -> external browser
            final r = TapGestureRecognizer()
              ..onTap = () => _openUrl(token);
            _recognizers.add(r);
            spans.add(TextSpan(text: token, style: urlStyle, recognizer: r));
          }

          last = m.end;
        }

        if (last < widget.text.length) {
          spans.add(TextSpan(text: widget.text.substring(last)));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text.rich(
              TextSpan(style: base, children: spans),
              maxLines: isCollapsed ? widget.maxLines : null,
              overflow: isCollapsed ? TextOverflow.ellipsis : null,
            ),
            if (exceeds)
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _expanded ? 'Show less' : 'Read more',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: linkColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
