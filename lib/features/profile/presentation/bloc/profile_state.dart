import 'package:atlas/features/profile/domain/entities/profile_summary_entity.dart';
import 'package:equatable/equatable.dart';

enum ProfileStatus { initial, loading, loaded, error }

class ProfileState extends Equatable {
  final ProfileStatus status;
  final ProfileSummaryEntity? profile;
  final bool isSavingUsername;
  final bool isSavingAvatar;
  final String? errorMessage;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.isSavingUsername = false,
    this.isSavingAvatar = false,
    this.errorMessage,
  });

  ProfileState copyWith({
    ProfileStatus? status,
    ProfileSummaryEntity? profile,
    bool? isSavingUsername,
    bool? isSavingAvatar,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      isSavingUsername: isSavingUsername ?? this.isSavingUsername,
      isSavingAvatar: isSavingAvatar ?? this.isSavingAvatar,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    profile,
    isSavingUsername,
    isSavingAvatar,
    errorMessage,
  ];
}
