import 'package:atlas/features/preferences/domain/entities/category_entity.dart';
import 'package:equatable/equatable.dart';

abstract class PreferencesState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PreferencesInitial extends PreferencesState {}

class PreferencesLoading extends PreferencesState {}

class PreferencesSaving extends PreferencesState {}

class PreferencesSaved extends PreferencesState {
  final List<String> categoryTypes;
  PreferencesSaved(this.categoryTypes);

  @override
  List<Object?> get props => [categoryTypes];
}

class PreferencesLoaded extends PreferencesState {
  final Map<String, List<CategoryEntity>> groupedCategories;
  final Set<String> selected;

  PreferencesLoaded({required this.groupedCategories, required this.selected});

  PreferencesLoaded copyWith({
    Map<String, List<CategoryEntity>>? groupedCategories,
    Set<String>? selected,
  }) => PreferencesLoaded(
    groupedCategories: groupedCategories ?? this.groupedCategories,
    selected: selected ?? this.selected,
  );

  @override
  List<Object?> get props => [groupedCategories, selected];
}

class InterestsError extends PreferencesState {
  final String message;
  InterestsError(this.message);

  @override
  List<Object?> get props => [message];
}
