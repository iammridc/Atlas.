import 'package:atlas/core/errors/app_exception.dart';
import 'package:atlas/features/home/domain/entity/home_map_entity.dart';
import 'package:atlas/features/home/domain/entity/recommendation_entity.dart';
import 'package:dartz/dartz.dart';

abstract class HomeMapRepository {
  Future<Either<AppException, List<RecommendationEntity>>> getNearbyPlaces({
    required HomeMapCoordinateEntity center,
    double radiusMeters = 3000,
  });

  Future<Either<AppException, RecommendationEntity?>> findNearestPlace({
    required HomeMapCoordinateEntity center,
    double radiusMeters = 30,
  });

  Future<Either<AppException, HomeMapLocationEntity?>> resolveLocation({
    required HomeMapCoordinateEntity center,
  });
}
