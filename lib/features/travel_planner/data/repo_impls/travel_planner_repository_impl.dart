import 'package:atlas/core/errors/app_exception.dart';
import 'package:atlas/features/travel_planner/data/datasources/travel_planner_remote_datasource.dart';
import 'package:atlas/features/travel_planner/domain/entities/travel_location_entity.dart';
import 'package:atlas/features/travel_planner/domain/entities/travel_route_entity.dart';
import 'package:atlas/features/travel_planner/domain/repositories/travel_planner_repository.dart';
import 'package:dartz/dartz.dart';

class TravelPlannerRepositoryImpl implements TravelPlannerRepository {
  final TravelPlannerRemoteDatasource _datasource;

  TravelPlannerRepositoryImpl(this._datasource);

  @override
  Future<Either<AppException, TravelRoutePlanEntity>> buildPlan({
    required TravelLocationEntity origin,
    required TravelLocationEntity destination,
  }) async {
    try {
      final googleRoutes = await _fallbackToEmptyRoutes(
        _datasource.getGoogleRoutes(origin: origin, destination: destination),
      );
      final flightRoutes = await _datasource.getFlightRoutes(
        origin: origin,
        destination: destination,
      );
      final pointsOfInterest = await _fallbackToEmptyStops(
        _datasource.getNearbyPointsOfInterest(destination),
      );
      final hotels = await _fallbackToEmptyStops(
        _datasource.getNearbyHotels(destination),
      );
      final combinedRoutes = [...googleRoutes, ...flightRoutes];

      return Right(
        TravelRoutePlanEntity(
          origin: origin,
          destination: destination,
          routes: _orderRoutes(_limitRoutesPerTransport(combinedRoutes)),
          pointsOfInterest: pointsOfInterest,
          hotels: hotels,
        ),
      );
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownException(message: e.toString()));
    }
  }

  @override
  Future<Either<AppException, List<TravelLocationEntity>>> searchLocations(
    String query,
  ) async {
    try {
      final locations = await _datasource.searchLocations(query);
      return Right(locations);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownException(message: e.toString()));
    }
  }

  @override
  Future<Either<AppException, TravelLocationEntity?>> reverseGeocodeLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final location = await _datasource.reverseGeocodeLocation(
        latitude: latitude,
        longitude: longitude,
      );
      return Right(location);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownException(message: e.toString()));
    }
  }

  Future<List<TravelRouteEntity>> _fallbackToEmptyRoutes(
    Future<List<TravelRouteEntity>> future,
  ) async {
    try {
      return await future;
    } catch (_) {
      return const [];
    }
  }

  Future<List<TravelStopEntity>> _fallbackToEmptyStops(
    Future<List<TravelStopEntity>> future,
  ) async {
    try {
      return await future;
    } catch (_) {
      return const [];
    }
  }

  List<TravelRouteEntity> _limitRoutesPerTransport(
    List<TravelRouteEntity> routes,
  ) {
    final counts = <TravelTransportType, int>{};
    final limitedRoutes = <TravelRouteEntity>[];

    for (final route in routes) {
      final count = counts[route.transportType] ?? 0;
      if (count >= 2) continue;

      counts[route.transportType] = count + 1;
      limitedRoutes.add(route);
    }

    return limitedRoutes;
  }

  List<TravelRouteEntity> _orderRoutes(List<TravelRouteEntity> routes) {
    final orderedRoutes = [...routes];

    orderedRoutes.sort((a, b) {
      final typeComparison = _transportOrder(
        a.transportType,
      ).compareTo(_transportOrder(b.transportType));
      if (typeComparison != 0) return typeComparison;

      return a.duration.compareTo(b.duration);
    });

    return orderedRoutes;
  }

  int _transportOrder(TravelTransportType type) {
    return switch (type) {
      TravelTransportType.car => 0,
      TravelTransportType.train => 1,
      TravelTransportType.bus => 2,
      TravelTransportType.flight => 3,
      TravelTransportType.best => 4,
    };
  }
}
