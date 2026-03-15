import 'package:dartz/dartz.dart';
import 'package:atlas/core/errors/app_exception.dart';
import 'package:atlas/features/home/domain/entity/recommendation_entity.dart';
import 'package:atlas/features/home/domain/repositories/recommendations_repository.dart';

class GetRecommendationsUseCase {
  final RecommendationsRepository _repository;

  GetRecommendationsUseCase(this._repository);

  Future<Either<AppException, List<RecommendationEntity>>> call(
    List<String> categoryTypes,
  ) {
    return _repository.getRecommendations(categoryTypes);
  }
}
