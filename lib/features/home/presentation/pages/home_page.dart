import 'package:atlas/core/consts/app_colors.dart';
import 'package:atlas/core/injections/injections.dart';
import 'package:atlas/core/router/app_router.dart';
import 'package:atlas/core/utils/app_snackbar.dart';
import 'package:atlas/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:atlas/features/auth/presentation/bloc/auth_state.dart';
import 'package:atlas/features/home/presentation/bloc/recommendation_cubit.dart';
import 'package:atlas/features/home/presentation/bloc/recommendations_state.dart';
import 'package:atlas/features/home/presentation/bloc/search_places_cubit.dart';
import 'package:atlas/features/home/presentation/widgets/home_bottom_nav_bar.dart';
import 'package:atlas/features/home/presentation/widgets/hot_places_section.dart';
import 'package:atlas/features/home/presentation/widgets/map_section.dart';
import 'package:atlas/features/home/presentation/widgets/recommendation_section.dart';
import 'package:atlas/features/home/presentation/widgets/search_tab_view.dart';
import 'package:atlas/features/profile/presentation/pages/profile_page.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
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
  late final SearchPlacesCubit _searchPlacesCubit;
  late List<String> _categoryTypes;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _categoryTypes = List<String>.from(widget.categoryTypes);
    _recommendationsCubit = getIt<RecommendationsCubit>()
      ..loadRecommendations(_categoryTypes);
    _searchPlacesCubit = getIt<SearchPlacesCubit>()..initialize();
  }

  @override
  void dispose() {
    _recommendationsCubit.close();
    _searchPlacesCubit.close();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.categoryTypes, widget.categoryTypes)) {
      _categoryTypes = List<String>.from(widget.categoryTypes);
      _recommendationsCubit.loadRecommendations(_categoryTypes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _recommendationsCubit),
        BlocProvider.value(value: _searchPlacesCubit),
      ],
      child: Scaffold(
        extendBody: true,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  const _RecommendationsView(),
                  SearchTabView(
                    onBackToHome: () => setState(() => _selectedIndex = 0),
                  ),
                  ProfilePage(
                    onPreferencesUpdated: (categoryTypes) {
                      final nextCategoryTypes = List<String>.from(
                        categoryTypes,
                      );
                      setState(() {
                        _categoryTypes = nextCategoryTypes;
                        _selectedIndex = 0;
                      });
                      _recommendationsCubit.loadRecommendations(
                        nextCategoryTypes,
                      );
                    },
                  ),
                  const _SettingsView(),
                ],
              ),
            ),
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

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider.value(
      value: getIt<AuthCubit>(),
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            context.router.replaceAll([const SplashRoute()]);
            return;
          }

          if (state is AuthError) {
            AppSnackbar.show(
              context,
              message: state.message,
              type: SnackbarType.error,
            );
          }
        },
        child: SafeArea(
          bottom: false,
          child: BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              final isLoading = state is AuthLoading;

              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Just one action for now.',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () => context.read<AuthCubit>().signOut(),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          backgroundColor: isDark ? Colors.white : Colors.black,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        child: isLoading
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: isDark ? Colors.black : Colors.white,
                                ),
                              )
                            : const Text(
                                'Log Out',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
