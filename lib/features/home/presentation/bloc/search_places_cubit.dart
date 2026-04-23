import 'dart:async';

import 'package:atlas/features/home/domain/usecases/search_places_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'search_places_state.dart';

class SearchPlacesCubit extends Cubit<SearchPlacesState> {
  final SearchPlacesUseCase _searchPlaces;

  Timer? _searchDebounce;
  int _activeRequestId = 0;
  bool _isInitialized = false;

  static const _recentQueriesKey = 'atlas_recent_search_queries';
  static const _recentLimit = 6;
  static const _debounceDuration = Duration(milliseconds: 350);

  SearchPlacesCubit({required SearchPlacesUseCase searchPlaces})
    : _searchPlaces = searchPlaces,
      super(const SearchPlacesState());

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    final prefs = await SharedPreferences.getInstance();
    final recentQueries = prefs.getStringList(_recentQueriesKey) ?? const [];

    emit(state.copyWith(recentQueries: recentQueries));
  }

  Future<void> onQueryChanged(String query) async {
    _searchDebounce?.cancel();
    emit(state.copyWith(query: query, errorMessage: ''));

    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      _activeRequestId++;
      emit(
        state.copyWith(
          query: query,
          isLoading: false,
          hasSearched: false,
          errorMessage: '',
          results: const [],
        ),
      );
      return;
    }

    _searchDebounce = Timer(
      _debounceDuration,
      () => _performSearch(trimmedQuery),
    );
  }

  Future<void> searchNow(String query, {bool saveToRecent = true}) async {
    _searchDebounce?.cancel();

    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      await onQueryChanged('');
      return;
    }

    emit(state.copyWith(query: query, errorMessage: ''));
    await _performSearch(trimmedQuery, saveToRecent: saveToRecent);
  }

  Future<void> retry() async {
    final trimmedQuery = state.query.trim();
    if (trimmedQuery.isEmpty) return;
    await _performSearch(trimmedQuery);
  }

  Future<void> saveCurrentQuery() async {
    await _saveRecentQuery(state.query);
  }

  Future<void> removeRecentQuery(String query) async {
    final updatedQueries = state.recentQueries
        .where((item) => item != query)
        .toList();
    emit(state.copyWith(recentQueries: updatedQueries));
    await _persistRecentQueries(updatedQueries);
  }

  Future<void> clearRecentQueries() async {
    emit(state.copyWith(recentQueries: const []));
    await _persistRecentQueries(const []);
  }

  Future<void> _performSearch(String query, {bool saveToRecent = false}) async {
    final requestId = ++_activeRequestId;

    emit(
      state.copyWith(
        isLoading: true,
        hasSearched: true,
        errorMessage: '',
        results: const [],
      ),
    );

    final result = await _searchPlaces(query);

    if (requestId != _activeRequestId) return;

    result.fold(
      (exception) => emit(
        state.copyWith(
          isLoading: false,
          hasSearched: true,
          errorMessage: exception.message,
          results: const [],
        ),
      ),
      (places) => emit(
        state.copyWith(
          isLoading: false,
          hasSearched: true,
          errorMessage: '',
          results: places,
        ),
      ),
    );

    if (saveToRecent && result.isRight()) {
      await _saveRecentQuery(query);
    }
  }

  Future<void> _saveRecentQuery(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;

    final updatedQueries = [
      trimmedQuery,
      ...state.recentQueries.where(
        (item) => item.toLowerCase() != trimmedQuery.toLowerCase(),
      ),
    ].take(_recentLimit).toList();

    emit(state.copyWith(recentQueries: updatedQueries));
    await _persistRecentQueries(updatedQueries);
  }

  Future<void> _persistRecentQueries(List<String> queries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentQueriesKey, queries);
  }

  @override
  Future<void> close() async {
    _searchDebounce?.cancel();
    await super.close();
  }
}
