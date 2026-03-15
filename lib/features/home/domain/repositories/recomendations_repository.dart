import 'package:dartz/dartz.dart';
import 'package:atlas/core/errors/app_exception.dart';
import 'package:atlas/features/home/domain/entity/recommendation_entity.dart';

abstract class RecommendationsRepository {
  Future<Either<AppException, List<RecommendationEntity>>> getRecommendations(
    List<String> categoryTypes,
  );
}
