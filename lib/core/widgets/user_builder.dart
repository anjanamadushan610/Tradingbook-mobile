import 'package:flutter/material.dart';

import '../../data/models/user.dart';
import '../../data/repositories/user_repository.dart';
import '../di/service_locator.dart';

/// Resolves a user id to a profile through the shared, batching cache and
/// rebuilds when it arrives. `null` means unknown/private — render "Trader".
class UserBuilder extends StatefulWidget {
  const UserBuilder({super.key, required this.userId, required this.builder});

  final String userId;
  final Widget Function(BuildContext context, UserProfile? user) builder;

  @override
  State<UserBuilder> createState() => _UserBuilderState();
}

class _UserBuilderState extends State<UserBuilder> {
  final _repo = sl<UserRepository>();
  UserProfile? _user;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(UserBuilder old) {
    super.didUpdateWidget(old);
    if (old.userId != widget.userId) _resolve();
  }

  void _resolve() {
    _user = _repo.cached(widget.userId);
    if (_repo.isCached(widget.userId)) return;
    final id = widget.userId;
    _repo.profile(id).then((p) {
      if (mounted && id == widget.userId) setState(() => _user = p);
    });
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _user);
}
