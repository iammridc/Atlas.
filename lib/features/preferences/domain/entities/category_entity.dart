import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  final String id;
  final String label;
  final String group;
  final String table;
  final int order;

  const CategoryEntity({
    required this.id,
    required this.label,
    required this.group,
    required this.table,
    required this.order,
  });

  @override
  List<Object?> get props => [id, label, group, table, order];
}
