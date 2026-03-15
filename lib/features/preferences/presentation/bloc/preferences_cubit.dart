import 'package:atlas/features/preferences/domain/entities/category_entity.dart';
import 'package:atlas/features/preferences/domain/usecases/get_categories_usecase.dart';
import 'package:atlas/features/preferences/domain/usecases/save_preferences_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'preferences_state.dart';

class PreferencesCubit extends Cubit<PreferencesState> {
  final GetCategoriesUseCase _getCategoriesUseCase;
  final SavePreferencesUseCase _savePreferencesUseCase;

  PreferencesCubit({
    required GetCategoriesUseCase getCategoriesUseCase,
    required SavePreferencesUseCase savePreferencesUseCase,
  }) : _getCategoriesUseCase = getCategoriesUseCase,
       _savePreferencesUseCase = savePreferencesUseCase,
       super(PreferencesInitial());

  Future<void> loadCategories() async {
    emit(PreferencesLoading());
    final result = await _getCategoriesUseCase();
    result.fold((failure) => emit(InterestsError(failure.message)), (
      categories,
    ) {
      final Map<String, List<CategoryEntity>> grouped = {};
      for (final cat in categories) {
        grouped.putIfAbsent(cat.group, () => []);
        grouped[cat.group]!.add(cat);
      }
      emit(PreferencesLoaded(groupedCategories: grouped, selected: {}));
    });
  }

  void toggle(String categoryId) {
    final current = state;
    if (current is! PreferencesLoaded) return;
    final newSelected = Set<String>.from(current.selected);
    newSelected.contains(categoryId)
        ? newSelected.remove(categoryId)
        : newSelected.add(categoryId);
    emit(current.copyWith(selected: newSelected));
  }

  Future<void> savePreferences(String uid) async {
    final current = state;
    if (current is! PreferencesLoaded) return;
    emit(PreferencesSaving());
    final result = await _savePreferencesUseCase(
      SavePreferencesParams(uid: uid, categoryIds: current.selected.toList()),
    );
    result.fold(
      (failure) => emit(InterestsError(failure.message)),
      (_) => emit(PreferencesSaved()),
    );
  }
}
