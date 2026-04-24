class FavoritePlaceEntity {
  final String id;
  final String name;
  final String location;
  final String city;
  final String country;
  final String? photoReference;
  final String note;
  final DateTime savedAt;

  const FavoritePlaceEntity({
    required this.id,
    required this.name,
    required this.location,
    this.city = '',
    this.country = '',
    this.photoReference,
    required this.note,
    required this.savedAt,
  });
}
