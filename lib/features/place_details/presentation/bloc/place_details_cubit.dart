import 'package:atlas/features/place_details/domain/usecases/get_place_community_reviews_usecase.dart';
import 'package:atlas/features/place_details/domain/entities/place_review_entity.dart';
import 'package:atlas/features/place_details/domain/usecases/get_place_details_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'place_details_state.dart';

class PlaceDetailsCubit extends Cubit<PlaceDetailsState> {
  final GetPlaceDetailsUseCase _getPlaceDetailsUseCase;
  final GetPlaceCommunityReviewsUseCase _getPlaceCommunityReviewsUseCase;

  PlaceDetailsCubit({
    required GetPlaceDetailsUseCase getPlaceDetailsUseCase,
    required GetPlaceCommunityReviewsUseCase getPlaceCommunityReviewsUseCase,
  }) : _getPlaceDetailsUseCase = getPlaceDetailsUseCase,
       _getPlaceCommunityReviewsUseCase = getPlaceCommunityReviewsUseCase,
       super(PlaceDetailsInitial());

  Future<void> loadPlace({
    required String placeId,
    required String placeName,
    required String city,
    required String country,
    String? photoReference,
  }) async {
    emit(PlaceDetailsLoading());

    final detailsResult = await _getPlaceDetailsUseCase(
      GetPlaceDetailsParams(
        placeId: placeId,
        fallbackName: placeName,
        fallbackCity: city,
        fallbackCountry: country,
        fallbackPhotoName: photoReference,
      ),
    );

    await detailsResult.fold(
      (failure) async {
        emit(PlaceDetailsError(failure.message));
      },
      (place) async {
        final communityReviewsResult = await _getPlaceCommunityReviewsUseCase(
          placeId,
        );
        final communityReviews = communityReviewsResult.fold(
          (_) => <PlaceReviewEntity>[],
          (reviews) => reviews,
        );

        emit(
          PlaceDetailsLoaded(
            place: place,
            communityReviews: List<PlaceReviewEntity>.of(communityReviews),
          ),
        );
      },
    );
  }
}
