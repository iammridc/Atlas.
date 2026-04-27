import 'package:atlas/core/errors/app_exception.dart';
import 'package:atlas/features/home/data/datasources/home_map_remote_datasource.dart';
import 'package:atlas/features/home/domain/entity/home_map_entity.dart';
import 'package:atlas/features/home/domain/entity/recommendation_entity.dart';
import 'package:atlas/features/home/domain/repositories/home_map_repository.dart';
import 'package:dartz/dartz.dart';

class HomeMapRepositoryImpl implements HomeMapRepository {
  final HomeMapRemoteDatasource _datasource;

  const HomeMapRepositoryImpl(this._datasource);

  @override
  Future<Either<AppException, List<RecommendationEntity>>> getNearbyPlaces({
    required HomeMapCoordinateEntity center,
    double radiusMeters = 3000,
  }) async {
    try {
      final places = await _datasource.getNearbyPlaces(
        center: center,
        radiusMeters: radiusMeters,
      );
      return Right(places);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownException(message: e.toString()));
    }
  }

  @override
  Future<Either<AppException, RecommendationEntity?>> findNearestPlace({
    required HomeMapCoordinateEntity center,
    double radiusMeters = 30,
  }) async {
    try {
      final place = await _datasource.findNearestPlace(
        center: center,
        radiusMeters: radiusMeters,
      );
      return Right(place);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownException(message: e.toString()));
    }
  }

  @override
  Future<Either<AppException, HomeMapLocationEntity?>> resolveLocation({
    required HomeMapCoordinateEntity center,
  }) async {
    try {
      final location = await _datasource.resolveLocation(center: center);
      return Right(location);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownException(message: e.toString()));
    }
  }
}
