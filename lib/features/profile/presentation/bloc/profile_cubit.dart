import 'package:atlas/features/profile/domain/repositories/profile_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository _profileRepository;

  ProfileCubit({required ProfileRepository profileRepository})
    : _profileRepository = profileRepository,
      super(const ProfileState());

  Future<void> loadProfile({bool showLoader = true}) async {
    if (showLoader) {
      emit(state.copyWith(status: ProfileStatus.loading, clearError: true));
    }

    final result = await _profileRepository.getProfileSummary();
    result.fold(
      (error) => emit(
        state.copyWith(
          status: ProfileStatus.error,
          errorMessage: error.message,
          isSavingAvatar: false,
          isSavingUsername: false,
        ),
      ),
      (profile) => emit(
        state.copyWith(
          status: ProfileStatus.loaded,
          profile: profile,
          isSavingAvatar: false,
          isSavingUsername: false,
          clearError: true,
        ),
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
