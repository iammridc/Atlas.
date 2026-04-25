import 'package:atlas/core/errors/app_exception.dart';
import 'package:atlas/features/travel_planner/domain/entities/travel_location_entity.dart';
import 'package:atlas/features/travel_planner/domain/entities/travel_route_entity.dart';
import 'package:dartz/dartz.dart';

abstract class TravelPlannerRepository {
  Future<Either<AppException, TravelRoutePlanEntity>> buildPlan({
    required TravelLocationEntity origin,
    required TravelLocationEntity destination,
  });

  Future<Either<AppException, List<TravelLocationEntity>>> searchLocations(
    String query,
  );

  Future<Either<AppException, TravelLocationEntity?>> reverseGeocodeLocation({
    required double latitude,
    required double longitude,
  });
}
