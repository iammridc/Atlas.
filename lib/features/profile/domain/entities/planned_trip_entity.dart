class PlannedTripEntity {
  final String id;
  final String title;
  final String routeSummary;
  final String note;
  final DateTime updatedAt;

  const PlannedTripEntity({
    required this.id,
    required this.title,
    required this.routeSummary,
    required this.note,
    required this.updatedAt,
  });
}
