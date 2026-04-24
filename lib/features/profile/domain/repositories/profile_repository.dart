import 'package:atlas/core/errors/app_exception.dart';
import 'package:atlas/features/profile/domain/entities/favorite_place_entity.dart';
import 'package:atlas/features/profile/domain/entities/planned_trip_entity.dart';
import 'package:atlas/features/profile/domain/entities/profile_review_entity.dart';
import 'package:atlas/features/profile/domain/entities/profile_summary_entity.dart';
import 'package:dartz/dartz.dart';

abstract class ProfileRepository {
  Future<Either<AppException, ProfileSummaryEntity>> getProfileSummary();
  Future<Either<AppException, void>> updateUsername(String username);
  Future<Either<AppException, void>> updateAvatar(String? avatarUrl);
  Future<Either<AppException, bool>> isFavoritePlace(String id);
  Future<Either<AppException, List<FavoritePlaceEntity>>> getFavoritePlaces();
  Future<Either<AppException, FavoritePlaceEntity>> saveFavoritePlace(
    FavoritePlaceEntity place,
  );
  Future<Either<AppException, void>> deleteFavoritePlace(String id);
  Future<Either<AppException, List<ProfileReviewEntity>>> getProfileReviews();
  Future<Either<AppException, ProfileReviewEntity?>> getProfileReviewForPlace(
    String placeId,
  );
  Future<Either<AppException, ProfileReviewEntity>> saveProfileReview(
    ProfileReviewEntity review,
  );
  Future<Either<AppException, void>> deleteProfileReview(
    ProfileReviewEntity review,
  );
  Future<Either<AppException, List<PlannedTripEntity>>> getPlannedTrips();
  Future<Either<AppException, PlannedTripEntity>> savePlannedTrip(
    PlannedTripEntity trip,
  );
  Future<Either<AppException, void>> deletePlannedTrip(String id);
}
