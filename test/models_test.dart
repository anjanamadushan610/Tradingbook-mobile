import 'package:flutter_test/flutter_test.dart';
import 'package:trading_book/core/utils/media_urls.dart';
import 'package:trading_book/core/utils/validators.dart';
import 'package:trading_book/data/models/comment.dart';
import 'package:trading_book/data/models/community.dart';
import 'package:trading_book/data/models/post.dart';
import 'package:trading_book/data/models/user.dart';

void main() {
  group('Post.fromJson', () {
    test('reads a feed item (postId, no status) as a live public post', () {
      final p = Post.fromJson({
        'postId': 'p1',
        'authorId': 'u1',
        'type': 'image',
        'caption': 'chart',
        'mediaRefs': ['images/u1/m1/original'],
        'language': 'en',
        'createdAt': 1700000000000,
        'score': 1.2,
      });
      expect(p.id, 'p1');
      expect(p.type, PostType.image);
      expect(p.status, PostStatus.live);
      expect(p.visibility, PostVisibility.public);
    });

    test('reads a PostRecord with status, visibility and counts', () {
      final p = Post.fromJson({
        'id': 'p2',
        'authorId': 'u1',
        'type': 'text',
        'caption': 'x',
        'status': 'pending_group',
        'visibility': 'followers_only',
        'groupId': 'g1',
        'rejectedReason': null,
        'likeCount': 3,
        'commentCount': 1,
        'createdAt': 1,
      });
      expect(p.status, PostStatus.pendingGroup);
      expect(p.status.isInReview, isTrue);
      expect(p.visibility, PostVisibility.followersOnly);
      expect(p.isCommunityPost, isTrue);
      expect(p.likeCount, 3);
    });

    test('tolerates missing optional fields', () {
      final p = Post.fromJson({'id': 'p3', 'authorId': 'u', 'createdAt': 0});
      expect(p.caption, '');
      expect(p.mediaRefs, isEmpty);
      expect(p.type, PostType.text);
    });
  });

  test('UserProfile distinguishes social accounts and moderators', () {
    final social = UserProfile.fromJson({
      'id': 'u',
      'displayName': 'A',
      'createdAt': 0,
      'authProvider': 'google',
      'platformRole': 'moderator',
    });
    expect(social.hasPassword, isFalse);
    expect(social.isModerator, isTrue);
    final plain = UserProfile.fromJson({'id': 'u', 'displayName': 'B', 'createdAt': 0});
    expect(plain.hasPassword, isTrue);
    expect(plain.isModerator, isFalse);
  });

  test('FollowCounts accepts both response spellings', () {
    expect(FollowCounts.fromJson({'followers': 2, 'following': 3}).following, 3);
    expect(FollowCounts.fromJson({'followersCount': 5, 'followingCount': 1}).followers, 5);
  });

  test('Comment reads body/content and parentCommentId/parentId', () {
    final c = Comment.fromJson({
      'id': 'c',
      'postId': 'p',
      'authorId': 'u',
      'content': 'hi',
      'parentId': 'c0',
      'createdAt': 0,
    });
    expect(c.body, 'hi');
    expect(c.isReply, isTrue);
  });

  test('Group reads visibility; CommunityPage reads coverImageUrl', () {
    expect(Group.fromJson({'id': 'g', 'name': 'G', 'visibility': 'private', 'ownerId': 'o', 'createdAt': 0}).isPrivate,
        isTrue);
    expect(
      CommunityPage.fromJson({'id': 'p', 'name': 'P', 'ownerId': 'o', 'coverImageUrl': 'https://x/c.png', 'createdAt': 0})
          .coverUrl,
      'https://x/c.png',
    );
    expect(GroupRole.admin.canManage, isTrue);
    expect(GroupRole.moderator.canManage, isFalse);
  });

  group('MediaUrls', () {
    test('maps an original upload key to its WebP variant', () {
      expect(
        MediaUrls.image('images/u/m/original'),
        'https://media.tradingbooknet.com/images/u/m/feed.webp',
      );
      expect(
        MediaUrls.image('images/u/m/original', ImageVariant.thumbnail),
        'https://media.tradingbooknet.com/images/u/m/thumbnail.webp',
      );
      expect(MediaUrls.original('images/u/m/original'), 'https://media.tradingbooknet.com/images/u/m/original');
    });

    test('leaves absolute URLs and non-original keys alone', () {
      expect(MediaUrls.image('https://cdn/x.png'), 'https://cdn/x.png');
      expect(MediaUrls.image('streamuid'), 'https://media.tradingbooknet.com/streamuid');
    });
  });

  group('Validators.newPassword mirrors the backend policy', () {
    test('rejects short, banned and single-class passwords', () {
      expect(Validators.newPassword('short1'), isNotNull);
      expect(Validators.newPassword('password123'), isNotNull);
      expect(Validators.newPassword('TradingBook'), isNotNull);
      expect(Validators.newPassword('abcdefgh'), isNotNull);
    });

    test('accepts two classes, or 14+ varied characters', () {
      expect(Validators.newPassword('abcdefg1'), isNull);
      expect(Validators.newPassword('correct horse battery'), isNull);
      expect(Validators.newPassword('aaaaaaaaaaaaaaaa'), isNotNull);
    });

    test('email validation', () {
      expect(Validators.email('a@b.co'), isNull);
      expect(Validators.email('nope'), isNotNull);
    });
  });
}
