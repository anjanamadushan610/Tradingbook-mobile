import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/widgets/feedback.dart';
import '../../../data/models/community.dart';
import '../../../data/repositories/community_repository.dart';

/// Join (public) / Request (private) straight from a group list, so joining
/// doesn't need a trip to the group's page (QA mobile BUG 05).
///
/// Pass [joined] when the list already knows (discover lists only hold groups
/// the user isn't in); otherwise the button asks the API once.
class GroupJoinButton extends StatefulWidget {
  const GroupJoinButton({super.key, required this.group, this.joined, this.onJoined});

  final Group group;
  final bool? joined;
  final VoidCallback? onJoined;

  @override
  State<GroupJoinButton> createState() => _GroupJoinButtonState();
}

enum _JoinState { unknown, open, requested, joined }

class _GroupJoinButtonState extends State<GroupJoinButton> {
  final _repo = sl<CommunityRepository>();
  late _JoinState _state = switch (widget.joined) {
    true => _JoinState.joined,
    false => _JoinState.open,
    null => _JoinState.unknown,
  };
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (_state == _JoinState.unknown) {
      _repo.membership(widget.group.id).then((m) {
        if (mounted) setState(() => _state = m.isMember ? _JoinState.joined : _JoinState.open);
      }).catchError((_) {
        if (mounted) setState(() => _state = _JoinState.open);
      });
    }
  }

  Future<void> _join() async {
    setState(() => _busy = true);
    try {
      final status = await _repo.joinGroup(widget.group.id);
      if (!mounted) return;
      if (status == 'requested') {
        setState(() => _state = _JoinState.requested);
        Toast.show(context, 'Request sent. An admin will review it.');
      } else {
        setState(() => _state = _JoinState.joined);
        Toast.show(context, 'You joined ${widget.group.name}');
        widget.onJoined?.call();
      }
    } catch (e) {
      if (mounted) Toast.error(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      _JoinState.unknown => const _Placeholder(),
      _JoinState.joined => const _DoneChip(label: 'Joined'),
      _JoinState.requested => const _DoneChip(label: 'Requested'),
      _JoinState.open => _PillButton(
          label: widget.group.isPrivate ? 'Request' : 'Join',
          busy: _busy,
          onPressed: _join,
        ),
    };
  }
}

/// Follow / Following straight from a page list (QA mobile BUG 07).
class PageFollowButton extends StatefulWidget {
  const PageFollowButton({super.key, required this.page, this.following, this.onChanged});

  final CommunityPage page;
  final bool? following;
  final ValueChanged<bool>? onChanged;

  @override
  State<PageFollowButton> createState() => _PageFollowButtonState();
}

class _PageFollowButtonState extends State<PageFollowButton> {
  final _repo = sl<CommunityRepository>();
  late bool? _following = widget.following;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (_following == null) {
      _repo.isFollowingPage(widget.page.id).then((f) {
        if (mounted) setState(() => _following = f);
      }).catchError((_) {
        if (mounted) setState(() => _following = false);
      });
    }
  }

  Future<void> _toggle() async {
    final was = _following ?? false;
    setState(() {
      _busy = true;
      _following = !was;
    });
    try {
      was ? await _repo.unfollowPage(widget.page.id) : await _repo.followPage(widget.page.id);
      widget.onChanged?.call(!was);
    } catch (e) {
      if (mounted) {
        setState(() => _following = was);
        Toast.error(context, e);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final following = _following;
    if (following == null) return const _Placeholder();
    return _PillButton(
      label: following ? 'Following' : 'Follow',
      outlined: following,
      busy: _busy,
      onPressed: _toggle,
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.onPressed, this.busy = false, this.outlined = false});

  final String label;
  final VoidCallback onPressed;
  final bool busy;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      visualDensity: VisualDensity.compact,
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 14)),
      minimumSize: const WidgetStatePropertyAll(Size(84, 34)),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(17))),
    );
    final child = busy
        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
        : Text(label, style: const TextStyle(fontWeight: FontWeight.w600));
    return outlined
        ? OutlinedButton(style: style, onPressed: busy ? null : onPressed, child: child)
        : FilledButton(
            style: style.copyWith(backgroundColor: const WidgetStatePropertyAll(AppColors.primary)),
            onPressed: busy ? null : onPressed,
            child: child,
          );
  }
}

class _DoneChip extends StatelessWidget {
  const _DoneChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
        ],
      );
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) => const SizedBox(width: 84, height: 34);
}
