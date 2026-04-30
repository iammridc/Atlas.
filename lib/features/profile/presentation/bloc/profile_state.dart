import 'package:atlas/features/profile/domain/entities/profile_gamification_entity.dart';
import 'package:atlas/features/profile/domain/entities/profile_summary_entity.dart';
import 'package:equatable/equatable.dart';

enum ProfileStatus { initial, loading, loaded, error }

class ProfileState extends Equatable {
  final ProfileStatus status;
  final ProfileSummaryEntity? profile;
  final ProfileGamificationEntity? gamification;
  final bool isSavingUsername;
  final bool isSavingAvatar;
  final String? errorMessage;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.gamification,
    this.isSavingUsername = false,
    this.isSavingAvatar = false,
    this.errorMessage,
  });

  ProfileState copyWith({
    ProfileStatus? status,
    ProfileSummaryEntity? profile,
    ProfileGamificationEntity? gamification,
    bool? isSavingUsername,
    bool? isSavingAvatar,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      gamification: gamification ?? this.gamification,
      isSavingUsername: isSavingUsername ?? this.isSavingUsername,
      isSavingAvatar: isSavingAvatar ?? this.isSavingAvatar,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    profile,
    gamification,
    isSavingUsername,
    isSavingAvatar,
    errorMessage,
  ];
}
