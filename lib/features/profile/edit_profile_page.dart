import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/di/service_locator.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/net_image.dart';
import '../../core/utils/image_prep.dart';
import '../../core/utils/validators.dart';
import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../auth/session_cubit.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late UserProfile _user = context.read<SessionCubit>().user!;
  late final _name = TextEditingController(text: _user.displayName);
  late final _bio = TextEditingController(text: _user.bio);
  final _interestInput = TextEditingController();
  late final List<String> _interests = List.of(_user.interests);
  late Set<String> _languages = _user.languages.toSet();
  late bool _isPrivate = _user.isPrivate;
  bool _saving = false;
  String? _uploading;

  static const _languageOptions = {'en': 'English', 'si': 'Sinhala', 'ta': 'Tamil', 'hi': 'Hindi', 'ar': 'Arabic', 'es': 'Spanish'};
  static const _interestSuggestions = [
    'Crypto', 'Forex', 'Stocks', 'Gold', 'Indices', 'Options', 'Day Trading',
    'Swing Trading', 'Technical Analysis', 'Fundamental Analysis', 'Macro', 'Scalping',
  ];

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _interestInput.dispose();
    super.dispose();
  }

  Future<void> _uploadImage(String kind) async {
    File? file;
    try {
      file = await ImagePrep.pickOne(maxSide: kind == 'avatar' ? 1024 : 2048);
    } catch (_) {
      if (mounted) Toast.show(context, 'Couldn\'t open your photos.', error: true);
      return;
    }
    if (file == null) return;
    setState(() => _uploading = kind);
    try {
      final updated = await sl<AuthRepository>().uploadProfileImage(file, kind: kind);
      if (!mounted) return;
      setState(() => _user = updated);
      context.read<SessionCubit>().profileUpdated(updated);
      sl<UserRepository>().primeCache(updated);
    } catch (e) {
      if (mounted) Toast.error(context, e);
    } finally {
      if (mounted) setState(() => _uploading = null);
    }
  }

  void _addInterest(String raw) {
    final v = raw.trim();
    if (v.isEmpty || v.length > 50 || _interests.length >= 50) return;
    if (_interests.any((i) => i.toLowerCase() == v.toLowerCase())) return;
    setState(() => _interests.add(v));
    _interestInput.clear();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final updated = await sl<AuthRepository>().updateMe({
        'displayName': _name.text.trim(),
        'bio': _bio.text.trim(),
        'interests': _interests,
        'languages': _languages.toList(),
        'isPrivate': _isPrivate,
      });
      if (!mounted) return;
      context.read<SessionCubit>().profileUpdated(updated);
      sl<UserRepository>().primeCache(updated);
      Toast.show(context, 'Profile saved');
      context.pop();
    } catch (e) {
      if (mounted) Toast.error(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            SizedBox(
              height: 200,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    bottom: 50,
                    child: GestureDetector(
                      onTap: _uploading == null ? () => _uploadImage('cover') : null,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _user.coverUrl == null
                              ? Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient))
                              : NetImage(url: _user.coverUrl!),
                          Container(color: Colors.black26),
                          Center(
                            child: _uploading == 'cover'
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.photo_camera_outlined, color: Colors.white),
                                      Text('Change cover', style: TextStyle(color: Colors.white)),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: _uploading == null ? () => _uploadImage('avatar') : null,
                      child: Stack(
                        children: [
                          AppAvatar(
                            url: _user.avatarUrl,
                            name: _user.displayName,
                            size: 96,
                            borderColor: dark ? AppColors.darkSurface : Colors.white,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primary,
                              child: _uploading == 'avatar'
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.photo_camera_rounded, size: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: 'Display name',
                    controller: _name,
                    maxLength: 80,
                    textCapitalization: TextCapitalization.words,
                    validator: Validators.displayName,
                  ),
                  const SizedBox(height: 8),
                  AppTextField(
                    label: 'Bio',
                    hint: 'Your markets, style and experience',
                    controller: _bio,
                    maxLines: 4,
                    maxLength: 500,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  Text('Interests', style: AppTextStyles.titleSmall.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final i in _interests)
                        InputChip(
                          label: Text(i),
                          onDeleted: () => setState(() => _interests.remove(i)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _interestInput,
                    textCapitalization: TextCapitalization.words,
                    onSubmitted: _addInterest,
                    decoration: InputDecoration(
                      hintText: 'Add an interest and press enter',
                      suffixIcon: IconButton(
                        tooltip: 'Add interest',
                        icon: const Icon(Icons.add_rounded),
                        onPressed: () => _addInterest(_interestInput.text),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final s in _interestSuggestions.where(
                          (s) => !_interests.any((i) => i.toLowerCase() == s.toLowerCase())))
                        ActionChip(label: Text('+ $s'), onPressed: () => _addInterest(s)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Languages', style: AppTextStyles.titleSmall.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final e in _languageOptions.entries)
                        FilterChip(
                          label: Text(e.value),
                          selected: _languages.contains(e.key),
                          onSelected: (on) => setState(() {
                            _languages = {..._languages};
                            on ? _languages.add(e.key) : _languages.remove(e.key);
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _isPrivate,
                    onChanged: (v) => setState(() => _isPrivate = v),
                    title: const Text('Private profile'),
                    subtitle: const Text('Hide your profile from search and from people who don\'t follow you.'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
