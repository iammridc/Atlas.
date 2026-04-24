import 'package:atlas/features/profile/domain/entities/planned_trip_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlannedTripModel extends PlannedTripEntity {
  const PlannedTripModel({
    required super.id,
    required super.title,
    required super.routeSummary,
    required super.note,
    required super.updatedAt,
  });

  factory PlannedTripModel.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final json = doc.data();
    return PlannedTripModel(
      id: doc.id,
      title: (json['title'] as String?)?.trim() ?? '',
      routeSummary: (json['routeSummary'] as String?)?.trim() ?? '',
      note: (json['note'] as String?)?.trim() ?? '',
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title.trim(),
      'routeSummary': routeSummary.trim(),
      'note': note.trim(),
      'updatedAt': updatedAt,
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
