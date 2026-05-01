import 'package:atlas/core/consts/app_colors.dart';
import 'package:atlas/features/home/domain/entity/search_places_filter_entity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SearchFiltersPage extends StatefulWidget {
  final SearchPlacesFilterEntity initialFilters;

  const SearchFiltersPage({super.key, required this.initialFilters});

  @override
  State<SearchFiltersPage> createState() => _SearchFiltersPageState();
}

class _SearchFiltersPageState extends State<SearchFiltersPage> {
  late SearchPlacesFilterEntity _filters;

  static const _categories = [
    _SearchFilterCategory(
      id: 'tourist_attraction',
      label: 'Tourist Attractions',
      icon: CupertinoIcons.sparkles,
    ),
    _SearchFilterCategory(
      id: 'museum',
      label: 'Museums',
      icon: CupertinoIcons.building_2_fill,
    ),
    _SearchFilterCategory(
      id: 'park',
      label: 'Parks',
      icon: CupertinoIcons.tree,
    ),
    _SearchFilterCategory(
      id: 'art_gallery',
      label: 'Art Galleries',
      icon: CupertinoIcons.photo_on_rectangle,
    ),
    _SearchFilterCategory(
      id: 'restaurant',
      label: 'Restaurants',
      icon: Icons.restaurant_outlined,
    ),
    _SearchFilterCategory(
      id: 'cafe',
      label: 'Cafes',
      icon: Icons.local_cafe_outlined,
    ),
    _SearchFilterCategory(
      id: 'shopping_mall',
      label: 'Shopping',
      icon: CupertinoIcons.bag,
    ),
    _SearchFilterCategory(
      id: 'hotel',
      label: 'Hotels',
      icon: Icons.hotel_outlined,
    ),
    _SearchFilterCategory(
      id: 'bar',
      label: 'Bars',
      icon: Icons.local_bar_outlined,
    ),
    _SearchFilterCategory(id: 'zoo', label: 'Zoos', icon: Icons.pets_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : AppColors.appPrimaryBlack;
    final secondaryColor = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Row(
                    children: [
                      _FilterIconButton(
                        icon: CupertinoIcons.chevron_left,
                        onTap: () => Navigator.of(context).pop(),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Search Filters',
                            maxLines: 1,
                            softWrap: false,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 26, 24, 78),
                    children: [
                      _FilterSectionTitle(
                        title: 'Place Type',
                        color: secondaryColor,
                      ),
                      const SizedBox(height: 8),
                      _FilterOptionTile(
                        icon: CupertinoIcons.circle_grid_hex,
                        title: 'All Places',
                        isSelected: !_filters.hasCategories,
                        titleColor: titleColor,
                        secondaryColor: secondaryColor,
                        onTap: () => setState(() {
                          _filters = SearchPlacesFilterEntity.empty;
                        }),
                      ),
                      ..._categories.map(
                        (category) => _FilterOptionTile(
                          icon: category.icon,
                          title: category.label,
                          isSelected: _filters.containsCategory(category.id),
                          titleColor: titleColor,
                          secondaryColor: secondaryColor,
                          onTap: () => setState(() {
                            _filters = _filters.toggleCategory(
                              id: category.id,
                              label: category.label,
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 20,
            child: SizedBox(
              height: 54,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(_filters),
                child: Text(
                  _filters.hasActiveFilters
                      ? 'Apply ${_filters.activeCount} filter${_filters.activeCount == 1 ? '' : 's'}'
                      : 'Apply Filters',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchFilterCategory {
  final String id;
  final String label;
  final IconData icon;

  const _SearchFilterCategory({
    required this.id,
    required this.label,
    required this.icon,
  });
}

class _FilterSectionTitle extends StatelessWidget {
  final String title;
  final Color color;

  const _FilterSectionTitle({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
    );
  }
}

class _FilterOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final Color titleColor;
  final Color secondaryColor;
  final VoidCallback onTap;

  const _FilterOptionTile({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.titleColor,
    required this.secondaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: titleColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(
              width: 24,
              child: isSelected
                  ? Icon(CupertinoIcons.checkmark, color: titleColor, size: 22)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _FilterIconButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          size: 22,
          color: isDark ? AppColors.appPrimaryWhite : AppColors.appPrimaryBlack,
        ),
      ),
    );
  }
}
