import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/user_repository.dart';

/// Search-and-pick a trader (invite to group, add to a page's team).
Future<UserProfile?> pickUser(BuildContext context, {required String title}) {
  return showModalBottomSheet<UserProfile>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _UserPicker(title: title),
  );
}

class _UserPicker extends StatefulWidget {
  const _UserPicker({required this.title});
  final String title;

  @override
  State<_UserPicker> createState() => _UserPickerState();
}

class _UserPickerState extends State<_UserPicker> {
  Timer? _debounce;
  List<UserProfile> _results = const [];
  bool _loading = false;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _search(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (q.trim().isEmpty) {
        setState(() => _results = const []);
        return;
      }
      setState(() => _loading = true);
      try {
        final page = await sl<UserRepository>().search(q.trim());
        if (mounted) setState(() => _results = page.items);
      } catch (_) {
        if (mounted) setState(() => _results = const []);
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                autofocus: true,
                onChanged: _search,
                decoration: const InputDecoration(
                  hintText: 'Search by name',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            if (_loading) const LinearProgressIndicator(),
            Expanded(
              child: ListView(
                children: [
                  for (final u in _results)
                    ListTile(
                      leading: AppAvatar(url: u.avatarUrl, name: u.displayName),
                      title: Text(u.displayName),
                      subtitle: u.bio.isEmpty ? null : Text(u.bio, maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () => Navigator.pop(context, u),
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
