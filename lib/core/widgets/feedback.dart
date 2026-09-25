import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../network/api_exception.dart';

/// App-wide snackbars. Errors are passed as-is and turned into user copy here,
/// so call sites never format exceptions themselves.
class Toast {
  Toast._();

  static void show(BuildContext context, String message, {bool error = false}) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? AppColors.error : null,
        duration: Duration(seconds: error ? 4 : 2),
      ));
  }

  static void error(BuildContext context, Object error) =>
      show(context, friendlyErrorMessage(error), error: true);
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: destructive ? TextButton.styleFrom(foregroundColor: AppColors.error) : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Single text-input dialog (reject reasons, edits). Returns null on cancel.
Future<String?> promptDialog(
  BuildContext context, {
  required String title,
  String? initial,
  String? hint,
  String confirmLabel = 'Save',
  int maxLines = 1,
  int? maxLength,
  bool allowEmpty = false,
}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: maxLines,
          minLines: 1,
          maxLength: maxLength,
          decoration: InputDecoration(hintText: hint),
          onChanged: (_) => setState(() {}),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: !allowEmpty && controller.text.trim().isEmpty
                ? null
                : () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ),
  ).whenComplete(controller.dispose);
}

/// Runs [action], showing a toast on failure. Returns true on success.
Future<bool> guard(BuildContext context, Future<void> Function() action, {String? success}) async {
  try {
    await action();
    if (success != null && context.mounted) Toast.show(context, success);
    return true;
  } catch (e) {
    if (context.mounted) Toast.error(context, e);
    return false;
  }
}
