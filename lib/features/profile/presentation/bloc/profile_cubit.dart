import 'package:atlas/features/profile/domain/entities/favorite_place_entity.dart';
import 'package:atlas/features/profile/domain/entities/planned_trip_entity.dart';
import 'package:atlas/features/profile/domain/entities/profile_review_entity.dart';
import 'package:atlas/features/profile/domain/services/profile_gamification_calculator.dart';
import 'package:atlas/features/profile/domain/repositories/profile_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository _profileRepository;
  final _gamificationCalculator = ProfileGamificationCalculator();

  ProfileCubit({required ProfileRepository profileRepository})
    : _profileRepository = profileRepository,
      super(const ProfileState());

  Future<void> loadProfile({bool showLoader = true}) async {
    if (showLoader) {
      emit(state.copyWith(status: ProfileStatus.loading, clearError: true));
    }

    final result = await _profileRepository.getProfileSummary();
    final error = result.fold((error) => error, (_) => null);
    if (error != null) {
      emit(
        state.copyWith(
          status: ProfileStatus.error,
          errorMessage: error.message,
          isSavingAvatar: false,
          isSavingUsername: false,
        ),
      );
      return;
    }

    final profile = result.getOrElse(() => throw StateError('Missing profile'));
    final favoritesResult = await _profileRepository.getFavoritePlaces();
    final reviewsResult = await _profileRepository.getProfileReviews();
    final tripsResult = await _profileRepository.getPlannedTrips();

    final favorites = favoritesResult.fold<List<FavoritePlaceEntity>>(
      (_) => const [],
      (value) => value,
    );
    final reviews = reviewsResult.fold<List<ProfileReviewEntity>>(
      (_) => const [],
      (value) => value,
    );
    final trips = tripsResult.fold<List<PlannedTripEntity>>(
      (_) => const [],
      (value) => value,
    );
    final gamification = _gamificationCalculator.calculate(
      profile: profile,
      favorites: favorites,
      reviews: reviews,
      trips: trips,
    );

    emit(
      state.copyWith(
        status: ProfileStatus.loaded,
        profile: profile,
        gamification: gamification,
        isSavingAvatar: false,
        isSavingUsername: false,
        clearError: true,
      ),
    );
  }

  Future<String?> updateUsername(String username) async {
    emit(state.copyWith(isSavingUsername: true, clearError: true));
    final result = await _profileRepository.updateUsername(username);
    final error = result.fold((error) => error, (_) => null);
    if (error != null) {
      emit(
        state.copyWith(isSavingUsername: false, errorMessage: error.message),
      );
      return error.message;
    }

    await loadProfile(showLoader: false);
    return null;
  }

  Future<String?> updateAvatar(String? avatarUrl) async {
    emit(state.copyWith(isSavingAvatar: true, clearError: true));
    final result = await _profileRepository.updateAvatar(avatarUrl);
    final error = result.fold((error) => error, (_) => null);
    if (error != null) {
      emit(state.copyWith(isSavingAvatar: false, errorMessage: error.message));
      return error.message;
    }

    await loadProfile(showLoader: false);
    return null;
  }
}
