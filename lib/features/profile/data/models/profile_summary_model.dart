import 'package:atlas/features/profile/domain/entities/profile_summary_entity.dart';

class ProfileSummaryModel extends ProfileSummaryEntity {
  const ProfileSummaryModel({
    required super.userId,
    required super.email,
    required super.username,
    required super.preferences,
    required super.favoritePlacesCount,
    required super.reviewsCount,
    required super.plannedTripsCount,
    super.avatarUrl,
  });

  factory ProfileSummaryModel.fromJson(
    Map<String, dynamic> json, {
    required String userId,
    required String email,
    required int favoritePlacesCount,
    required int reviewsCount,
    required int plannedTripsCount,
  }) {
    final safeEmail = email.trim();
    final fallbackUsername = safeEmail.isEmpty
        ? 'Atlas Traveler'
        : safeEmail.split('@').first;

    return ProfileSummaryModel(
      userId: userId,
      email: safeEmail,
      username: (json['username'] as String?)?.trim().isNotEmpty == true
          ? (json['username'] as String).trim()
          : fallbackUsername,
      avatarUrl: json['avatarUrl'] as String?,
      preferences: List<String>.from(json['preferences'] ?? const []),
      favoritePlacesCount: favoritePlacesCount,
      reviewsCount: reviewsCount,
      plannedTripsCount: plannedTripsCount,
    );
  }
}
