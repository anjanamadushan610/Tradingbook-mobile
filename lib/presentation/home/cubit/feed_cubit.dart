import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/feed_repository.dart';
import 'feed_state.dart';

class FeedCubit extends Cubit<FeedState> {
  final FeedRepository _feedRepository;
  final PostsRepository _postsRepository;

  FeedCubit({
    required FeedRepository feedRepository,
    required PostsRepository postsRepository,
  })  : _feedRepository = feedRepository,
        _postsRepository = postsRepository,
        super(const FeedInitial());

  Future<void> loadFeed() async {
    emit(const FeedLoading());
    try {
      final result = await _feedRepository.getFeed(limit: 20);
      emit(FeedLoaded(
        posts: result.items,
        nextCursor: result.nextCursor,
      ));
    } catch (e) {
      emit(FeedError(e.toString()));
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! FeedLoaded) return;
    if (current.nextCursor == null) return;
    if (current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));
    try {
      final result = await _feedRepository.getFeed(
        cursor: current.nextCursor,
        limit: 20,
      );
      emit(current.copyWith(
        posts: [...current.posts, ...result.items],
        nextCursor: result.nextCursor,
        isLoadingMore: false,
      ));
    } catch (_) {
      emit(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> refresh() async {
    await loadFeed();
  }

  Future<void> toggleLike(String postId) async {
    final current = state;
    if (current is! FeedLoaded) return;

    final index = current.posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = current.posts[index];
    final wasLiked = post.hasLiked;

    // Optimistic update
    final updatedPosts = [...current.posts];
    updatedPosts[index] = post.copyWith(
      hasLiked: !wasLiked,
      likeCount: wasLiked ? post.likeCount - 1 : post.likeCount + 1,
    );
    emit(current.copyWith(posts: updatedPosts));

    // API call
    try {
      if (wasLiked) {
        await _postsRepository.unlikePost(postId);
      } else {
        await _postsRepository.likePost(postId);
      }
    } catch (_) {
      // Revert on failure
      final revertedPosts = [...(state as FeedLoaded).posts];
      revertedPosts[index] = post;
      emit((state as FeedLoaded).copyWith(posts: revertedPosts));
    }
  }
}
