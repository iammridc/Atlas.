import 'package:atlas/core/errors/app_exception.dart';
import 'package:atlas/features/home/data/datasources/recommendations_remote_datasource.dart';
import 'package:atlas/features/home/domain/entity/recommendation_entity.dart';
import 'package:atlas/features/home/domain/repositories/recommendations_repository.dart';
import 'package:dartz/dartz.dart';

class RecommendationsRepositoryImpl implements RecommendationsRepository {
  final RecommendationsRemoteDatasource _datasource;

  RecommendationsRepositoryImpl(this._datasource);

  @override
  Future<Either<AppException, List<RecommendationEntity>>> getRecommendations(
    List<String> categoryTypes,
  ) async {
    try {
      final recommendations = await _datasource.getRecommendations(
        categoryTypes,
      );
      return Right(recommendations);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownException(message: e.toString()));
    }
  }
}
