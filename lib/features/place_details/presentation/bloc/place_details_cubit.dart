import 'package:atlas/features/profile/domain/entities/favorite_place_entity.dart';
import 'package:atlas/features/profile/domain/entities/profile_review_entity.dart';
import 'package:atlas/features/profile/domain/repositories/profile_repository.dart';
import 'package:atlas/features/profile/domain/services/favorite_places_sync_service.dart';
import 'package:atlas/features/profile/domain/services/profile_reviews_sync_service.dart';
import 'package:atlas/features/place_details/domain/usecases/get_place_community_reviews_usecase.dart';
import 'package:atlas/features/place_details/domain/entities/place_review_entity.dart';
import 'package:atlas/features/place_details/domain/usecases/get_place_details_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'place_details_state.dart';

enum PlaceFavoriteActionStatus { added, removed, failed, busy }

class PlaceFavoriteActionResult {
  final PlaceFavoriteActionStatus status;
  final String message;

  const PlaceFavoriteActionResult({
    required this.status,
    required this.message,
  });
}

class PlaceDetailsCubit extends Cubit<PlaceDetailsState> {
  final GetPlaceDetailsUseCase _getPlaceDetailsUseCase;
  final GetPlaceCommunityReviewsUseCase _getPlaceCommunityReviewsUseCase;
  final ProfileRepository _profileRepository;
  final FavoritePlacesSyncService _favoritePlacesSyncService;
  final ProfileReviewsSyncService _profileReviewsSyncService;

  PlaceDetailsCubit({
    required GetPlaceDetailsUseCase getPlaceDetailsUseCase,
    required GetPlaceCommunityReviewsUseCase getPlaceCommunityReviewsUseCase,
    required ProfileRepository profileRepository,
    required FavoritePlacesSyncService favoritePlacesSyncService,
    required ProfileReviewsSyncService profileReviewsSyncService,
  }) : _getPlaceDetailsUseCase = getPlaceDetailsUseCase,
       _getPlaceCommunityReviewsUseCase = getPlaceCommunityReviewsUseCase,
       _profileRepository = profileRepository,
       _favoritePlacesSyncService = favoritePlacesSyncService,
       _profileReviewsSyncService = profileReviewsSyncService,
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
        final currentUserReviewResult = await _profileRepository
            .getProfileReviewForPlace(placeId);
        final currentUserReview = currentUserReviewResult
            .fold<ProfileReviewEntity?>((_) => null, (review) => review);
        final favoriteResult = await _profileRepository.isFavoritePlace(
          placeId,
        );
        final isFavorite = favoriteResult.fold((_) => false, (value) => value);

        emit(
          PlaceDetailsLoaded(
            place: place,
            communityReviews: List<PlaceReviewEntity>.of(communityReviews),
            currentUserReview: currentUserReview,
            isFavorite: isFavorite,
          ),
        );
      },
    );
  }

  Future<PlaceFavoriteActionResult> toggleFavoritePlace() async {
    final current = state;
    if (current is! PlaceDetailsLoaded) {
      return const PlaceFavoriteActionResult(
        status: PlaceFavoriteActionStatus.failed,
        message: 'Place details are still loading.',
      );
    }

    if (current.isSavingFavorite) {
      return const PlaceFavoriteActionResult(
        status: PlaceFavoriteActionStatus.busy,
        message: 'Updating favourite status...',
      );
    }

    final place = current.place;
    final nextIsFavorite = !current.isFavorite;
    final location = place.formattedAddress.trim().isNotEmpty
        ? place.formattedAddress.trim()
        : [
            if (place.city.trim().isNotEmpty) place.city.trim(),
            if (place.country.trim().isNotEmpty) place.country.trim(),
          ].join(', ');

    emit(current.copyWith(isFavorite: nextIsFavorite, isSavingFavorite: true));

    final result = nextIsFavorite
        ? await _profileRepository.saveFavoritePlace(
            FavoritePlaceEntity(
              id: place.id,
              name: place.name,
              location: location.isEmpty ? place.name : location,
              city: place.city,
              country: place.country,
              photoReference: place.photoNames.isEmpty
                  ? null
                  : place.photoNames.first,
              note: '',
              savedAt: DateTime.now(),
            ),
          )
        : await _profileRepository.deleteFavoritePlace(place.id);

    return result.fold(
      (failure) {
        emit(current.copyWith(isSavingFavorite: false));
        return PlaceFavoriteActionResult(
          status: PlaceFavoriteActionStatus.failed,
          message: failure.message,
        );
      },
      (_) {
        emit(
          current.copyWith(isFavorite: nextIsFavorite, isSavingFavorite: false),
        );
        _favoritePlacesSyncService.notifyChanged();
        return PlaceFavoriteActionResult(
          status: nextIsFavorite
              ? PlaceFavoriteActionStatus.added
              : PlaceFavoriteActionStatus.removed,
          message: nextIsFavorite
              ? 'Added to favourites.'
              : 'Removed from favourites.',
        );
      },
    );
  }

  Future<String?> saveCurrentUserReview({
    required double rating,
    required String text,
  }) async {
    final current = state;
    if (current is! PlaceDetailsLoaded) {
      return 'Place details are still loading.';
    }
    if (text.trim().isEmpty) {
      return 'Review text is required.';
    }

    final place = current.place;
    final result = await _profileRepository.saveProfileReview(
      ProfileReviewEntity(
        id: place.id,
        placeId: place.id,
        placeName: place.name,
        placeCity: place.city,
        placeCountry: place.country,
        rating: rating.clamp(1, 5).toDouble(),
        text: text,
        createdAt: current.currentUserReview?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final errorMessage = result.fold((failure) => failure.message, (_) => null);
    return errorMessage;
  }

  Future<void> refreshReviews() async {
    final current = state;
    if (current is! PlaceDetailsLoaded) return;

    final reviewsResult = await _getPlaceCommunityReviewsUseCase(
      current.place.id,
    );
    final currentUserReviewResult = await _profileRepository
        .getProfileReviewForPlace(current.place.id);
    final nextState = state;
    if (nextState is! PlaceDetailsLoaded) return;

    final nextCommunityReviews = reviewsResult.fold(
      (_) => nextState.communityReviews,
      (reviews) => List<PlaceReviewEntity>.of(reviews),
    );
    final nextCurrentUserReview = currentUserReviewResult
        .fold<ProfileReviewEntity?>(
          (_) => nextState.currentUserReview,
          (review) => review,
        );

    emit(
      nextState.copyWith(
        communityReviews: nextCommunityReviews,
        currentUserReview: nextCurrentUserReview,
      ),
    );
    _profileReviewsSyncService.notifyChanged();
  }
}
