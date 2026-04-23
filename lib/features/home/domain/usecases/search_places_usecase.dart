import 'package:atlas/core/errors/app_exception.dart';
import 'package:atlas/features/home/domain/entity/recommendation_entity.dart';
import 'package:atlas/features/home/domain/repositories/recommendations_repository.dart';
import 'package:dartz/dartz.dart';

class SearchPlacesUseCase {
  final RecommendationsRepository _repository;

  SearchPlacesUseCase(this._repository);

  Future<Either<AppException, List<RecommendationEntity>>> call(String query) {
    return _repository.searchPlaces(query);
  }
}
