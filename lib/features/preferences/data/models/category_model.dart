import 'package:atlas/features/preferences/domain/entities/category_entity.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.label,
    required super.group,
    required super.table,
    required super.order,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      label: json['label'] as String,
      group: json['group'] as String,
      table: json['table'] as String,
      order: json['order'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'group': group,
      'table': table,
      'order': order,
    };
  }
}
