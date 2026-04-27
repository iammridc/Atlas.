class RecommendationEntity {
  final String id;
  final String name;
  final String city;
  final String country;
  final String? photoReference;
  final double? latitude;
  final double? longitude;

  const RecommendationEntity({
    required this.id,
    required this.name,
    required this.city,
    required this.country,
    this.photoReference,
    this.latitude,
    this.longitude,
  });

  bool get hasCoordinates => latitude != null && longitude != null;
}
