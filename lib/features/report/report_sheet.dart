import 'package:flutter/material.dart';

import '../../core/constants/app_text_styles.dart';
import '../../core/di/service_locator.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/feedback.dart';
import '../../data/models/moderation.dart';
import '../../data/repositories/moderation_repository.dart';

/// Lets anyone flag a post, comment, user, group or page for the moderation
/// team (Google Play's user-generated-content policy requires this).
Future<bool> showReportSheet(
  BuildContext context, {
  required ReportTarget target,
  required String targetId,
}) async {
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _ReportSheet(target: target, targetId: targetId),
  );
  if (sent == true && context.mounted) {
    Toast.show(context, 'Thanks — our moderators will review it.');
  }
  return sent == true;
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({required this.target, required this.targetId});

  final ReportTarget target;
  final String targetId;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  ReportReason? _reason;
  final _details = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null) return;
    setState(() => _busy = true);
    try {
      await sl<ModerationRepository>().report(
        target: widget.target,
        targetId: widget.targetId,
        reason: reason,
        details: _details.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) Toast.error(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Report ${widget.target.name}', style: AppTextStyles.headlineMedium.copyWith(color: cs.onSurface)),
            const SizedBox(height: 4),
            Text(
              'Reports are anonymous to the person you report.',
              style: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            RadioGroup<ReportReason>(
              groupValue: _reason,
              onChanged: (v) => setState(() => _reason = v),
              child: Column(
                children: [
                  for (final r in ReportReason.values)
                    RadioListTile<ReportReason>(
                      value: r,
                      contentPadding: EdgeInsets.zero,
                      title: Text(r.label),
                    ),
                ],
              ),
            ),
            TextField(
              controller: _details,
              maxLines: 3,
              maxLength: 1000,
              decoration: const InputDecoration(hintText: 'Add details (optional)'),
            ),
            const SizedBox(height: 8),
            AppButton(
              label: 'Submit report',
              style: AppButtonStyle.danger,
              isLoading: _busy,
              onPressed: _reason == null ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
