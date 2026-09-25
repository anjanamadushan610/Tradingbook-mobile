import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.url,
    this.name,
    this.size = 40,
    this.square = false,
    this.borderColor,
  });

  final String? url;
  final String? name;
  final double size;

  /// Rounded square — used for groups and pages, circles are for people.
  final bool square;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final radius = square ? BorderRadius.circular(size * 0.24) : BorderRadius.circular(size);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    Widget content = url != null && url!.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: url!,
            fit: BoxFit.cover,
            memCacheWidth: (size * dpr).round(),
            placeholder: (_, _) => _initials(context),
            errorWidget: (_, _, _) => _initials(context),
          )
        : _initials(context);
    return Semantics(
      label: name == null ? 'Avatar' : '$name avatar',
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: borderColor == null ? null : Border.all(color: borderColor!, width: 2),
        ),
        child: ClipRRect(borderRadius: radius, child: content),
      ),
    );
  }

  Widget _initials(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: dark ? AppColors.primary.withValues(alpha: 0.35) : AppColors.primarySurface,
      alignment: Alignment.center,
      child: Text(
        _letters(),
        style: TextStyle(
          color: dark ? Colors.white : AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.36,
        ),
      ),
    );
  }

  String _letters() {
    final n = (name ?? '').trim();
    if (n.isEmpty) return '?';
    // Initials come from words, not symbols: "Algo & Quant" → "AQ".
    final parts = n
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty && RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(p.characters.first))
        .toList();
    if (parts.isEmpty) return n.characters.first.toUpperCase();
    if (parts.length >= 2) {
      return (parts[0].characters.first + parts[1].characters.first).toUpperCase();
    }
    return n.characters.first.toUpperCase();
  }
}
