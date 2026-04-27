class HomeMapCoordinateEntity {
  final double latitude;
  final double longitude;

  const HomeMapCoordinateEntity({
    required this.latitude,
    required this.longitude,
  });
}

class HomeMapLocationEntity {
  final String city;
  final String country;

  const HomeMapLocationEntity({required this.city, required this.country});

  bool get hasLocationLabel =>
      city.trim().isNotEmpty || country.trim().isNotEmpty;

  String get label {
    final parts = [
      city.trim(),
      country.trim(),
    ].where((part) => part.isNotEmpty).toList();

    return parts.join(', ');
  }
}
