import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../widgets/app_avatar.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  int _tabIndex = 0; // 0=All Chats, 1=Direct, 2=Channels
  final _searchController = TextEditingController();

  final _chats = [
    _Chat(
      name: 'Sarah Jenkins',
      lastMessage: '\$ETH: Take a look at that \$ETH setu...',
      time: '2m ago',
      unread: 1,
      isOnline: true,
      badge: '🔵 Long \$3,420 • Risk/Reward 3.2',
    ),
    _Chat(
      name: 'Marcus Chen',
      lastMessage: 'Did you close the NVDA short?',
      time: '1h ago',
      isOnline: true,
      tags: ['\$NVDA', 'Position check'],
    ),
    _Chat(
      name: 'Alpha Traders',
      lastMessage: 'Alex: Markets opening flat today, wa...',
      time: '3h ago',
      unread: 5,
      isGroup: true,
      membersOnline: 1248,
      isPro: true,
    ),
    _Chat(
      name: 'Kasun Silva',
      lastMessage: 'Target reached on XAU/USD! +45 pip ✓',
      time: 'Yesterday',
      isOnline: false,
      badge: '🟡 +45 Pips Profit',
    ),
    _Chat(
      name: 'Elena Rostova',
      lastMessage: 'Thanks for sharing the chart! Will revi...',
      time: 'Tuesday',
      isOnline: false,
      attachment: '1 snapshot attached',
    ),
  ];

  final _activeTraders = [
    ('Share Idea', null, Icons.add_rounded),
    ('Sarah J.', null, null),
    ('Marcus', null, null),
    ('Kasun P.', null, null),
    ('Elena R.', null, null),
    ('Alex', null, null),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildSearch(),
            _buildActiveTraders(),
            _buildTabs(),
            const SizedBox(height: 4),
            Expanded(
              child: ListView.separated(
                itemCount: _chats.length + 1,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1),
                itemBuilder: (context, index) {
                  if (index == _chats.length) {
                    return _buildBroadcastBanner();
                  }
                  return _ChatTile(chat: _chats[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.show_chart_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Text('Home', style: AppTextStyles.headlineSmall),
          const Spacer(),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: cs.surface,
                shape: BoxShape.circle,
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Icon(Icons.search_rounded, size: 20, color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 8),
          Stack(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: cs.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Icon(Icons.notifications_outlined, size: 20, color: cs.onSurfaceVariant),
              ),
              Positioned(
                top: 6, right: 6,
                child: Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(color: AppColors.badge, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          const AppAvatar(name: 'Alex', size: 40),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Row(
            children: [
              Text('Messages', style: AppTextStyles.headlineLarge),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('3 Unread',
                    style: AppTextStyles.caption.copyWith(color: Colors.white)),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Icon(Icons.tune_rounded, size: 18, color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.edit_rounded, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTraders() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('ACTIVE TRADERS', style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1.5)),
              const SizedBox(width: 8),
              Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Text('Live Floor', style: AppTextStyles.caption.copyWith(color: AppColors.success)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _activeTraders.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final (name, avatar, plusIcon) = _activeTraders[index];
                final isAdd = plusIcon != null;
                return Column(
                  children: [
                    if (isAdd)
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 1.5),
                        ),
                        child: Icon(plusIcon, color: AppColors.primary, size: 22),
                      )
                    else
                      AppAvatar(name: name, size: 48, isOnline: index < 4),
                    const SizedBox(height: 4),
                    Text(name, style: AppTextStyles.caption),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final cs = Theme.of(context).colorScheme;
    final tabs = ['All Chats', 'Direct (4)', 'Channels (1)'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: tabs.asMap().entries.map((e) {
          final isSelected = e.key == _tabIndex;
          return GestureDetector(
            onTap: () => setState(() => _tabIndex = e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primarySurface : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : cs.outlineVariant,
                ),
              ),
              child: Text(e.value,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isSelected ? AppColors.primary : cs.onSurfaceVariant,
                  )),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBroadcastBanner() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.cell_tower_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Broadcast Trade Signal', style: AppTextStyles.titleMedium),
                Text('Push a live setup to all followers',
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Text('Broadcast',
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _Chat {
  final String name;
  final String lastMessage;
  final String time;
  final int unread;
  final bool isOnline;
  final bool isGroup;
  final bool isPro;
  final int? membersOnline;
  final String? badge;
  final List<String>? tags;
  final String? attachment;

  _Chat({
    required this.name,
    required this.lastMessage,
    required this.time,
    this.unread = 0,
    this.isOnline = false,
    this.isGroup = false,
    this.isPro = false,
    this.membersOnline,
    this.badge,
    this.tags,
    this.attachment,
  });
}

class _ChatTile extends StatelessWidget {
  final _Chat chat;
  const _ChatTile({required this.chat});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppAvatar(
              name: chat.name,
              size: 50,
              isOnline: chat.isOnline,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text(chat.name, style: AppTextStyles.titleMedium),
                            if (chat.isPro) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('PRO',
                                    style: AppTextStyles.labelSmall
                                        .copyWith(color: Colors.white, fontSize: 9)),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Text(chat.time, style: AppTextStyles.caption),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(chat.lastMessage,
                            style: AppTextStyles.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (chat.unread > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(chat.unread.toString(),
                              style: AppTextStyles.labelSmall
                                  .copyWith(color: Colors.white, fontSize: 10)),
                        ),
                      ] else ...[
                        const Icon(Icons.done_all_rounded,
                            size: 14, color: AppColors.primary),
                      ],
                    ],
                  ),
                  if (chat.badge != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.bullishLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(chat.badge!,
                          style: AppTextStyles.caption.copyWith(color: AppColors.bullish)),
                    ),
                  ],
                  if (chat.tags != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: chat.tags!
                          .map((tag) => Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(tag, style: AppTextStyles.caption),
                              ))
                          .toList(),
                    ),
                  ],
                  if (chat.attachment != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.attach_file_rounded,
                            size: 12, color: cs.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(chat.attachment!, style: AppTextStyles.caption),
                      ],
                    ),
                  ],
                  if (chat.membersOnline != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.alarm_rounded,
                            size: 12, color: cs.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text('${chat.membersOnline} members online',
                            style: AppTextStyles.caption),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
