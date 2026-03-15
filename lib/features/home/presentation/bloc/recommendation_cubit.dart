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
      _cached = places..shuffle(Random());
      _appendNextPage();
    });
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! RecommendationsLoaded || current.isLoadingMore) return;

    if (_cached.length >= _pageSize) {
      _appendNextPage();
      return;
    }

    // otherwise fetch a new batch then append
    emit(
      RecommendationsLoaded(recommendations: _displayed, isLoadingMore: true),
    );

    final result = await _getRecommendations(_categoryTypes);

    result.fold((exception) => emit(RecommendationsError(exception.message)), (
      places,
    ) {
      _cached = places..shuffle(Random());
      _appendNextPage();
    });
  }

  void _appendNextPage() {
    final nextItems = _cached.take(_pageSize).toList();
    _cached = _cached.skip(_pageSize).toList();
    _displayed = [..._displayed, ...nextItems];

    emit(RecommendationsLoaded(recommendations: _displayed));
  }
}
