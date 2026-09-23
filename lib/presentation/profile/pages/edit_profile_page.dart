import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trading_book/domain/repositories/auth_repository.dart';
import 'package:trading_book/presentation/auth/cubit/auth_cubit.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // ── Controllers ────────────────────────────────────────────────────────────
  final TextEditingController _displayNameCtrl = TextEditingController();
  final TextEditingController _bioCtrl = TextEditingController();
  final TextEditingController _languagesCtrl = TextEditingController();

  // ── State ──────────────────────────────────────────────────────────────────
  bool _privateProfile = false;
  bool _isSaving = false;

  /// Editable copy of the user's interests chips.
  List<String> _interests = [];

  @override
  void initState() {
    super.initState();
    // Pre-populate fields from the already-loaded AuthCubit user.
    final user = context.read<AuthCubit>().currentUser;
    if (user != null) {
      _displayNameCtrl.text = user.displayName;
      _bioCtrl.text = user.bio;
      _languagesCtrl.text = user.languages.join(', ');
      _privateProfile = user.isPrivate;
      _interests = List<String>.from(user.interests);
    }
    // Fallback sample data so the UI is never empty during development.
    if (_interests.isEmpty) {
      _interests = ['Options', 'Volatility', 'Equity'];
    }
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _bioCtrl.dispose();
    _languagesCtrl.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _onSave() async {
    final displayName = _displayNameCtrl.text.trim();
    if (displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Display name cannot be empty')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final authRepo = context.read<AuthRepository>();
      await authRepo.updateMe(
        displayName: displayName,
        bio: _bioCtrl.text.trim(),
        interests: _interests,
        languages: _languagesCtrl.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        isPrivate: _privateProfile,
      );
      // Refresh the cached user in AuthCubit so the profile header updates.
      if (!mounted) return;
      await context.read<AuthCubit>().refreshCurrentUser();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  void _onCancel() => Navigator.pop(context);

  void _removeInterest(String tag) {
    setState(() => _interests.remove(tag));
  }

  void _addInterest() {
    // Simple inline dialog — replace with a bottom sheet when ready.
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Interest'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'e.g. Futures'),
          onSubmitted: (_) => Navigator.pop(ctx),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final tag = ctrl.text.trim();
              if (tag.isNotEmpty && !_interests.contains(tag)) {
                setState(() => _interests.add(tag));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: _isSaving ? null : _onCancel,
        ),
        title: Text(
          'Back to Profile',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Scrollable form ──────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                children: [
                  // Title
                  Text(
                    'Edit Profile',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Display name
                  _label('Display name', theme),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _displayNameCtrl,
                    enabled: !_isSaving,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDeco('Your display name', theme),
                  ),
                  const SizedBox(height: 20),

                  // Bio
                  _label('Bio', theme),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bioCtrl,
                    enabled: !_isSaving,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    decoration: _inputDeco(
                        'Tell others about your trading style…', theme),
                  ),
                  const SizedBox(height: 20),

                  // Interests
                  _label('Interests', theme),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._interests.map(
                        (tag) => Chip(
                          label: Text(tag),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted:
                              _isSaving ? null : () => _removeInterest(tag),
                          backgroundColor:
                              theme.colorScheme.primaryContainer,
                          labelStyle: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontSize: 13,
                          ),
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 0),
                        ),
                      ),
                      ActionChip(
                        avatar: Icon(Icons.add,
                            size: 16, color: theme.colorScheme.primary),
                        label: Text(
                          'Add interest',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 13,
                          ),
                        ),
                        backgroundColor: theme.colorScheme.surface,
                        side: BorderSide(
                            color: theme.colorScheme.outline, width: 1),
                        onPressed: _isSaving ? null : _addInterest,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Preferred languages
                  _label('Preferred languages', theme),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _languagesCtrl,
                    enabled: !_isSaving,
                    textInputAction: TextInputAction.done,
                    decoration:
                        _inputDeco('e.g. English, Spanish', theme),
                  ),
                  const SizedBox(height: 20),

                  // Private profile
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: _privateProfile,
                        onChanged: _isSaving
                            ? null
                            : (v) =>
                                setState(() => _privateProfile = v ?? false),
                        activeColor: theme.colorScheme.primary,
                        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Private profile',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              'Hidden from non-followers',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ── Buttons ────────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Save Changes
                      FilledButton(
                        onPressed: _isSaving ? null : _onSave,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                      ),
                      const SizedBox(width: 12),
                      // Cancel
                      FilledButton.tonal(
                        onPressed: _isSaving ? null : _onCancel,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _label(String text, ThemeData theme) => Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      );

  InputDecoration _inputDeco(String hint, ThemeData theme) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          fontSize: 14,
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerLowest,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      );
}
