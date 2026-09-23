import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:trading_book/core/router/app_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:trading_book/core/network/dio_client.dart';
import 'package:trading_book/domain/repositories/auth_repository.dart';
import 'package:trading_book/domain/repositories/feed_repository.dart';
import 'package:trading_book/presentation/auth/cubit/auth_cubit.dart';
import 'package:trading_book/presentation/profile/widgets/post_card.dart';
import 'package:trading_book/presentation/widgets/app_avatar.dart';
import 'package:trading_book/presentation/profile/models/profile_models.dart';
import 'package:trading_book/presentation/profile/pages/edit_profile_page.dart';
import 'package:trading_book/presentation/profile/pages/edit_privacy_page.dart';
import 'package:trading_book/presentation/groups/pages/groups_page.dart';
import 'package:trading_book/presentation/profile/pages/my_communities_page.dart';

class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  UserModel? _user;
  List<ValueNotifier<PostModel>> _posts = [];
  bool _isLoadingProfile = true;
  bool _isLoadingFeed = true;
  String? _profileError;
  String? _feedError;

  bool get isCurrentUser {
    final authUser = context.read<AuthCubit>().currentUser;
    if (_user == null || authUser == null) return true;
    return authUser.displayName == _user!.name;
  }

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProfile();
    });
  }

  Future<void> _fetchProfile() async {
    final authRepo = context.read<AuthRepository>();
    final dioClient = context.read<DioClient>();

    try {
      final ownUser = await authRepo.getMe();

      int followers = 0;
      int following = 0;
      if (ownUser.id.isNotEmpty) {
        try {
          final countsRes =
              await dioClient.get('/api/social/counts/${ownUser.id}');
          final countsData = countsRes.data['data'] ?? countsRes.data;
          followers = (countsData['followers'] as num?)?.toInt() ?? 0;
          following = (countsData['following'] as num?)?.toInt() ?? 0;
        } catch (_) {}
      }

      List<String> interests = ownUser.interests;
      if (interests.isEmpty) {
        interests = ['btc', 'volatility', 'Options'];
      }

      if (!mounted) return;
      setState(() {
        _user = UserModel(
          name: ownUser.displayName,
          username: '@${ownUser.id}',
          bio: ownUser.bio,
          followers: followers,
          following: following,
          avatarUrl: ownUser.avatarUrl,
          coverUrl: ownUser.coverUrl,
          interests: interests,
        );
        _isLoadingProfile = false;
        _profileError = null;
      });

      await _fetchFeed();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _profileError = 'Failed to load profile';
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _fetchFeed() async {
    final postsRepo = context.read<PostsRepository>();
    try {
      final result = await postsRepo.getMyPosts(limit: 20);
      final parsed = result.items.map((post) {
        return ValueNotifier(PostModel(
          id: post.id,
          authorName: post.authorName ?? _user?.name ?? '',
          authorUsername: _user?.username ?? '',
          date: DateTime.fromMillisecondsSinceEpoch(post.createdAt * 1000)
              .toLocal()
              .toString()
              .substring(0, 10),
          content: post.caption,
          authorAvatarUrl: post.authorAvatarUrl ?? _user?.avatarUrl,
          mediaUrls: post.mediaRefs,
          likes: post.likeCount,
          comments: post.commentCount,
          isLiked: post.hasLiked,
          shares: 0,
          status: post.status.name,
        ));
      }).toList();

      if (!mounted) return;
      setState(() {
        _posts = parsed;
        _isLoadingFeed = false;
        _feedError = null;
      });
    } catch (e) {
      debugPrint('Error loading posts: $e');
      if (!mounted) return;
      setState(() {
        _feedError = 'Error loading posts';
        _isLoadingFeed = false;
      });
    }
  }

  Future<void> _handleLikeToggled(String postId) async {
    final index = _posts.indexWhere((p) => p.value.id == postId);
    if (index == -1) return;

    final notifier = _posts[index];
    final post = notifier.value;
    final wasLiked = post.isLiked;

    notifier.value = post.copyWith(
      isLiked: !wasLiked,
      likes: post.likes + (!wasLiked ? 1 : -1),
    );

    try {
      if (!wasLiked) {
        await context.read<PostsRepository>().likePost(postId);
      } else {
        await context.read<PostsRepository>().unlikePost(postId);
      }
    } catch (e) {
      if (!mounted) return;
      notifier.value = post;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update like')),
      );
    }
  }

  Future<void> _handleBookmarkToggled(String postId) async {
    final index = _posts.indexWhere((p) => p.value.id == postId);
    if (index == -1) return;

    final notifier = _posts[index];
    final post = notifier.value;
    final wasSaved = post.isSaved;

    notifier.value = post.copyWith(isSaved: !wasSaved);

    try {
      await context.read<PostsRepository>().toggleBookmark(postId);
    } catch (e) {
      if (!mounted) return;
      notifier.value = post;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update bookmark')),
      );
    }
  }

  Future<void> _uploadImage(String endpoint, bool isAvatar) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening image picker...')),
    );
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final dioClient = context.read<DioClient>();
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(image.path, filename: image.name),
      });

      final res = await dioClient.post(endpoint, data: formData);
      final responseData = res.data;
      final profile =
          responseData['profile'] ?? responseData['data'] ?? responseData;

      if (mounted) {
        Navigator.pop(context);
        setState(() {
          if (_user != null) {
            _user = UserModel(
              name: _user!.name,
              username: _user!.username,
              bio: _user!.bio,
              followers: _user!.followers,
              following: _user!.following,
              interests: _user!.interests,
              avatarUrl: isAvatar ? profile['avatarUrl'] : _user!.avatarUrl,
              coverUrl: !isAvatar ? profile['coverUrl'] : _user!.coverUrl,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    }
  }

  void _showOptionsMenu(BuildContext btnContext) async {
    final RenderBox button = btnContext.findRenderObject()! as RenderBox;
    final RenderBox overlay = Navigator.of(btnContext)
        .overlay!
        .context
        .findRenderObject()! as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final theme = Theme.of(btnContext);
    final String? value = await showMenu<String>(
      context: btnContext,
      position: position,
      color: theme.colorScheme.surfaceContainer,
      items: [
        PopupMenuItem(
          value: 'edit_profile',
          child: Row(children: [
            Icon(Icons.edit_outlined,
                size: 20, color: theme.colorScheme.onSurface),
            const SizedBox(width: 12),
            Text('Edit Profile',
                style: TextStyle(color: theme.colorScheme.onSurface)),
          ]),
        ),
        PopupMenuItem(
          value: 'edit_privacy',
          child: Row(children: [
            Icon(Icons.public, size: 20, color: theme.colorScheme.onSurface),
            const SizedBox(width: 12),
            Text('Edit Privacy',
                style: TextStyle(color: theme.colorScheme.onSurface)),
          ]),
        ),
        PopupMenuItem(
          value: 'my_groups',
          child: Row(children: [
            Icon(Icons.group_outlined,
                size: 20, color: theme.colorScheme.onSurface),
            const SizedBox(width: 12),
            Text('My Groups',
                style: TextStyle(color: theme.colorScheme.onSurface)),
          ]),
        ),
        PopupMenuItem(
          value: 'my_communities',
          child: Row(children: [
            Icon(Icons.groups, size: 20, color: theme.colorScheme.onSurface),
            const SizedBox(width: 12),
            Text('My Communities',
                style: TextStyle(color: theme.colorScheme.onSurface)),
          ]),
        ),
      ],
    );

    if (value != null && mounted) {
      switch (value) {
        case 'edit_profile':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditProfilePage()),
          );
        case 'edit_privacy':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditPrivacyPage()),
          );
        case 'my_groups':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GroupsPage()),
          );
        case 'my_communities':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyCommunitiesPage()),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoadingProfile && _user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_profileError != null && _user == null) {
      return Scaffold(
        body: Center(child: Text(_profileError!)),
      );
    }

    final user = _user!;

    return Scaffold(
      drawer: _buildDrawer(context, theme, user),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Header Stack (Cover Photo + Action Icons + Avatar Overlap) ──
              // Total stack height: Cover height (150) + Avatar lower half radius (40) = 190
              SizedBox(
                height: 195,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 1. Cover Photo
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 150,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          image: user.coverUrl != null &&
                                  user.coverUrl!.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(user.coverUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                      ),
                    ),

                    // 2. App bar top buttons (Menu & More Options overlay on top of cover)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Builder(
                        builder: (innerContext) => Container(
                          decoration: const BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.menu,
                                color: Colors.white, size: 20),
                            onPressed: () => Scaffold.of(innerContext).openDrawer(),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Builder(
                        builder: (btnContext) => Container(
                          decoration: const BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.more_vert,
                                color: Colors.white, size: 20),
                            padding: EdgeInsets.zero,
                            onPressed: () => _showOptionsMenu(btnContext),
                          ),
                        ),
                      ),
                    ),

                    // 3. Cover Camera Button
                    if (isCurrentUser)
                      Positioned(
                        top: 106,
                        right: 12,
                        child: GestureDetector(
                          onTap: () => _uploadImage('/api/v1/me/cover', false),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface
                                  .withValues(alpha: 0.7),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.camera_alt,
                                size: 18, color: theme.colorScheme.onSurface),
                          ),
                        ),
                      ),

                    // 4. Avatar (Half overlapping the bottom edge of the cover photo)
                    Positioned(
                      top: 105,
                      left: 16,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.scaffoldBackgroundColor,
                                width: 4,
                              ),
                            ),
                            child: AppAvatar(
                              imageUrl: user.avatarUrl,
                              name: user.name,
                              size: 82,
                            ),
                          ),
                          if (isCurrentUser)
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () =>
                                    _uploadImage('/api/v1/me/avatar', true),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: theme.scaffoldBackgroundColor,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    size: 13,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Profile Details Section (Starts immediately beneath overlap) ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + Follow button row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          user.name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (!isCurrentUser)
                          FilledButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Follow clicked')),
                              );
                            },
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            icon: const Icon(Icons.person_add, size: 16),
                            label: const Text('Follow',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),

                    const SizedBox(height: 4),
                    // Followers / Following counts
                    Row(
                      children: [
                        Text(
                          '${user.following}',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Following',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${user.followers}',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Followers',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),

                    // Bio
                    if (user.bio.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        user.bio,
                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                      ),
                    ],

                    // Interests
                    const SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'INTERESTS',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            if (isCurrentUser) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.edit_outlined,
                                  size: 14,
                                  color: theme.colorScheme.onSurfaceVariant),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6.0,
                          runSpacing: 6.0,
                          children: user.interests
                              .map((e) => _buildChip(e, theme))
                              .toList(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Divider(color: theme.colorScheme.outlineVariant, height: 1),
                  ],
                ),
              ),

              // -- Feed Section ----------------------------------------------
              if (_isLoadingFeed)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_feedError != null)
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      _feedError!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                )
              else if (_posts.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: Text('No posts yet')),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    final notifier = _posts[index];
                    return PostCard(
                      key: ValueKey(notifier.value.id),
                      postNotifier: notifier,
                      onDelete: () {
                        setState(() {
                          _posts.removeAt(index);
                        });
                      },
                      onLikeToggled: _handleLikeToggled,
                      onBookmarkToggled: _handleBookmarkToggled,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, ThemeData theme, UserModel? user) {
    return Drawer(
      backgroundColor: const Color(0xFFF8FAFC), // Clean light background
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "Menu" Title
              Text(
                'Menu',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF00647C),
                ),
              ),
              const SizedBox(height: 24),
              
              // Profile Section Card
              GestureDetector(
                onTap: () {
                   Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      AppAvatar(
                        imageUrl: user?.avatarUrl,
                        name: user?.name ?? 'Unknown',
                        size: 40,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                user?.name ?? 'Profile Options',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E293B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF00647C),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'View profile',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, size: 16, color: Color(0xFF94A3B8)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // TRADING HUB Section
              _buildSectionTitle(theme, 'TRADING HUB'),
              _buildMenuCard([
                _buildMenuItem(theme, Icons.explore_outlined, 'Discovered', onTap: () {
                  Navigator.pop(context);
                }),
                _buildMenuItem(theme, Icons.show_chart, 'Market', onTap: () {
                  Navigator.pop(context);
                }),
                _buildMenuItem(theme, Icons.bookmark_border, 'Saved', onTap: () {
                  Navigator.pop(context);
                }),
                _buildMenuItem(theme, Icons.block, 'Blocked List', onTap: () {
                  Navigator.pop(context);
                }),
              ]),
              
              const SizedBox(height: 24),
              // COMMUNITY Section
              _buildSectionTitle(theme, 'COMMUNITY'),
              _buildMenuCard([
                _buildMenuItem(theme, Icons.group_outlined, 'Groups', badgeText: '14 new', onTap: () {
                  Navigator.pop(context);
                }),
                _buildMenuItem(theme, Icons.flag_outlined, 'Pages', onTap: () {
                  Navigator.pop(context);
                }),
              ]),
              
              const SizedBox(height: 24),
              // PREFERENCES Section
              _buildSectionTitle(theme, 'PREFERENCES'),
              _buildMenuCard([
                _buildMenuItem(theme, Icons.settings_outlined, 'Settings', onTap: () {
                  Navigator.pop(context);
                  context.push(AppRoutes.settings);
                }),
                _buildMenuItem(theme, Icons.help_outline, 'Help & Support', onTap: () {
                  Navigator.pop(context);
                }),
              ]),
              
              const SizedBox(height: 32),
              
              // Log Out
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  context.read<AuthCubit>().logout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: const Color(0xFF94A3B8),
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildMenuItem(
    ThemeData theme,
    IconData icon,
    String title, {
    String? badgeText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: const Color(0xFF475569)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF1E293B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (badgeText != null) ...[
              Text(
                badgeText,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF00647C),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(Icons.chevron_right, size: 20, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }
}