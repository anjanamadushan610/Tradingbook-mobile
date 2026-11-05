import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_colors.dart';

/// Renders [text] with web URLs highlighted and clickable.
///
/// Automatically parses `https://...`, `http://...`, and `www....` links,
/// styling them in primary blue with a subtle underline, and launching them
/// in an external browser via [url_launcher].
class LinkText extends StatefulWidget {
  const LinkText({
    super.key,
    required this.text,
    this.style,
    this.linkStyle,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle? style;
  final TextStyle? linkStyle;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  State<LinkText> createState() => _LinkTextState();
}

class _LinkTextState extends State<LinkText> {
  final _recognizers = <TapGestureRecognizer>[];

  static final _urlRegex = RegExp(
    r'''(https?:\/\/[^\s<]+[^<.,:;"')\]\s]|(?<![\w@])www\.[^\s<]+[^<.,:;"')\]\s])''',
    caseSensitive: false,
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
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final dark = Theme.of(context).brightness == Brightness.dark;
    final defaultStyle = DefaultTextStyle.of(context).style;
    final baseStyle = widget.style ?? defaultStyle;
    final linkColor = dark ? AppColors.primaryLight : AppColors.primary;
    final effectiveLinkStyle = widget.linkStyle ??
        baseStyle.copyWith(
          color: linkColor,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: linkColor.withOpacity(0.4),
        );

    final text = widget.text;
    final spans = <InlineSpan>[];
    var last = 0;

    for (final m in _urlRegex.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      final matchedUrl = m.group(0)!;
      final recognizer = TapGestureRecognizer()
        ..onTap = () => _openUrl(matchedUrl);
      _recognizers.add(recognizer);
      spans.add(TextSpan(
        text: matchedUrl,
        style: effectiveLinkStyle,
        recognizer: recognizer,
      ));
      last = m.end;
    }

    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }

    return Text.rich(
      TextSpan(style: baseStyle, children: spans),
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }
}
