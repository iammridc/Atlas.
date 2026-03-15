import 'package:atlas/features/home/domain/entity/recommendation_entity.dart';

abstract class RecommendationsState {}

class RecommendationsInitial extends RecommendationsState {}

class RecommendationsLoading extends RecommendationsState {}

class RecommendationsLoaded extends RecommendationsState {
  final List<RecommendationEntity> recommendations;
  final bool isLoadingMore;

  RecommendationsLoaded({
    required this.recommendations,
    this.isLoadingMore = false,
  });
}

class RecommendationsError extends RecommendationsState {
  final String message;
  RecommendationsError(this.message);
}
