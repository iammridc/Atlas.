class ProfileGamificationEntity {
  final TravelerLevelEntity level;
  final List<ProfileBadgeEntity> badges;
  final TravelPassportEntity passport;
  final List<CategorySkillEntity> skills;
  final ReviewQualityEntity reviewQuality;
  final List<MonthlyChallengeEntity> monthlyChallenges;

  const ProfileGamificationEntity({
    required this.level,
    required this.badges,
    required this.passport,
    required this.skills,
    required this.reviewQuality,
    required this.monthlyChallenges,
  });
}

class TravelerLevelEntity {
  final int level;
  final String title;
  final int xp;
  final int currentLevelXp;
  final int nextLevelXp;
  final String nextTitle;

  const TravelerLevelEntity({
    required this.level,
    required this.title,
    required this.xp,
    required this.currentLevelXp,
    required this.nextLevelXp,
    required this.nextTitle,
  });

  double get progress {
    final span = nextLevelXp - currentLevelXp;
    if (span <= 0) return 1;
    return ((xp - currentLevelXp) / span).clamp(0, 1).toDouble();
  }

  int get xpToNext => (nextLevelXp - xp).clamp(0, nextLevelXp);
}

class ProfileBadgeEntity {
  final String title;
  final String description;
  final String iconKey;
  final int progress;
  final int target;

  const ProfileBadgeEntity({
    required this.title,
    required this.description,
    required this.iconKey,
    required this.progress,
    required this.target,
  });

  bool get isUnlocked => progress >= target;
  double get completion =>
      target <= 0 ? 1 : (progress / target).clamp(0, 1).toDouble();
}

class TravelPassportEntity {
  final int citiesVisited;
  final int countriesVisited;
  final int placesReviewed;
  final int photosUploaded;
  final String favoritePlaceType;
  final String mostVisitedCity;
  final int totalDistanceKm;
  final int travelStreakDays;
  final List<PassportStampEntity> stamps;

  const TravelPassportEntity({
    required this.citiesVisited,
    required this.countriesVisited,
    required this.placesReviewed,
    required this.photosUploaded,
    required this.favoritePlaceType,
    required this.mostVisitedCity,
    required this.totalDistanceKm,
    required this.travelStreakDays,
    required this.stamps,
  });
}

class PassportStampEntity {
  final String placeName;
  final String levelTitle;
  final int progress;
  final int target;

  const PassportStampEntity({
    required this.placeName,
    required this.levelTitle,
    required this.progress,
    required this.target,
  });

  bool get isUnlocked => progress >= target;
}

class CategorySkillEntity {
  final String title;
  final String iconKey;
  final int xp;
  final int level;
  final int nextLevelXp;

  const CategorySkillEntity({
    required this.title,
    required this.iconKey,
    required this.xp,
    required this.level,
    required this.nextLevelXp,
  });

  double get progress {
    final previousLevelXp = (level - 1) * 100;
    final span = nextLevelXp - previousLevelXp;
    if (span <= 0) return 1;
    return ((xp - previousLevelXp) / span).clamp(0, 1).toDouble();
  }
}

class ReviewQualityEntity {
  final int score;
  final String title;
  final int highQualityReviews;
  final int totalReviews;
  final int reviewsWithPhotos;
  final int helpfulVotes;

  const ReviewQualityEntity({
    required this.score,
    required this.title,
    required this.highQualityReviews,
    required this.totalReviews,
    required this.reviewsWithPhotos,
    required this.helpfulVotes,
  });
}

class MonthlyChallengeEntity {
  final String title;
  final String reward;
  final String iconKey;
  final int progress;
  final int target;

  const MonthlyChallengeEntity({
    required this.title,
    required this.reward,
    required this.iconKey,
    required this.progress,
    required this.target,
  });

  bool get isCompleted => progress >= target;
  double get completion =>
      target <= 0 ? 1 : (progress / target).clamp(0, 1).toDouble();
}
