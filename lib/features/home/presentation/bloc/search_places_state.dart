import 'package:atlas/features/home/domain/entity/recommendation_entity.dart';
import 'package:atlas/features/home/domain/entity/search_places_filter_entity.dart';

class SearchPlacesState {
  final String query;
  final bool isLoading;
  final bool hasSearched;
  final String errorMessage;
  final List<RecommendationEntity> results;
  final List<String> recentQueries;
  final SearchPlacesFilterEntity filters;

  const SearchPlacesState({
    this.query = '',
    this.isLoading = false,
    this.hasSearched = false,
    this.errorMessage = '',
    this.results = const [],
    this.recentQueries = const [],
    this.filters = SearchPlacesFilterEntity.empty,
  });

  bool get hasQuery => query.trim().isNotEmpty;
  bool get hasError => errorMessage.isNotEmpty;

  SearchPlacesState copyWith({
    String? query,
    bool? isLoading,
    bool? hasSearched,
    String? errorMessage,
    List<RecommendationEntity>? results,
    List<String>? recentQueries,
    SearchPlacesFilterEntity? filters,
  }) {
    return SearchPlacesState(
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      hasSearched: hasSearched ?? this.hasSearched,
      errorMessage: errorMessage ?? this.errorMessage,
      results: results ?? this.results,
      recentQueries: recentQueries ?? this.recentQueries,
      filters: filters ?? this.filters,
    );
  }
}
