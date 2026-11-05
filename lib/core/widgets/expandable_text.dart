import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import 'link_text.dart';

/// Wraps [text] with a line-based truncation threshold and an interactive
/// 'Read more' / 'Show less' toggle.
///
/// Uses [LayoutBuilder] and [TextPainter] to accurately measure whether the
/// text overflows [maxLines] (default: 3) for the current layout width.
/// All embedded web URLs remain highlighted and clickable via [LinkText].
class ExpandableText extends StatefulWidget {
  const ExpandableText({
    super.key,
    required this.text,
    this.maxLines = 3,
    this.style,
    this.linkStyle,
    this.expandText = 'Read more',
    this.collapseText = 'Show less',
  });

  final String text;
  final int maxLines;
  final TextStyle? style;
  final TextStyle? linkStyle;
  final String expandText;
  final String collapseText;

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final defaultStyle = DefaultTextStyle.of(context).style;
    final baseStyle = widget.style ?? defaultStyle;
    final linkColor = dark ? AppColors.primaryLight : AppColors.primary;
    final toggleStyle = AppTextStyles.labelMedium.copyWith(
      color: linkColor,
      fontWeight: FontWeight.w600,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: baseStyle),
          textDirection: Directionality.of(context),
          maxLines: widget.maxLines,
        )..layout(maxWidth: constraints.maxWidth);

        final isOverflowing = textPainter.didExceedMaxLines;

        if (!isOverflowing) {
          return LinkText(
            text: widget.text,
            style: baseStyle,
            linkStyle: widget.linkStyle,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            LinkText(
              text: widget.text,
              style: baseStyle,
              linkStyle: widget.linkStyle,
              maxLines: _isExpanded ? null : widget.maxLines,
              overflow: _isExpanded ? null : TextOverflow.ellipsis,
            ),
            GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 2),
                child: Text(
                  _isExpanded ? widget.collapseText : widget.expandText,
                  style: toggleStyle,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

