import 'package:atlas/core/errors/app_exception.dart';
import 'package:atlas/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:atlas/features/profile/domain/entities/favorite_place_entity.dart';
import 'package:atlas/features/profile/domain/entities/planned_trip_entity.dart';
import 'package:atlas/features/profile/domain/entities/profile_review_entity.dart';
import 'package:atlas/features/profile/domain/entities/profile_summary_entity.dart';
import 'package:atlas/features/profile/domain/repositories/profile_repository.dart';
import 'package:dartz/dartz.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDatasource _datasource;

  ProfileRepositoryImpl(this._datasource);

  @override
  Future<Either<AppException, ProfileSummaryEntity>> getProfileSummary() async {
    try {
      final summary = await _datasource.getProfileSummary();
      return Right(summary);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownException(message: e.toString()));
    }
  }

  @override
  Future<Either<AppException, void>> updateUsername(String username) async {
    try {
      await _datasource.updateUsername(username);
      return const Right(null);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownException(message: e.toString()));
    }
  }

  @override
  Future<Either<AppException, void>> updateAvatar(String? avatarUrl) async {
    try {
      await _datasource.updateAvatar(avatarUrl);
      return const Right(null);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownException(message: e.toString()));
    }
  }

  @override
  Future<Either<AppException, bool>> isFavoritePlace(String id) async {
    try {
      final isFavorite = await _datasource.isFavoritePlace(id);
      return Right(isFavorite);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownException(message: e.toString()));
    }
  }

  @override
  Future<Either<AppException, List<FavoritePlaceEntity>>>
  getFavoritePlaces() async {
    try {
      final places = await _datasource.getFavoritePlaces();
      return Right(places);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownException(message: e.toString()));
    }
  }

  @override
  Future<Either<AppException, FavoritePlaceEntity>> saveFavoritePlace(
    FavoritePlaceEntity place,
  ) async {
    try {
      final savedPlace = await _datasource.saveFavoritePlace(place);
      return Right(savedPlace);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownException(message: e.toString()));
    }
  }

  @override
  Future<Either<AppException, void>> deleteFavoritePlace(String id) async {
    try {
      await _datasource.deleteFavoritePlace(id);
      return const Right(null);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownException(message: e.toString()));
    }
  }

  @override
  Future<Either<AppException, List<ProfileReviewEntity>>>
  getProfileReviews() async {
    try {
      final reviews = await _datasource.getProfileReviews();
      return Right(reviews);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownException(message: e.toString()));
    }
  }

  @override
  Future<Either<AppException, ProfileReviewEntity?>> getProfileReviewForPlace(
    String placeId,
  ) async {
    try {
      final review = await _datasource.getProfileReviewForPlace(placeId);
      return Right(review);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownException(message: e.toString()));
    }
  }

  @override
  Future<Either<AppException, ProfileReviewEntity>> saveProfileReview(
    ProfileReviewEntity review,
  ) async {
    try {
      final savedReview = await _datasource.saveProfileReview(review);
      return Right(savedReview);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownException(message: e.toString()));
    }
  }

  @override
  Future<Either<AppException, void>> deleteProfileReview(
    ProfileReviewEntity review,
  ) async {
    try {
      await _datasource.deleteProfileReview(review);
      return const Right(null);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownException(message: e.toString()));
    }
  }

  @override
  Future<Either<AppException, List<PlannedTripEntity>>>
  getPlannedTrips() async {
    try {
      final trips = await _datasource.getPlannedTrips();
      return Right(trips);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownException(message: e.toString()));
    }
  }

  @override
  Future<Either<AppException, PlannedTripEntity>> savePlannedTrip(
    PlannedTripEntity trip,
  ) async {
    try {
      final savedTrip = await _datasource.savePlannedTrip(trip);
      return Right(savedTrip);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownException(message: e.toString()));
    }
  }

  @override
  Future<Either<AppException, void>> deletePlannedTrip(String id) async {
    try {
      await _datasource.deletePlannedTrip(id);
      return const Right(null);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownException(message: e.toString()));
    }
  }
}
