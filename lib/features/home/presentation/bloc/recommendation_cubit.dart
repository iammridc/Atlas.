import 'dart:math';
import 'package:atlas/features/home/domain/entity/recommendation_entity.dart';
import 'package:atlas/features/home/domain/usecases/get_recommendations_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'recommendations_state.dart';

class RecommendationsCubit extends Cubit<RecommendationsState> {
  final GetRecommendationsUseCase _getRecommendations;

  List<RecommendationEntity> _displayed = [];
  List<RecommendationEntity> _cached = [];
  List<String> _categoryTypes = [];
  static const _pageSize = 10;

  RecommendationsCubit({required GetRecommendationsUseCase getRecommendations})
    : _getRecommendations = getRecommendations,
      super(RecommendationsInitial());

  Future<void> loadRecommendations(List<String> categoryTypes) async {
    _categoryTypes = categoryTypes;
    _displayed = [];
    _cached = [];

    emit(RecommendationsLoading());

    final result = await _getRecommendations(categoryTypes);

    result.fold((exception) => emit(RecommendationsError(exception.message)), (
      places,
    ) {
      _mergeFreshRecommendations(places);
      if (_cached.isEmpty) {
        emit(RecommendationsLoaded(recommendations: _displayed));
        return;
      }
      _appendNextPage();
    });
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! RecommendationsLoaded || current.isLoadingMore) return;

    emit(
      RecommendationsLoaded(recommendations: _displayed, isLoadingMore: true),
    );

    if (_cached.length >= _pageSize) {
      _appendNextPage();
      return;
    }

    final result = await _getRecommendations(_categoryTypes);

    result.fold((exception) => emit(RecommendationsError(exception.message)), (
      places,
    ) {
      _mergeFreshRecommendations(places);
      if (_cached.isEmpty) {
        emit(RecommendationsLoaded(recommendations: _displayed));
        return;
      }
      _appendNextPage();
    });
  }

  Future<void> reload() async {
    if (state is RecommendationsError) {
      emit(
        RecommendationsError(
          (state as RecommendationsError).message,
          isReloading: true,
        ),
      );
    }
    await loadRecommendations(_categoryTypes);
  }

  void _appendNextPage() {
    final nextItems = _cached.take(_pageSize).toList();
    _cached = _cached.skip(_pageSize).toList();
    _displayed = [..._displayed, ...nextItems];
    emit(RecommendationsLoaded(recommendations: _displayed));
  }

  void _mergeFreshRecommendations(List<RecommendationEntity> places) {
    final seenIds = {
      ..._displayed.map((place) => place.id),
      ..._cached.map((place) => place.id),
    };

    final shuffledPlaces = List<RecommendationEntity>.from(places)
      ..shuffle(Random());

    final uniqueFreshPlaces = shuffledPlaces
        .where((place) => seenIds.add(place.id))
        .toList();

    _cached = [..._cached, ...uniqueFreshPlaces];
  }
}
