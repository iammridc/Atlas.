import 'package:atlas/features/profile/domain/entities/favorite_place_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FavoritePlaceModel extends FavoritePlaceEntity {
  const FavoritePlaceModel({
    required super.id,
    required super.name,
    required super.location,
    super.city,
    super.country,
    super.photoReference,
    required super.note,
    required super.savedAt,
  });

  factory FavoritePlaceModel.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final json = doc.data();
    return FavoritePlaceModel(
      id: doc.id,
      name: (json['name'] as String?)?.trim() ?? '',
      location: (json['location'] as String?)?.trim() ?? '',
      city: (json['city'] as String?)?.trim() ?? '',
      country: (json['country'] as String?)?.trim() ?? '',
      photoReference: (json['photoReference'] as String?)?.trim(),
      note: (json['note'] as String?)?.trim() ?? '',
      savedAt: _parseDate(json['savedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name.trim(),
      'location': location.trim(),
      'city': city.trim(),
      'country': country.trim(),
      'photoReference': photoReference,
      'note': note.trim(),
      'savedAt': savedAt,
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
