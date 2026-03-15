class RecommendationEntity {
  final String id;
  final String name;
  final String city;
  final String country;
  final String? photoReference;

  const RecommendationEntity({
    required this.id,
    required this.name,
    required this.city,
    required this.country,
    this.photoReference,
  });
}
