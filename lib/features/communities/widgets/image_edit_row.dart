import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/image_prep.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/net_image.dart';

/// Cover + avatar editor used by the group and page settings screens.
class CommunityImagesEditor extends StatefulWidget {
  const CommunityImagesEditor({
    super.key,
    required this.name,
    required this.avatarUrl,
    required this.coverUrl,
    required this.upload,
  });

  final String name;
  final String? avatarUrl;
  final String? coverUrl;

  /// Uploads [file] as `avatar` or `cover`; the caller refreshes its model.
  final Future<void> Function(File file, String kind) upload;

  @override
  State<CommunityImagesEditor> createState() => _CommunityImagesEditorState();
}

class _CommunityImagesEditorState extends State<CommunityImagesEditor> {
  String? _busy;

  Future<void> _pick(String kind) async {
    final File? file;
    try {
      file = await ImagePrep.pickOne(maxSide: kind == 'avatar' ? 1024 : 2048);
    } catch (_) {
      if (mounted) Toast.show(context, 'Couldn\'t open your photos.', error: true);
      return;
    }
    if (file == null) return;
    setState(() => _busy = kind);
    try {
      await widget.upload(file, kind);
    } catch (e) {
      if (mounted) Toast.error(context, e);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 190,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            bottom: 44,
            child: GestureDetector(
              onTap: _busy == null ? () => _pick('cover') : null,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  widget.coverUrl == null
                      ? Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient))
                      : NetImage(url: widget.coverUrl!),
                  Container(color: Colors.black26),
                  Center(
                    child: _busy == 'cover'
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.photo_camera_outlined, color: Colors.white),
                            Text('Change cover', style: TextStyle(color: Colors.white)),
                          ]),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 0,
            child: GestureDetector(
              onTap: _busy == null ? () => _pick('avatar') : null,
              child: Stack(
                children: [
                  AppAvatar(
                    url: widget.avatarUrl,
                    name: widget.name,
                    size: 84,
                    square: true,
                    borderColor: dark ? AppColors.darkSurface : Colors.white,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: AppColors.primary,
                      child: _busy == 'avatar'
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.photo_camera_rounded, size: 15, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
