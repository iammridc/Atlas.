class ProfileSummaryEntity {
  final String userId;
  final String email;
  final String username;
  final String? avatarUrl;
  final List<String> preferences;
  final int favoritePlacesCount;
  final int reviewsCount;
  final int plannedTripsCount;

  const ProfileSummaryEntity({
    required this.userId,
    required this.email,
    required this.username,
    required this.preferences,
    required this.favoritePlacesCount,
    required this.reviewsCount,
    required this.plannedTripsCount,
    this.avatarUrl,
  });
}
