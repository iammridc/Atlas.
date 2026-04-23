import 'package:atlas/core/consts/app_colors.dart';
import 'package:atlas/core/injections/injections.dart';
import 'package:atlas/features/home/presentation/bloc/recommendation_cubit.dart';
import 'package:atlas/features/home/presentation/bloc/recommendations_state.dart';
import 'package:atlas/features/home/presentation/widgets/home_bottom_nav_bar.dart';
import 'package:atlas/features/home/presentation/widgets/hot_places_section.dart';
import 'package:atlas/features/home/presentation/widgets/map_section.dart';
import 'package:atlas/features/home/presentation/widgets/recommendation_section.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class HomePage extends StatefulWidget {
  final List<String> categoryTypes;

  const HomePage({super.key, required this.categoryTypes});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final RecommendationsCubit _recommendationsCubit;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _recommendationsCubit = getIt<RecommendationsCubit>()
      ..loadRecommendations(widget.categoryTypes);
  }

  @override
  void dispose() {
    _recommendationsCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _recommendationsCubit,
      child: Scaffold(
        extendBody: true,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: _buildActivePage()),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: HomeBottomNavBar(
                        selectedIndex: _selectedIndex,
                        onSelected: (index) =>
                            setState(() => _selectedIndex = index),
                        items: const [
                          HomeBottomNavBarItem(
                            icon: CupertinoIcons.house_fill,
                            label: 'Home',
                          ),
                          HomeBottomNavBarItem(
                            icon: CupertinoIcons.search,
                            label: 'Search',
                          ),
                          HomeBottomNavBarItem(
                            icon: CupertinoIcons.person_fill,
                            label: 'Profile',
                          ),
                          HomeBottomNavBarItem(
                            icon: CupertinoIcons.gear_alt_fill,
                            label: 'Settings',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivePage() {
    return switch (_selectedIndex) {
      0 => const _RecommendationsView(),
      1 => const _PlaceholderTab(
        icon: CupertinoIcons.search,
        title: 'Search',
        description: 'Search page will be implemented here later.',
      ),
      2 => const _PlaceholderTab(
        icon: CupertinoIcons.person_crop_circle,
        title: 'Profile',
        description: 'Profile page will be implemented here later.',
      ),
      _ => const _PlaceholderTab(
        icon: CupertinoIcons.gear_alt,
        title: 'Settings',
        description: 'Settings page will be implemented here later.',
      ),
    };
  }
}

class _RecommendationsView extends StatelessWidget {
  const _RecommendationsView();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: const PageStorageKey('recommendations-tab-scroll'),
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.of(context).padding.top),
        ),
        const SliverToBoxAdapter(child: HotPlacesSection()),
        SliverToBoxAdapter(
          child: BlocBuilder<RecommendationsCubit, RecommendationsState>(
            builder: (context, state) {
              return switch (state) {
                RecommendationsLoading() => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                ),
                RecommendationsLoaded(
                  recommendations: final places,
                  isLoadingMore: final isLoadingMore,
                ) =>
                  RecommendationsSection(
                    recommendations: places,
                    isLoadingMore: isLoadingMore,
                  ),
                RecommendationsError(isReloading: final isReloading) =>
                  RecommendationsSection(
                    recommendations: [],
                    hasError: true,
                    isReloading: isReloading,
                  ),
                _ => const SizedBox.shrink(),
              };
            },
          ),
        ),
        const SliverToBoxAdapter(child: MapSection()),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _PlaceholderTab({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor = isDark ? Colors.white54 : Colors.black45;

    return SafeArea(
      bottom: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 120),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 56,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.45,
                  color: secondaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
