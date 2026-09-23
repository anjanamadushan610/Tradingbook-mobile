import 'package:equatable/equatable.dart';
import '../../../domain/entities/market.dart';

abstract class MarketsState extends Equatable {
  const MarketsState();
  @override
  List<Object?> get props => [];
}

class MarketsInitial extends MarketsState {
  const MarketsInitial();
}

class MarketsLoading extends MarketsState {
  const MarketsLoading();
}

class MarketsLoaded extends MarketsState {
  /// The complete unfiltered list from the API.
  final List<Market> allMarkets;

  /// The currently displayed subset (after category filter).
  final List<Market> displayedMarkets;

  /// Index into the category tab bar (0 = All, 1 = Forex, 2 = Crypto, etc.)
  final int categoryIndex;

  /// The current active search query (empty if no search).
  final String searchQuery;

  const MarketsLoaded({
    required this.allMarkets,
    required this.displayedMarkets,
    this.categoryIndex = 0,
    this.searchQuery = '',
  });

  MarketsLoaded copyWith({
    List<Market>? allMarkets,
    List<Market>? displayedMarkets,
    int? categoryIndex,
    String? searchQuery,
  }) {
    return MarketsLoaded(
      allMarkets: allMarkets ?? this.allMarkets,
      displayedMarkets: displayedMarkets ?? this.displayedMarkets,
      categoryIndex: categoryIndex ?? this.categoryIndex,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [allMarkets, displayedMarkets, categoryIndex, searchQuery];
}

class MarketsError extends MarketsState {
  final String message;
  const MarketsError(this.message);
  @override
  List<Object?> get props => [message];
}
