import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/service_locator.dart';
import '../../core/router/routes.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models/community.dart';
import '../../data/repositories/community_repository.dart';
import '../auth/session_cubit.dart';
import '../communities/widgets/image_edit_row.dart';

/// Create a group, or edit one (admins+) when [groupId] is given.
class GroupFormPage extends StatefulWidget {
  const GroupFormPage({super.key, this.groupId});

  final String? groupId;

  @override
  State<GroupFormPage> createState() => _GroupFormPageState();
}

class _GroupFormPageState extends State<GroupFormPage> {
  final _repo = sl<CommunityRepository>();
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  bool _isPrivate = false;
  bool _showOwner = true;
  bool _saving = false;
  Group? _group;
  Object? _loadError;

  // Picked on the create form, uploaded once the group exists (QA mobile BUG 11).
  File? _avatarFile;
  File? _coverFile;
  bool get _editing => widget.groupId != null;
  bool get _isOwner => _group != null && _group!.ownerId == context.read<SessionCubit>().user?.id;

  @override
  void initState() {
    super.initState();
    if (_editing) _load();
  }

  Future<void> _load() async {
    try {
      final g = await _repo.group(widget.groupId!);
      if (!mounted) return;
      setState(() {
        _group = g;
        _name.text = g.name;
        _description.text = g.description;
        _isPrivate = g.isPrivate;
        _showOwner = g.showOwner;
      });
    } catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      if (_editing) {
        await _repo.updateGroup(
          widget.groupId!,
          name: _name.text,
          description: _description.text,
          isPrivate: _isPrivate,
          // Only the owner decides whether they're listed (QA mobile BUG 23).
          showOwner: _isOwner ? _showOwner : null,
        );
        if (!mounted) return;
        Toast.show(context, 'Group updated');
        context.pop();
      } else {
        final g = await _repo.createGroup(
          name: _name.text,
          description: _description.text,
          isPrivate: _isPrivate,
        );
        var imagesFailed = false;
        for (final (file, kind) in [(_avatarFile, 'avatar'), (_coverFile, 'cover')]) {
          if (file == null) continue;
          try {
            await _repo.uploadGroupImage(g.id, file, kind: kind);
          } catch (_) {
            imagesFailed = true;
          }
        }
        if (!mounted) return;
        Toast.show(
          context,
          imagesFailed ? 'Group created, but a photo didn\'t upload. Try again from Edit.' : 'Group created',
          error: imagesFailed,
        );
        context.pushReplacement(Routes.group(g.id));
      }
    } catch (e) {
      if (mounted) Toast.error(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_editing && _group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit group')),
        body: _loadError != null ? ErrorView(error: _loadError, onRetry: _load) : const LoadingView(),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit group' : 'New group')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            if (_group != null)
              CommunityImagesEditor(
                name: _group!.name,
                avatarUrl: _group!.avatarUrl,
                coverUrl: _group!.coverUrl,
                upload: (file, kind) async {
                  final g = await _repo.uploadGroupImage(_group!.id, file, kind: kind);
                  if (mounted) setState(() => _group = g);
                },
              )
            else
              CommunityImagesEditor(
                name: _name.text.isEmpty ? 'G' : _name.text,
                avatarUrl: null,
                coverUrl: null,
                avatarFile: _avatarFile,
                coverFile: _coverFile,
                upload: (file, kind) async => setState(() {
                  if (kind == 'avatar') {
                    _avatarFile = file;
                  } else {
                    _coverFile = file;
                  }
                }),
                onRemove: (kind) => setState(() {
                  if (kind == 'avatar') {
                    _avatarFile = null;
                  } else {
                    _coverFile = null;
                  }
                }),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: 'Group name',
                    hint: 'e.g. Gold & Metals Traders',
                    controller: _name,
                    maxLength: 100,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => Validators.required(v, 'Name'),
                  ),
                  const SizedBox(height: 8),
                  AppTextField(
                    label: 'Description',
                    hint: 'What the group is about, and its rules',
                    controller: _description,
                    maxLines: 5,
                    maxLength: 1000,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _isPrivate,
                    onChanged: (v) => setState(() => _isPrivate = v),
                    title: const Text('Private group'),
                    subtitle: const Text(
                      'Only members see posts. People must request to join, and admins approve them.',
                    ),
                  ),
                  if (_editing && _isOwner)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _showOwner,
                      onChanged: (v) => setState(() => _showOwner = v),
                      title: const Text('Show me in the members list'),
                      subtitle: const Text(
                        'Off: members won\'t see you listed as the owner. Admins and TradingBook moderators still can.',
                      ),
                    ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: _editing ? 'Save changes' : 'Create group',
                    isLoading: _saving,
                    onPressed: _save,
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
