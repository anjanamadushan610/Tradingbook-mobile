import 'package:flutter/material.dart';
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
import '../communities/widgets/image_edit_row.dart';

/// Create a page, or edit one (owner/admin) when [pageId] is given.
class PageFormPage extends StatefulWidget {
  const PageFormPage({super.key, this.pageId});

  final String? pageId;

  @override
  State<PageFormPage> createState() => _PageFormPageState();
}

class _PageFormPageState extends State<PageFormPage> {
  final _repo = sl<CommunityRepository>();
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  bool _saving = false;
  CommunityPage? _page;
  Object? _loadError;
  bool get _editing => widget.pageId != null;

  @override
  void initState() {
    super.initState();
    if (_editing) _load();
  }

  Future<void> _load() async {
    try {
      final p = await _repo.page(widget.pageId!);
      if (!mounted) return;
      setState(() {
        _page = p;
        _name.text = p.name;
        _description.text = p.description;
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
        await _repo.updatePage(widget.pageId!, name: _name.text, description: _description.text);
        if (!mounted) return;
        Toast.show(context, 'Page updated');
        context.pop();
      } else {
        final p = await _repo.createPage(name: _name.text, description: _description.text);
        if (!mounted) return;
        Toast.show(context, 'Page created');
        context.pushReplacement(Routes.page(p.id));
      }
    } catch (e) {
      if (mounted) Toast.error(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_editing && _page == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit page')),
        body: _loadError != null ? ErrorView(error: _loadError, onRetry: _load) : const LoadingView(),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit page' : 'New page')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            if (_page != null)
              CommunityImagesEditor(
                name: _page!.name,
                avatarUrl: _page!.avatarUrl,
                coverUrl: _page!.coverUrl,
                upload: (file, kind) async {
                  final p = await _repo.uploadPageImage(_page!.id, file, kind: kind);
                  if (mounted) setState(() => _page = p);
                },
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: 'Page name',
                    hint: 'e.g. Colombo FX Desk',
                    controller: _name,
                    maxLength: 100,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => Validators.required(v, 'Name'),
                  ),
                  const SizedBox(height: 8),
                  AppTextField(
                    label: 'About',
                    hint: 'What followers can expect from this page',
                    controller: _description,
                    maxLines: 5,
                    maxLength: 1000,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  if (!_editing)
                    Text(
                      'Pages are public. Posts you publish as the page are reviewed by moderators first. '
                      'You can add a logo and cover after creating it.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: _editing ? 'Save changes' : 'Create page',
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
