import 'package:atlas/core/consts/app_colors.dart';
import 'package:atlas/features/home/presentation/bloc/search_places_cubit.dart';
import 'package:atlas/features/home/presentation/bloc/search_places_state.dart';
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 108),
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
                    icon: state.hasQuery
                        ? CupertinoIcons.xmark
                        : _focusNode.hasFocus
                        ? CupertinoIcons.keyboard_chevron_compact_down
                        : CupertinoIcons.slider_horizontal_3,
                    onTap: state.hasQuery
                        ? _clearQuery
                        : () {
                            if (_focusNode.hasFocus) {
                              FocusScope.of(context).unfocus();
                            } else {
                              _focusNode.requestFocus();
                            }
                          },
                    isDark: isDark,
                  ),
                ],
              ),
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
                          onRetry: () =>
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

  const _TopIconButton({
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
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Icon(icon, size: 22),
      ),
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
        if (state.recentQueries.isEmpty)
          _EmptyStateCard(
            icon: CupertinoIcons.time,
            title: 'No recent searches yet',
            subtitle:
                'Start typing to instantly explore places and save your latest requests here.',
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            titleColor: titleColor,
            secondaryTextColor: secondaryTextColor,
          )
        else
          ...state.recentQueries.map(
            (query) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RecentQueryTile(
                query: query,
                surfaceColor: surfaceColor,
                borderColor: borderColor,
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
  final VoidCallback onRetry;
  final VoidCallback onResultTap;

  const _SearchResultsView({
    super.key,
    required this.state,
    required this.titleColor,
    required this.secondaryTextColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.onRetry,
    required this.onResultTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey('search-results-list'),
      physics: const BouncingScrollPhysics(),
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
          _StateMessageCard(
            icon: CupertinoIcons.exclamationmark_triangle,
            title: 'Couldn’t load search results',
            subtitle: state.errorMessage,
            actionLabel: 'Try Again',
            onActionTap: onRetry,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            titleColor: titleColor,
            secondaryTextColor: secondaryTextColor,
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
    );
  }
}

class _RecentQueryTile extends StatelessWidget {
  final String query;
  final Color surfaceColor;
  final Color borderColor;
  final Color titleColor;
  final Color secondaryTextColor;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _RecentQueryTile({
    required this.query,
    required this.surfaceColor,
    required this.borderColor,
    required this.titleColor,
    required this.secondaryTextColor,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(CupertinoIcons.time, size: 18, color: secondaryTextColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                query,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onRemove,
              child: Icon(
                CupertinoIcons.xmark,
                size: 18,
                color: secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
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

class _StateMessageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onActionTap;
  final Color surfaceColor;
  final Color borderColor;
  final Color titleColor;
  final Color secondaryTextColor;

  const _StateMessageCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onActionTap,
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
          Icon(icon, size: 28, color: AppColors.errorColor),
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
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onActionTap,
            style: FilledButton.styleFrom(
              backgroundColor: titleColor,
              foregroundColor:
                  ThemeData.estimateBrightnessForColor(titleColor) ==
                      Brightness.dark
                  ? Colors.white
                  : Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
