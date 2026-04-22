import 'package:atlas/core/errors/app_exception.dart';
import 'package:atlas/features/place_details/data/datasources/place_details_remote_datasource.dart';
import 'package:atlas/features/place_details/domain/entities/place_details_entity.dart';
import 'package:atlas/features/place_details/domain/entities/place_review_entity.dart';
import 'package:atlas/features/place_details/domain/repositories/place_details_repository.dart';
import 'package:dartz/dartz.dart';

class PlaceDetailsRepositoryImpl implements PlaceDetailsRepository {
  final PlaceDetailsRemoteDatasource _datasource;

  PlaceDetailsRepositoryImpl(this._datasource);

  @override
  Future<Either<AppException, PlaceDetailsEntity>> getPlaceDetails({
    required String placeId,
    required String fallbackName,
    required String fallbackCity,
    required String fallbackCountry,
    String? fallbackPhotoName,
  }) async {
    try {
      final place = await _datasource.getPlaceDetails(
        placeId: placeId,
        fallbackName: fallbackName,
        fallbackCity: fallbackCity,
        fallbackCountry: fallbackCountry,
        fallbackPhotoName: fallbackPhotoName,
      );
      return Right(place);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownException(message: e.toString()));
    }
  }

  @override
  Future<Either<AppException, List<PlaceReviewEntity>>> getCommunityReviews(
    String placeId,
  ) async {
    try {
      final reviews = await _datasource.getCommunityReviews(placeId);
      return Right(reviews);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownException(message: e.toString()));
    }
  }
}
