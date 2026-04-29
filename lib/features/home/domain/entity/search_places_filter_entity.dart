class SearchPlacesFilterEntity {
  final List<String> categoryIds;
  final List<String> categoryLabels;

  const SearchPlacesFilterEntity({
    this.categoryIds = const [],
    this.categoryLabels = const [],
  });

  static const empty = SearchPlacesFilterEntity();

  bool get hasCategories => categoryIds.isNotEmpty;

  bool get hasActiveFilters => hasCategories;

  int get activeCount => categoryIds.length;

  String get summaryLabel {
    if (categoryLabels.isEmpty) return '';
    if (categoryLabels.length == 1) return categoryLabels.first;
    return '${categoryLabels.length} place types';
  }

  bool containsCategory(String id) => categoryIds.contains(id);

  SearchPlacesFilterEntity toggleCategory({
    required String id,
    required String label,
  }) {
    if (containsCategory(id)) {
      final removeIndex = categoryIds.indexOf(id);
      return SearchPlacesFilterEntity(
        categoryIds: [
          for (final categoryId in categoryIds)
            if (categoryId != id) categoryId,
        ],
        categoryLabels: [
          for (var index = 0; index < categoryLabels.length; index++)
            if (index != removeIndex) categoryLabels[index],
        ],
      );
    }

    return SearchPlacesFilterEntity(
      categoryIds: [...categoryIds, id],
      categoryLabels: [...categoryLabels, label],
    );
  }

  SearchPlacesFilterEntity clear() => empty;
}
