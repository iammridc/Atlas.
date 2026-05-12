import 'package:atlas/core/consts/app_colors.dart';
import 'package:atlas/core/localization/app_localizations.dart';
import 'package:atlas/core/widgets/fitted_single_line_text.dart';
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
      icon: CupertinoIcons.sparkles,
    ),
    _SearchFilterCategory(id: 'museum', icon: CupertinoIcons.building_2_fill),
    _SearchFilterCategory(id: 'park', icon: CupertinoIcons.tree),
    _SearchFilterCategory(
      id: 'art_gallery',
      icon: CupertinoIcons.photo_on_rectangle,
    ),
    _SearchFilterCategory(id: 'restaurant', icon: Icons.restaurant_outlined),
    _SearchFilterCategory(id: 'cafe', icon: Icons.local_cafe_outlined),
    _SearchFilterCategory(id: 'shopping_mall', icon: CupertinoIcons.bag),
    _SearchFilterCategory(id: 'hotel', icon: Icons.hotel_outlined),
    _SearchFilterCategory(id: 'bar', icon: Icons.local_bar_outlined),
    _SearchFilterCategory(id: 'zoo', icon: Icons.pets_outlined),
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
                            context.l10n.t('searchFilters'),
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
                        title: context.l10n.t('placeType'),
                        color: secondaryColor,
                      ),
                      const SizedBox(height: 8),
                      _FilterOptionTile(
                        icon: CupertinoIcons.circle_grid_hex,
                        title: context.l10n.t('allPlaces'),
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
                          title: localizedSearchFilterCategoryLabel(
                            context,
                            category.id,
                          ),
                          isSelected: _filters.containsCategory(category.id),
                          titleColor: titleColor,
                          secondaryColor: secondaryColor,
                          onTap: () => setState(() {
                            _filters = _filters.toggleCategory(
                              id: category.id,
                              label: localizedSearchFilterCategoryLabel(
                                context,
                                category.id,
                              ),
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
                      ? context.l10n.named('applyFiltersCount', {
                          'count': _filters.activeCount,
                        })
                      : context.l10n.t('applyFilters'),
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
  final IconData icon;

  const _SearchFilterCategory({required this.id, required this.icon});
}

String localizedSearchFilterCategoryLabel(
  BuildContext context,
  String id, [
  String? fallback,
]) {
  final key = switch (id) {
    'tourist_attraction' => 'touristAttractions',
    'museum' => 'museums',
    'park' => 'parks',
    'art_gallery' => 'artGalleries',
    'restaurant' => 'restaurant',
    'cafe' => 'cafes',
    'shopping_mall' => 'shopping',
    'hotel' => 'hotels',
    'bar' => 'bars',
    'zoo' => 'zoos',
    _ => null,
  };
  return key == null ? (fallback ?? id) : context.l10n.t(key);
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
              child: FittedSingleLineText(
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
