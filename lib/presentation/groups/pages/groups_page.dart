import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../widgets/trading_book_app_bar.dart';

class GroupsPage extends StatelessWidget {
  const GroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TradingBookAppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
            splashRadius: 24,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildFeaturedLabel()),
            SliverToBoxAdapter(child: _buildFeaturedGroups(context)),
            SliverToBoxAdapter(child: _buildAllLabel(context)),
            SliverToBoxAdapter(child: _buildAllGroups(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedLabel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Communities', style: AppTextStyles.headlineLarge),
          const SizedBox(height: 4),
          Text('Find your tribe and trade together.',
              style: AppTextStyles.bodySmall),
          const SizedBox(height: 16),
          Text('FEATURED',
              style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildFeaturedGroups(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final featured = [
      ('Crypto Alpha', '42.5k Members', Icons.trending_up_rounded),
      ('Forex Kings', '18.2k Members', Icons.equalizer_rounded),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: featured.map((g) {
          final (name, members, icon) = g;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTextStyles.headlineSmall),
                      const SizedBox(height: 2),
                      Text(members, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                const _JoinButton(isMember: false),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAllLabel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        'ALL COMMUNITIES',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildAllGroups(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final groups = [
      ('Swing Traders', '8.9k Members', Icons.swap_horiz_rounded, false),
      ('Trading Psych', '5.1k Members', Icons.psychology_outlined, false),
      ('Meme Coin Degens', '99k Members', Icons.rocket_launch_outlined, false),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: groups.map((g) {
          final (name, members, icon, joined) = g;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: cs.onSurfaceVariant, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTextStyles.titleMedium),
                      Text(members, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                _JoinButton(isMember: joined),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _JoinButton extends StatefulWidget {
  final bool isMember;
  const _JoinButton({required this.isMember});

  @override
  State<_JoinButton> createState() => _JoinButtonState();
}

class _JoinButtonState extends State<_JoinButton> {
  late bool _isMember;

  @override
  void initState() {
    super.initState();
    _isMember = widget.isMember;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => setState(() => _isMember = !_isMember),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: _isMember ? cs.surface : AppColors.primary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isMember ? cs.outlineVariant : Colors.transparent,
          ),
        ),
        child: Text(
          _isMember ? 'Joined' : 'Join',
          style: AppTextStyles.labelMedium.copyWith(
            color: _isMember ? cs.onSurfaceVariant : Colors.white,
          ),
        ),
      ),
    );
  }
}
