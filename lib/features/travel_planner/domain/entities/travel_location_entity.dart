class TravelLocationEntity {
  final String id;
  final String name;
  final String address;
  final String city;
  final String country;
  final double latitude;
  final double longitude;
  final String? photoReference;

  const TravelLocationEntity({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.country,
    required this.latitude,
    required this.longitude,
    this.photoReference,
  });

  bool get hasCoordinates => latitude != 0 || longitude != 0;

  String get displayAddress {
    final normalizedAddress = address.trim();
    if (normalizedAddress.isNotEmpty) return normalizedAddress;

    final parts = [
      city,
      country,
    ].map((part) => part.trim()).where((part) => part.isNotEmpty).toList();
    if (parts.isNotEmpty) return parts.join(', ');
    return name;
  }
}
