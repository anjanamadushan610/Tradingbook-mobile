import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/feedback.dart';
import '../../../data/repositories/user_repository.dart';
import '../../auth/session_cubit.dart';

/// Follow/Following toggle. Pass [initial] when the caller already knows the
/// state (e.g. suggested traders are, by definition, not followed); otherwise
/// it asks the API once.
class FollowButton extends StatefulWidget {
  const FollowButton({
    super.key,
    required this.userId,
    this.initial,
    this.onChanged,
    this.expand = false,
  });

  final String userId;
  final bool? initial;
  final ValueChanged<bool>? onChanged;
  final bool expand;

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  final _repo = sl<UserRepository>();
  bool? _following;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _following = widget.initial;
    if (_following == null) {
      _repo.isFollowing(widget.userId).then((f) {
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
      was ? await _repo.unfollow(widget.userId) : await _repo.follow(widget.userId);
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
    final me = context.select((SessionCubit s) => s.state.userOrNull?.id);
    if (me == widget.userId) return const SizedBox.shrink();
    final following = _following;
    if (widget.expand) {
      return AppButton(
        label: following == true ? 'Following' : 'Follow',
        icon: following == true ? Icons.check_rounded : Icons.person_add_alt_1_rounded,
        style: following == true ? AppButtonStyle.outlined : AppButtonStyle.primary,
        height: 42,
        onPressed: following == null || _busy ? null : _toggle,
      );
    }
    return AppButton.small(
      label: following == true ? 'Following' : 'Follow',
      style: following == true ? AppButtonStyle.outlined : AppButtonStyle.primary,
      onPressed: following == null || _busy ? null : _toggle,
    );
  }
}
