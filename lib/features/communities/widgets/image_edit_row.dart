import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/image_prep.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/net_image.dart';

/// Cover + avatar editor used by the group and page settings screens, and by
/// the create forms — there [avatarFile]/[coverFile] preview images picked
/// before the community exists, and [onRemove] clears one.
class CommunityImagesEditor extends StatefulWidget {
  const CommunityImagesEditor({
    super.key,
    required this.name,
    required this.avatarUrl,
    required this.coverUrl,
    required this.upload,
    this.avatarFile,
    this.coverFile,
    this.onRemove,
  });

  final String name;
  final String? avatarUrl;
  final String? coverUrl;
  final File? avatarFile;
  final File? coverFile;
  final void Function(String kind)? onRemove;

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
                  if (widget.coverFile != null)
                    Image.file(widget.coverFile!, fit: BoxFit.cover, cacheWidth: 1200)
                  else if (widget.coverUrl != null)
                    NetImage(url: widget.coverUrl!)
                  else
                    Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
                  Container(color: Colors.black26),
                  Center(
                    child: _busy == 'cover'
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Column(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.photo_camera_outlined, color: Colors.white),
                            Text(
                              widget.coverFile == null && widget.coverUrl == null ? 'Add cover image' : 'Change cover',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ]),
                  ),
                  if (widget.coverFile != null && widget.onRemove != null)
                    Positioned(top: 8, right: 8, child: _RemoveButton(onTap: () => widget.onRemove!('cover'))),
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
                clipBehavior: Clip.none,
                children: [
                  if (widget.avatarFile != null)
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: dark ? AppColors.darkSurface : Colors.white, width: 2),
                        image: DecorationImage(image: FileImage(widget.avatarFile!), fit: BoxFit.cover),
                      ),
                    )
                  else
                    AppAvatar(
                      url: widget.avatarUrl,
                      name: widget.name,
                      size: 84,
                      square: true,
                      borderColor: dark ? AppColors.darkSurface : Colors.white,
                    ),
                  if (widget.avatarFile != null && widget.onRemove != null)
                    Positioned(top: -6, left: -6, child: _RemoveButton(onTap: () => widget.onRemove!('avatar'))),
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

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Remove image',
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
            child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
          ),
        ),
      );
}
