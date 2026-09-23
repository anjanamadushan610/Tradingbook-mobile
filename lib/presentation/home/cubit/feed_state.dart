import 'package:equatable/equatable.dart';
import '../../../domain/entities/post.dart';

abstract class FeedState extends Equatable {
  const FeedState();
  @override
  List<Object?> get props => [];
}

class FeedInitial extends FeedState {
  const FeedInitial();
}

class FeedLoading extends FeedState {
  const FeedLoading();
}

class FeedLoaded extends FeedState {
  final List<Post> posts;
  final String? nextCursor;
  final bool isLoadingMore;

  const FeedLoaded({
    required this.posts,
    this.nextCursor,
    this.isLoadingMore = false,
  });

  FeedLoaded copyWith({
    List<Post>? posts,
    String? nextCursor,
    bool? isLoadingMore,
    bool clearCursor = false,
  }) {
    return FeedLoaded(
      posts: posts ?? this.posts,
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [posts, nextCursor, isLoadingMore];
}

class FeedError extends FeedState {
  final String message;
  const FeedError(this.message);
  @override
  List<Object?> get props => [message];
}
