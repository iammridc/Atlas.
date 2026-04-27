import 'package:atlas/core/errors/app_exception.dart';
import 'package:atlas/features/home/domain/entity/home_map_entity.dart';
import 'package:atlas/features/home/domain/entity/recommendation_entity.dart';
import 'package:atlas/features/home/domain/repositories/home_map_repository.dart';
import 'package:dartz/dartz.dart';

class GetNearbyMapPlacesUseCase {
  final HomeMapRepository _repository;

  const GetNearbyMapPlacesUseCase(this._repository);

  Future<Either<AppException, List<RecommendationEntity>>> call({
    required HomeMapCoordinateEntity center,
    double radiusMeters = 3000,
  }) {
    return _repository.getNearbyPlaces(
      center: center,
      radiusMeters: radiusMeters,
    );
  }
}

class FindNearestMapPlaceUseCase {
  final HomeMapRepository _repository;

  const FindNearestMapPlaceUseCase(this._repository);

  Future<Either<AppException, RecommendationEntity?>> call({
    required HomeMapCoordinateEntity center,
    double radiusMeters = 30,
  }) {
    return _repository.findNearestPlace(
      center: center,
      radiusMeters: radiusMeters,
    );
  }
}

class ResolveHomeMapLocationUseCase {
  final HomeMapRepository _repository;

  const ResolveHomeMapLocationUseCase(this._repository);

  Future<Either<AppException, HomeMapLocationEntity?>> call({
    required HomeMapCoordinateEntity center,
  }) {
    return _repository.resolveLocation(center: center);
  }
}
