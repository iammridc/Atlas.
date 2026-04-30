import 'package:atlas/features/profile/domain/entities/favorite_place_entity.dart';
import 'package:atlas/features/profile/domain/entities/planned_trip_entity.dart';
import 'package:atlas/features/profile/domain/entities/profile_gamification_entity.dart';
import 'package:atlas/features/profile/domain/entities/profile_review_entity.dart';
import 'package:atlas/features/profile/domain/entities/profile_summary_entity.dart';

class ProfileGamificationCalculator {
  static const _levels = [
    (xp: 0, title: 'New Explorer'),
    (xp: 160, title: 'Weekend Traveler'),
    (xp: 360, title: 'City Scout'),
    (xp: 700, title: 'Route Builder'),
    (xp: 1100, title: 'Local Expert'),
    (xp: 1650, title: 'World Explorer'),
    (xp: 2400, title: 'Travel Legend'),
  ];

  ProfileGamificationEntity calculate({
    required ProfileSummaryEntity profile,
    required List<FavoritePlaceEntity> favorites,
    required List<ProfileReviewEntity> reviews,
    required List<PlannedTripEntity> trips,
  }) {
    final activities = _collectActivities(favorites, reviews, trips);
    final cityCounts = _countsBy(activities.map((item) => item.city));
    final countryCounts = _countsBy(activities.map((item) => item.country));
    final uniqueCities = cityCounts.keys.length;
    final uniqueCountries = countryCounts.keys.length;
    final photosUploaded = reviews.fold<int>(
      0,
      (sum, review) => sum + review.photoDataUrls.length,
    );
    final monthlyActivities = activities
        .where((activity) => _isCurrentMonth(activity.date))
        .toList();
    final monthlyReviews = reviews
        .where((review) => _isCurrentMonth(review.updatedAt))
        .toList();

    final skillXp = _skillXp(reviews, favorites, trips, profile.preferences);
    final skills = _buildSkills(skillXp);
    final favoritePlaceType = skills.isEmpty
        ? 'Explorer'
        : skills.reduce((a, b) => a.xp >= b.xp ? a : b).title;
    final mostVisitedCity = _topValue(cityCounts, fallback: 'Start exploring');
    final totalDistanceKm = trips.fold<int>(
      0,
      (sum, trip) => sum + ((trip.route?.distanceMeters ?? 0) / 1000).round(),
    );

    final inferredVisits = activities.length;
    final reviewXp = reviews.fold<int>(0, (sum, review) {
      final hasPhotos = review.photoDataUrls.isNotEmpty;
      return sum + (hasPhotos ? 45 : 30);
    });
    final xp =
        inferredVisits * 20 +
        reviewXp +
        profile.plannedTripsCount * 25 +
        uniqueCities * 50 +
        uniqueCountries * 100 +
        photosUploaded * 5;

    final level = _buildLevel(xp);
    final reviewQuality = _buildReviewQuality(reviews);

    return ProfileGamificationEntity(
      level: level,
      badges: _buildBadges(
        activities: activities,
        cityCounts: cityCounts,
        countryCounts: countryCounts,
        reviews: reviews,
        photosUploaded: photosUploaded,
        plannedTripsCount: trips.length,
        travelStyleCount: skillXp.values.where((xp) => xp > 0).length,
      ),
      passport: TravelPassportEntity(
        citiesVisited: uniqueCities,
        countriesVisited: uniqueCountries,
        placesReviewed: reviews.length,
        photosUploaded: photosUploaded,
        favoritePlaceType: favoritePlaceType,
        mostVisitedCity: mostVisitedCity,
        totalDistanceKm: totalDistanceKm,
        travelStreakDays: _travelStreakDays(activities),
        stamps: _buildStamps(cityCounts, countryCounts),
      ),
      skills: skills,
      reviewQuality: reviewQuality,
      monthlyChallenges: _buildMonthlyChallenges(
        monthlyActivities: monthlyActivities,
        monthlyReviews: monthlyReviews,
        trips: trips,
      ),
    );
  }

  TravelerLevelEntity _buildLevel(int xp) {
    var index = 0;
    for (var i = 0; i < _levels.length; i++) {
      if (xp >= _levels[i].xp) index = i;
    }

    final current = _levels[index];
    final next = index == _levels.length - 1 ? current : _levels[index + 1];

    return TravelerLevelEntity(
      level: index + 1,
      title: current.title,
      xp: xp,
      currentLevelXp: current.xp,
      nextLevelXp: next.xp,
      nextTitle: next.title,
    );
  }

  List<ProfileBadgeEntity> _buildBadges({
    required List<_TravelActivity> activities,
    required Map<String, int> cityCounts,
    required Map<String, int> countryCounts,
    required List<ProfileReviewEntity> reviews,
    required int photosUploaded,
    required int plannedTripsCount,
    required int travelStyleCount,
  }) {
    final foodReviews = reviews.where((review) => _matches(review, 'Food'));
    final museumActivities = activities.where(
      (activity) => _matchesText(activity.searchText, 'museum'),
    );
    final beachActivities = activities.where(
      (activity) => _matchesText(activity.searchText, 'beach'),
    );
    final hiddenGemReviews = reviews.where(_isHiddenGemReview);
    final detailedReviews = reviews.where(
      (review) => _wordCount(review.text) >= 20,
    );
    final reviewsWithTags = reviews.where(
      (review) => review.likedTags.isNotEmpty,
    );
    final reviewsWithPhotos = reviews.where(
      (review) => review.photoDataUrls.isNotEmpty,
    );
    final positiveReviews = reviews.where((review) => review.rating >= 4);

    return [
      ProfileBadgeEntity(
        title: 'Place Collector',
        description: 'Saved, reviewed, or planned 25 places',
        iconKey: 'places',
        progress: activities.length,
        target: 25,
      ),
      ProfileBadgeEntity(
        title: 'City Collector',
        description: 'Visited 10 places in one city',
        iconKey: 'city',
        progress: cityCounts.values.fold<int>(
          0,
          (max, count) => count > max ? count : max,
        ),
        target: 10,
      ),
      ProfileBadgeEntity(
        title: 'Food Hunter',
        description: 'Reviewed 10 restaurants',
        iconKey: 'food',
        progress: foodReviews.length,
        target: 10,
      ),
      ProfileBadgeEntity(
        title: 'Museum Mind',
        description: 'Visited 5 museums',
        iconKey: 'museum',
        progress: museumActivities.length,
        target: 5,
      ),
      ProfileBadgeEntity(
        title: 'Beach Lover',
        description: 'Visited 5 beaches',
        iconKey: 'beach',
        progress: beachActivities.length,
        target: 5,
      ),
      ProfileBadgeEntity(
        title: 'Hidden Gem Finder',
        description: 'Reviewed low-key local places',
        iconKey: 'gem',
        progress: hiddenGemReviews.length,
        target: 3,
      ),
      ProfileBadgeEntity(
        title: 'Early Explorer',
        description: 'Added recent travel activity',
        iconKey: 'spark',
        progress: activities.any((activity) => _isRecent(activity.date))
            ? 1
            : 0,
        target: 1,
      ),
      ProfileBadgeEntity(
        title: 'Local Guide',
        description: 'Wrote 20 helpful reviews',
        iconKey: 'guide',
        progress: reviews.length,
        target: 20,
      ),
      ProfileBadgeEntity(
        title: 'Opinion Maker',
        description: 'Wrote 5 reviews',
        iconKey: 'review',
        progress: reviews.length,
        target: 5,
      ),
      ProfileBadgeEntity(
        title: 'Storyteller',
        description: 'Wrote 5 detailed reviews',
        iconKey: 'story',
        progress: detailedReviews.length,
        target: 5,
      ),
      ProfileBadgeEntity(
        title: 'Tag Curator',
        description: 'Added tags to 10 reviews',
        iconKey: 'tag',
        progress: reviewsWithTags.length,
        target: 10,
      ),
      ProfileBadgeEntity(
        title: 'Photo Traveler',
        description: 'Uploaded 30 travel photos',
        iconKey: 'photo',
        progress: photosUploaded,
        target: 30,
      ),
      ProfileBadgeEntity(
        title: 'Photo Reviewer',
        description: 'Added photos to 5 reviews',
        iconKey: 'photo_review',
        progress: reviewsWithPhotos.length,
        target: 5,
      ),
      ProfileBadgeEntity(
        title: 'Weekend Explorer',
        description: 'Visited 3 places in one weekend',
        iconKey: 'weekend',
        progress: _bestWeekendCount(activities),
        target: 3,
      ),
      ProfileBadgeEntity(
        title: 'Country Hopper',
        description: 'Visited places in 5 countries',
        iconKey: 'country',
        progress: countryCounts.length,
        target: 5,
      ),
      ProfileBadgeEntity(
        title: 'City Sampler',
        description: 'Explored 3 different cities',
        iconKey: 'city_sampler',
        progress: cityCounts.length,
        target: 3,
      ),
      ProfileBadgeEntity(
        title: 'Border Starter',
        description: 'Explored 2 different countries',
        iconKey: 'border',
        progress: countryCounts.length,
        target: 2,
      ),
      ProfileBadgeEntity(
        title: 'Great Taste',
        description: 'Found 5 places rated 4 stars or higher',
        iconKey: 'rating',
        progress: positiveReviews.length,
        target: 5,
      ),
      ProfileBadgeEntity(
        title: 'Route Maker',
        description: 'Saved 3 planned trips',
        iconKey: 'route',
        progress: plannedTripsCount,
        target: 3,
      ),
      ProfileBadgeEntity(
        title: 'Style Sampler',
        description: 'Explored 5 travel categories',
        iconKey: 'style',
        progress: travelStyleCount,
        target: 5,
      ),
    ];
  }

  List<PassportStampEntity> _buildStamps(
    Map<String, int> cityCounts,
    Map<String, int> countryCounts,
  ) {
    final cityStamps = cityCounts.entries.map((entry) {
      final title = _stampTitle(entry.value, entry.key);
      return PassportStampEntity(
        placeName: entry.key,
        levelTitle: title.levelTitle,
        progress: entry.value,
        target: title.target,
      );
    });
    final countryStamps = countryCounts.entries.map((entry) {
      final progress = entry.value;
      return PassportStampEntity(
        placeName: entry.key,
        levelTitle: progress >= 10 ? 'Country Expert' : 'Country Stamp',
        progress: progress,
        target: progress >= 10 ? 30 : 10,
      );
    });

    return [...cityStamps, ...countryStamps].take(6).toList();
  }

  ({String levelTitle, int target}) _stampTitle(
    int progress,
    String placeName,
  ) {
    if (progress >= 30) return (levelTitle: '$placeName Master', target: 30);
    if (progress >= 15) return (levelTitle: '$placeName Expert', target: 30);
    if (progress >= 5) return (levelTitle: '$placeName Explorer', target: 15);
    return (levelTitle: '$placeName Stamp', target: 5);
  }

  Map<String, int> _skillXp(
    List<ProfileReviewEntity> reviews,
    List<FavoritePlaceEntity> favorites,
    List<PlannedTripEntity> trips,
    List<String> preferences,
  ) {
    final scores = {for (final skill in _skillDefinitions.keys) skill: 0};

    for (final preference in preferences) {
      final skill = _skillForText(preference);
      if (skill != null) scores[skill] = scores[skill]! + 30;
    }

    for (final review in reviews) {
      final skill = _skillForText(
        '${review.placeName} ${review.likedTags.join(' ')} ${review.text}',
      );
      if (skill != null) {
        scores[skill] = scores[skill]! + 60 + review.photoDataUrls.length * 10;
      }
    }

    for (final favorite in favorites) {
      final skill = _skillForText('${favorite.name} ${favorite.location}');
      if (skill != null) scores[skill] = scores[skill]! + 35;
    }

    for (final trip in trips) {
      for (final stop in [
        ...trip.selectedPointsOfInterest,
        ...trip.selectedHotels,
      ]) {
        final skill = _skillForText('${stop.name} ${stop.category}');
        if (skill != null) scores[skill] = scores[skill]! + 25;
      }
    }

    return scores;
  }

  List<CategorySkillEntity> _buildSkills(Map<String, int> skillXp) {
    final skills = skillXp.entries.map((entry) {
      final xp = entry.value;
      final level = (xp ~/ 100 + 1).clamp(1, 9);
      return CategorySkillEntity(
        title: entry.key,
        iconKey: _skillDefinitions[entry.key]!.iconKey,
        xp: xp,
        level: level,
        nextLevelXp: level * 100,
      );
    }).toList();

    skills.sort((a, b) => b.xp.compareTo(a.xp));
    return skills;
  }

  ReviewQualityEntity _buildReviewQuality(List<ProfileReviewEntity> reviews) {
    if (reviews.isEmpty) {
      return const ReviewQualityEntity(
        score: 0,
        title: 'New Reviewer',
        highQualityReviews: 0,
        totalReviews: 0,
        reviewsWithPhotos: 0,
        helpfulVotes: 0,
      );
    }

    final scores = reviews.map(_reviewQualityScore).toList();
    final average = (scores.reduce((a, b) => a + b) / scores.length).round();
    final withPhotos = reviews
        .where((review) => review.photoDataUrls.isNotEmpty)
        .length;

    return ReviewQualityEntity(
      score: average,
      title: _qualityTitle(average),
      highQualityReviews: scores.where((score) => score >= 75).length,
      totalReviews: reviews.length,
      reviewsWithPhotos: withPhotos,
      helpfulVotes: 0,
    );
  }

  List<MonthlyChallengeEntity> _buildMonthlyChallenges({
    required List<_TravelActivity> monthlyActivities,
    required List<ProfileReviewEntity> monthlyReviews,
    required List<PlannedTripEntity> trips,
  }) {
    final monthlyTrips = trips.where((trip) => _isCurrentMonth(trip.updatedAt));
    final foodReviews = monthlyReviews.where(
      (review) => _matches(review, 'Food'),
    );
    final photoReviews = monthlyReviews.where(
      (review) => review.photoDataUrls.isNotEmpty,
    );
    final hiddenGems = monthlyReviews.where(_isHiddenGemReview);
    final categories = monthlyActivities
        .map((activity) => _skillForText(activity.searchText))
        .whereType<String>()
        .toSet();

    return [
      MonthlyChallengeEntity(
        title: 'Visit 3 new places',
        reward: '+90 XP',
        iconKey: 'visit',
        progress: monthlyActivities.length,
        target: 3,
      ),
      MonthlyChallengeEntity(
        title: 'Review 5 restaurants',
        reward: '+150 XP',
        iconKey: 'food',
        progress: foodReviews.length,
        target: 5,
      ),
      MonthlyChallengeEntity(
        title: 'Add photos to 3 places',
        reward: '+120 XP',
        iconKey: 'photo',
        progress: photoReviews.length,
        target: 3,
      ),
      MonthlyChallengeEntity(
        title: 'Discover 2 hidden gems',
        reward: '+100 XP',
        iconKey: 'gem',
        progress: hiddenGems.length,
        target: 2,
      ),
      MonthlyChallengeEntity(
        title: 'Create one weekend route',
        reward: '+80 XP',
        iconKey: 'route',
        progress: monthlyTrips.length,
        target: 1,
      ),
      MonthlyChallengeEntity(
        title: 'Try a new travel style',
        reward: '+75 XP',
        iconKey: 'spark',
        progress: categories.length,
        target: 2,
      ),
    ];
  }

  int _reviewQualityScore(ProfileReviewEntity review) {
    var score = 0;
    final wordCount = _wordCount(review.text);

    if (wordCount >= 20) {
      score += 35;
    } else if (wordCount >= 8) {
      score += 22;
    } else if (wordCount > 0) {
      score += 10;
    }
    if (review.photoDataUrls.isNotEmpty) score += 25;
    if (review.rating > 0) score += 15;
    if (review.likedTags.isNotEmpty) score += 15;
    if (!_looksRepeated(review.text)) score += 10;
    return score.clamp(0, 100);
  }

  int _wordCount(String text) {
    return text
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .length;
  }

  List<_TravelActivity> _collectActivities(
    List<FavoritePlaceEntity> favorites,
    List<ProfileReviewEntity> reviews,
    List<PlannedTripEntity> trips,
  ) {
    final byKey = <String, _TravelActivity>{};

    for (final favorite in favorites) {
      final key = _activityKey(favorite.id, favorite.name, favorite.city);
      byKey[key] = _TravelActivity(
        key: key,
        name: favorite.name,
        city: favorite.city,
        country: favorite.country,
        searchText: '${favorite.name} ${favorite.location} ${favorite.note}',
        date: favorite.savedAt,
      );
    }

    for (final review in reviews) {
      final key = _activityKey(
        review.placeId,
        review.placeName,
        review.placeCity,
      );
      byKey[key] = _TravelActivity(
        key: key,
        name: review.placeName,
        city: review.placeCity,
        country: review.placeCountry,
        searchText:
            '${review.placeName} ${review.placeCity} ${review.placeCountry} ${review.text} ${review.likedTags.join(' ')}',
        date: review.updatedAt,
      );
    }

    for (final trip in trips) {
      for (final location in [trip.origin, trip.destination]) {
        if (location == null) continue;
        final key = _activityKey(location.id, location.name, location.city);
        byKey.putIfAbsent(
          key,
          () => _TravelActivity(
            key: key,
            name: location.name,
            city: location.city,
            country: location.country,
            searchText: '${location.name} ${location.address}',
            date: trip.updatedAt,
          ),
        );
      }
    }

    return byKey.values.toList();
  }

  Map<String, int> _countsBy(Iterable<String> values) {
    final counts = <String, int>{};
    for (final value in values) {
      final normalized = value.trim();
      if (normalized.isEmpty) continue;
      counts[normalized] = (counts[normalized] ?? 0) + 1;
    }
    return counts;
  }

  String _topValue(Map<String, int> values, {required String fallback}) {
    if (values.isEmpty) return fallback;
    return values.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  int _travelStreakDays(List<_TravelActivity> activities) {
    if (activities.isEmpty) return 0;
    final days =
        activities
            .map(
              (activity) => DateTime(
                activity.date.year,
                activity.date.month,
                activity.date.day,
              ),
            )
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    final today = DateTime.now();
    var cursor = DateTime(today.year, today.month, today.day);
    var streak = 0;
    for (final day in days) {
      if (day == cursor) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else if (day.isBefore(cursor)) {
        break;
      }
    }

    if (streak > 0) return streak;
    return days.first.isAfter(cursor.subtract(const Duration(days: 7))) ? 1 : 0;
  }

  int _bestWeekendCount(List<_TravelActivity> activities) {
    final weekendCounts = <String, int>{};
    for (final activity in activities) {
      if (activity.date.weekday != DateTime.saturday &&
          activity.date.weekday != DateTime.sunday) {
        continue;
      }
      final saturday = activity.date.weekday == DateTime.saturday
          ? activity.date
          : activity.date.subtract(const Duration(days: 1));
      final key = '${saturday.year}-${saturday.month}-${saturday.day}';
      weekendCounts[key] = (weekendCounts[key] ?? 0) + 1;
    }

    return weekendCounts.values.fold<int>(
      0,
      (max, count) => count > max ? count : max,
    );
  }

  bool _matches(ProfileReviewEntity review, String skill) {
    return _skillForText(
          '${review.placeName} ${review.placeCity} ${review.text} ${review.likedTags.join(' ')}',
        ) ==
        skill;
  }

  bool _isHiddenGemReview(ProfileReviewEntity review) {
    final text =
        '${review.placeName} ${review.text} ${review.likedTags.join(' ')}'
            .toLowerCase();
    return text.contains('hidden') ||
        text.contains('quiet') ||
        text.contains('local') ||
        text.contains('underrated') ||
        text.contains('gem');
  }

  bool _matchesText(String value, String token) =>
      value.toLowerCase().contains(token.toLowerCase());

  bool _isRecent(DateTime date) {
    return DateTime.now().difference(date).inDays <= 14;
  }

  bool _isCurrentMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  bool _looksRepeated(String text) {
    final words = text
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .toList();
    if (words.length < 8) return false;
    return words.toSet().length <= words.length / 2;
  }

  String _qualityTitle(int score) {
    if (score >= 85) return 'Trusted Reviewer';
    if (score >= 70) return 'Helpful Traveler';
    if (score >= 50) return 'Local Expert';
    return 'New Reviewer';
  }

  String _activityKey(String id, String name, String city) {
    final safeId = id.trim();
    if (safeId.isNotEmpty) return safeId;
    return '${name.trim().toLowerCase()}-${city.trim().toLowerCase()}';
  }

  String? _skillForText(String value) {
    final lower = value.toLowerCase();
    for (final entry in _skillDefinitions.entries) {
      if (entry.value.tokens.any(lower.contains)) return entry.key;
    }
    return null;
  }
}

class _TravelActivity {
  final String key;
  final String name;
  final String city;
  final String country;
  final String searchText;
  final DateTime date;

  const _TravelActivity({
    required this.key,
    required this.name,
    required this.city,
    required this.country,
    required this.searchText,
    required this.date,
  });
}

class _SkillDefinition {
  final String iconKey;
  final List<String> tokens;

  const _SkillDefinition({required this.iconKey, required this.tokens});
}

const _skillDefinitions = {
  'Food': _SkillDefinition(
    iconKey: 'food',
    tokens: ['restaurant', 'food', 'cafe', 'bar', 'bakery', 'meal'],
  ),
  'Nature': _SkillDefinition(
    iconKey: 'nature',
    tokens: ['park', 'garden', 'nature', 'forest', 'beach', 'lake'],
  ),
  'Culture': _SkillDefinition(
    iconKey: 'culture',
    tokens: ['culture', 'historic', 'church', 'cathedral', 'monument'],
  ),
  'Hotels': _SkillDefinition(
    iconKey: 'hotel',
    tokens: ['hotel', 'hostel', 'stay', 'resort', 'lodging'],
  ),
  'Nightlife': _SkillDefinition(
    iconKey: 'night',
    tokens: ['night', 'club', 'bar', 'pub', 'cocktail'],
  ),
  'Shopping': _SkillDefinition(
    iconKey: 'shopping',
    tokens: ['shop', 'mall', 'market', 'store', 'boutique'],
  ),
  'Museums': _SkillDefinition(
    iconKey: 'museum',
    tokens: ['museum', 'gallery', 'exhibition', 'art'],
  ),
  'Adventure': _SkillDefinition(
    iconKey: 'adventure',
    tokens: ['adventure', 'hike', 'trail', 'climb', 'sport'],
  ),
  'Family': _SkillDefinition(
    iconKey: 'family',
    tokens: ['family', 'kids', 'children', 'zoo', 'playground'],
  ),
};
