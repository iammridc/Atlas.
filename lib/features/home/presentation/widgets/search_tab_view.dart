import 'package:atlas/core/consts/app_colors.dart';
import 'package:atlas/core/widgets/transient_error_placeholder.dart';
import 'package:atlas/features/home/domain/entity/search_places_filter_entity.dart';
import 'package:atlas/features/home/presentation/bloc/search_places_cubit.dart';
import 'package:atlas/features/home/presentation/bloc/search_places_state.dart';
import 'package:atlas/features/home/presentation/pages/search_filters_page.dart';
import 'package:atlas/features/home/presentation/widgets/search_result_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchTabView extends StatefulWidget {
  final VoidCallback onBackToHome;

  const SearchTabView({super.key, required this.onBackToHome});

  @override
  State<SearchTabView> createState() => _SearchTabViewState();
}

class _SearchTabViewState extends State<SearchTabView> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    final searchCubit = context.read<SearchPlacesCubit>();
    _controller = TextEditingController(text: searchCubit.state.query);
    _focusNode = FocusNode()..addListener(_handleFocusChanged);
    _controller.addListener(_handleQueryChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleQueryChanged)
      ..dispose();
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    setState(() {});
  }

  void _handleQueryChanged() {
    context.read<SearchPlacesCubit>().onQueryChanged(_controller.text);
  }

  void _applyQuery(String query, {bool saveToRecent = true}) {
    _controller
      ..text = query
      ..selection = TextSelection.collapsed(offset: query.length);
    _focusNode.requestFocus();
    context.read<SearchPlacesCubit>().searchNow(
      query,
      saveToRecent: saveToRecent,
    );
  }

  void _clearQuery() {
    _controller.clear();
    _focusNode.requestFocus();
  }

  Future<void> _openFiltersPage() async {
    FocusScope.of(context).unfocus();

    final result = await Navigator.of(context).push<SearchPlacesFilterEntity>(
      MaterialPageRoute(
        builder: (_) => SearchFiltersPage(
          initialFilters: context.read<SearchPlacesCubit>().state.filters,
        ),
      ),
    );

    if (!mounted || result == null) return;
    await context.read<SearchPlacesCubit>().updateFilters(result);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SearchPlacesCubit>().state;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sectionTitleColor = isDark ? Colors.white : AppColors.appPrimaryBlack;
    final secondaryTextColor = isDark
        ? Colors.white.withValues(alpha: 0.66)
        : Colors.black.withValues(alpha: 0.52);
    final surfaceColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);
    final elevatedSurfaceColor = isDark
        ? Colors.white.withValues(alpha: 0.09)
        : Colors.black.withValues(alpha: 0.06);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.08);
    final accentBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.16);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 108),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _TopIconButton(
                    icon: CupertinoIcons.chevron_left,
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      widget.onBackToHome();
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: _focusNode.hasFocus
                            ? elevatedSurfaceColor
                            : surfaceColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _focusNode.hasFocus
                              ? accentBorderColor
                              : borderColor,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.search,
                            size: 20,
                            color: secondaryTextColor,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              textInputAction: TextInputAction.search,
                              cursorColor: sectionTitleColor,
                              style: TextStyle(
                                color: sectionTitleColor,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration.collapsed(
                                hintText: 'Search places, cities, landmarks...',
                                hintStyle: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              onSubmitted: (value) {
                                context.read<SearchPlacesCubit>().searchNow(
                                  value,
                                  saveToRecent: true,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _TopIconButton(
                    icon: state.hasQuery && _focusNode.hasFocus
                        ? CupertinoIcons.xmark
                        : _focusNode.hasFocus
                        ? CupertinoIcons.keyboard_chevron_compact_down
                        : CupertinoIcons.slider_horizontal_3,
                    onTap: state.hasQuery && _focusNode.hasFocus
                        ? _clearQuery
                        : () {
                            if (_focusNode.hasFocus) {
                              FocusScope.of(context).unfocus();
                            } else {
                              _openFiltersPage();
                            }
                          },
                    isDark: isDark,
                    isActive: state.filters.hasActiveFilters,
                  ),
                ],
              ),
              if (state.filters.hasActiveFilters) ...[
                const SizedBox(height: 12),
                _ActiveSearchFilterBar(
                  label: state.filters.summaryLabel,
                  isDark: isDark,
                  onClear: () =>
                      context.read<SearchPlacesCubit>().clearFilters(),
                ),
                const SizedBox(height: 18),
              ] else
                const SizedBox(height: 26),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: state.hasQuery
                      ? _SearchResultsView(
                          key: ValueKey('results-${state.query}'),
                          state: state,
                          titleColor: sectionTitleColor,
                          secondaryTextColor: secondaryTextColor,
                          surfaceColor: surfaceColor,
                          borderColor: borderColor,
                          onRefresh: () =>
                              context.read<SearchPlacesCubit>().retry(),
                          onResultTap: () => context
                              .read<SearchPlacesCubit>()
                              .saveCurrentQuery(),
                        )
                      : _RecentRequestsView(
                          key: const ValueKey('recents'),
                          state: state,
                          titleColor: sectionTitleColor,
                          secondaryTextColor: secondaryTextColor,
                          surfaceColor: surfaceColor,
                          borderColor: borderColor,
                          onClearAll: state.recentQueries.isEmpty
                              ? null
                              : () => context
                                    .read<SearchPlacesCubit>()
                                    .clearRecentQueries(),
                          onQueryTap: _applyQuery,
                          onQueryRemove: (query) => context
                              .read<SearchPlacesCubit>()
                              .removeRecentQuery(query),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final bool isActive;

  const _TopIconButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
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
              color: isDark
                  ? AppColors.appPrimaryWhite
                  : AppColors.appPrimaryBlack,
            ),
          ),
          if (isActive)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.errorColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActiveSearchFilterBar extends StatelessWidget {
  final String label;
  final bool isDark;
  final VoidCallback onClear;

  const _ActiveSearchFilterBar({
    required this.label,
    required this.isDark,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? Colors.white : AppColors.appPrimaryBlack;
    final secondaryColor = isDark
        ? Colors.white.withValues(alpha: 0.66)
        : Colors.black.withValues(alpha: 0.52);

    return Row(
      children: [
        Icon(CupertinoIcons.slider_horizontal_3, size: 18, color: titleColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: titleColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(
          onPressed: onClear,
          icon: Icon(CupertinoIcons.xmark, size: 18, color: secondaryColor),
          tooltip: 'Clear filter',
        ),
      ],
    );
  }
}

class _RecentRequestsView extends StatelessWidget {
  final SearchPlacesState state;
  final Color titleColor;
  final Color secondaryTextColor;
  final Color surfaceColor;
  final Color borderColor;
  final VoidCallback? onClearAll;
  final ValueChanged<String> onQueryTap;
  final ValueChanged<String> onQueryRemove;

  const _RecentRequestsView({
    super.key,
    required this.state,
    required this.titleColor,
    required this.secondaryTextColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.onClearAll,
    required this.onQueryTap,
    required this.onQueryRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey('search-recents-list'),
      physics: const BouncingScrollPhysics(),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Recent Requests',
                style: TextStyle(
                  color: titleColor,
                  fontSize: 29,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
            ),
            TextButton(
              onPressed: onClearAll,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.errorColor,
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
              child: const Text(
                'Clear All',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (state.recentQueries.isNotEmpty)
          ...state.recentQueries.map(
            (query) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _RecentQueryTile(
                query: query,
                titleColor: titleColor,
                secondaryTextColor: secondaryTextColor,
                onTap: () => onQueryTap(query),
                onRemove: () => onQueryRemove(query),
              ),
            ),
          ),
      ],
    );
  }
}

class _SearchResultsView extends StatelessWidget {
  final SearchPlacesState state;
  final Color titleColor;
  final Color secondaryTextColor;
  final Color surfaceColor;
  final Color borderColor;
  final Future<void> Function() onRefresh;
  final VoidCallback onResultTap;

  const _SearchResultsView({
    super.key,
    required this.state,
    required this.titleColor,
    required this.secondaryTextColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.onRefresh,
    required this.onResultTap,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        key: const PageStorageKey('search-results-list'),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: [
          Text(
            state.isLoading
                ? 'Searching...'
                : 'Found ${state.results.length} ${state.results.length == 1 ? 'Result' : 'Results'}',
            style: TextStyle(
              color: titleColor,
              fontSize: 29,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 16),
          if (state.isLoading)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Center(
                child: CircularProgressIndicator(
                  color: titleColor,
                  strokeWidth: 2.6,
                ),
              ),
            )
          else if (state.hasError)
            TransientErrorPlaceholder(
              icon: Icons.wifi_off_rounded,
              title: 'Couldn’t load search results',
              message: state.errorMessage,
            )
          else if (state.hasSearched && state.results.isEmpty)
            _EmptyStateCard(
              icon: CupertinoIcons.search,
              title: 'No matches found',
              subtitle:
                  'Try a place name, city, or landmark with a little more detail.',
              surfaceColor: surfaceColor,
              borderColor: borderColor,
              titleColor: titleColor,
              secondaryTextColor: secondaryTextColor,
            )
          else
            ...state.results.map(
              (place) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: SearchResultCard(place: place, onTap: onResultTap),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecentQueryTile extends StatelessWidget {
  final String query;
  final Color titleColor;
  final Color secondaryTextColor;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _RecentQueryTile({
    required this.query,
    required this.titleColor,
    required this.secondaryTextColor,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(CupertinoIcons.time, size: 24, color: titleColor),
      title: Text(
        query,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: titleColor,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        'Recent request',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: secondaryTextColor),
      ),
      trailing: IconButton(
        onPressed: onRemove,
        icon: Icon(CupertinoIcons.xmark, size: 20, color: secondaryTextColor),
        tooltip: 'Remove',
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color surfaceColor;
  final Color borderColor;
  final Color titleColor;
  final Color secondaryTextColor;

  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.surfaceColor,
    required this.borderColor,
    required this.titleColor,
    required this.secondaryTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: secondaryTextColor),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: titleColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
