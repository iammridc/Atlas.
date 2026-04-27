import 'package:atlas/core/consts/app_colors.dart';
import 'package:atlas/core/injections/injections.dart';
import 'package:atlas/core/router/app_router.dart';
import 'package:atlas/core/theme/cubit/theme_cubit.dart';
import 'package:atlas/core/utils/app_snackbar.dart';
import 'package:atlas/core/utils/unit_conversions.dart';
import 'package:atlas/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:atlas/features/auth/presentation/bloc/auth_state.dart';
import 'package:atlas/features/home/presentation/bloc/recommendation_cubit.dart';
import 'package:atlas/features/home/presentation/bloc/recommendations_state.dart';
import 'package:atlas/features/home/presentation/bloc/search_places_cubit.dart';
import 'package:atlas/features/home/presentation/bloc/hot_places_cubit.dart';
import 'package:atlas/features/home/presentation/bloc/home_map_cubit.dart';
import 'package:atlas/features/home/presentation/widgets/home_bottom_nav_bar.dart';
import 'package:atlas/features/home/presentation/widgets/hot_places_section.dart';
import 'package:atlas/features/home/presentation/widgets/map_section.dart';
import 'package:atlas/features/home/presentation/widgets/recommendation_section.dart';
import 'package:atlas/features/home/presentation/widgets/search_tab_view.dart';
import 'package:atlas/features/profile/domain/repositories/profile_repository.dart';
import 'package:atlas/features/profile/presentation/pages/profile_page.dart';
import 'package:auto_route/auto_route.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

@RoutePage()
class HomePage extends StatefulWidget {
  final List<String> categoryTypes;

  const HomePage({super.key, required this.categoryTypes});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final RecommendationsCubit _recommendationsCubit;
  late final HotPlacesCubit _hotPlacesCubit;
  late final SearchPlacesCubit _searchPlacesCubit;
  late final HomeMapCubit _homeMapCubit;
  late List<String> _categoryTypes;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _categoryTypes = List<String>.from(widget.categoryTypes);
    _hotPlacesCubit = getIt<HotPlacesCubit>()..loadHotPlaces();
    _recommendationsCubit = getIt<RecommendationsCubit>()
      ..loadRecommendations(_categoryTypes);
    _searchPlacesCubit = getIt<SearchPlacesCubit>()..initialize();
    _homeMapCubit = getIt<HomeMapCubit>();
  }

  @override
  void dispose() {
    _hotPlacesCubit.close();
    _recommendationsCubit.close();
    _searchPlacesCubit.close();
    _homeMapCubit.close();
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
        BlocProvider.value(value: _hotPlacesCubit),
        BlocProvider.value(value: _searchPlacesCubit),
        BlocProvider.value(value: _homeMapCubit),
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

  static const double _bottomNavClearance = 76;

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
        const SliverToBoxAdapter(child: SizedBox(height: _bottomNavClearance)),
      ],
    );
  }
}

class _SettingsView extends StatefulWidget {
  const _SettingsView();

  @override
  State<_SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<_SettingsView> {
  static const double _bottomNavClearance = 76;
  static const _useFavoritesKey = 'settings_use_favorites_for_recommendations';
  static const _useReviewsKey = 'settings_use_reviews_for_recommendations';
  static const _recommendationNotificationsKey =
      'settings_recommendation_notifications';
  static const _publicReviewsKey = 'settings_public_reviews';
  static const _distanceUnitKey = UnitConversions.distanceUnitKey;
  static const _languageKey = 'settings_language';
  static const _currencyKey = UnitConversions.currencyKey;
  bool _useFavorites = true;
  bool _useReviews = true;
  bool _recommendationNotifications = false;
  bool _publicReviews = true;
  String _distanceUnit = 'km';
  String _language = 'English';
  String _currency = 'USD';
  bool _settingsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _useFavorites = prefs.getBool(_useFavoritesKey) ?? true;
      _useReviews = prefs.getBool(_useReviewsKey) ?? true;
      _recommendationNotifications =
          prefs.getBool(_recommendationNotificationsKey) ?? false;
      _publicReviews = prefs.getBool(_publicReviewsKey) ?? true;
      _distanceUnit = prefs.getString(_distanceUnitKey) ?? 'km';
      _language = prefs.getString(_languageKey) ?? 'English';
      if (_language == 'Deutsch') {
        _language = 'English';
        prefs.setString(_languageKey, _language);
      }
      _currency = UnitConversions.normalizeCurrency(
        prefs.getString(_currencyKey) ?? 'USD',
      );
      if (prefs.getString(_currencyKey) == 'GBP') {
        prefs.setString(_currencyKey, _currency);
      }
      _settingsLoaded = true;
    });
  }

  Future<void> _setBool(
    String key,
    bool value,
    ValueChanged<bool> apply,
  ) async {
    setState(() => apply(value));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _setString(
    String key,
    String value,
    ValueChanged<String> apply,
  ) async {
    setState(() => apply(value));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

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
              final user = state is AuthAuthenticated ? state.user : null;

              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  _bottomNavClearance,
                ),
                children: [
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tune Atlas around how you travel.',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!_settingsLoaded)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    _SettingsSection(
                      title: 'Appearance',
                      children: [
                        BlocBuilder<ThemeCubit, AppThemeMode>(
                          bloc: getIt<ThemeCubit>(),
                          builder: (context, themeMode) {
                            return _SettingsValueTile(
                              icon: CupertinoIcons.moon_stars,
                              title: 'Theme',
                              value: _themeModeLabel(themeMode),
                              onTap: () => _chooseValue<AppThemeMode>(
                                title: 'Theme',
                                values: AppThemeMode.values,
                                labels: const {
                                  AppThemeMode.light: 'Light',
                                  AppThemeMode.dark: 'Dark',
                                  AppThemeMode.system: 'System',
                                },
                                current: themeMode,
                                onSelected: (value) => getIt<ThemeCubit>()
                                    .setTheme(value, userId: user?.id),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    _SettingsSection(
                      title: 'Personalization',
                      children: [
                        _SettingsSwitchTile(
                          icon: CupertinoIcons.heart,
                          title: 'Use favorites',
                          subtitle: 'Improve recommendations from saved places',
                          value: _useFavorites,
                          onChanged: (value) => _setBool(
                            _useFavoritesKey,
                            value,
                            (next) => _useFavorites = next,
                          ),
                        ),
                        _SettingsSwitchTile(
                          icon: CupertinoIcons.star,
                          title: 'Use reviews',
                          subtitle: 'Improve recommendations from your ratings',
                          value: _useReviews,
                          onChanged: (value) => _setBool(
                            _useReviewsKey,
                            value,
                            (next) => _useReviews = next,
                          ),
                        ),
                        _SettingsSwitchTile(
                          icon: CupertinoIcons.bell,
                          title: 'Recommendation notifications',
                          subtitle: 'Get prompts when Atlas finds new ideas',
                          value: _recommendationNotifications,
                          onChanged: (value) => _setBool(
                            _recommendationNotificationsKey,
                            value,
                            (next) => _recommendationNotifications = next,
                          ),
                        ),
                      ],
                    ),
                    _SettingsSection(
                      title: 'Privacy & Data',
                      children: [
                        _SettingsSwitchTile(
                          icon: CupertinoIcons.eye,
                          title: 'Public reviews',
                          subtitle: _publicReviews
                              ? 'Your name and avatar can appear on reviews'
                              : 'Reviews stay private to your profile',
                          value: _publicReviews,
                          onChanged: _setPublicReviews,
                        ),
                        _SettingsActionTile(
                          icon: CupertinoIcons.trash,
                          title: 'Clear local cache/history',
                          subtitle: 'Remove recent searches on this device',
                          onTap: _clearLocalHistory,
                        ),
                      ],
                    ),
                    _SettingsSection(
                      title: 'Region',
                      children: [
                        _SettingsValueTile(
                          icon: CupertinoIcons.location,
                          title: 'Distance Unit',
                          value: _distanceUnitLabel(_distanceUnit),
                          onTap: () => _chooseValue(
                            title: 'Distance Unit',
                            values: const ['km', 'mi'],
                            labels: const {'km': 'Kilometers', 'mi': 'Miles'},
                            current: _distanceUnit,
                            onSelected: (value) => _setString(
                              _distanceUnitKey,
                              value,
                              (next) => _distanceUnit = next,
                            ),
                          ),
                        ),
                        _SettingsValueTile(
                          icon: CupertinoIcons.globe,
                          title: 'Language',
                          value: _language,
                          onTap: () => _chooseValue(
                            title: 'Language',
                            values: const ['English', 'Русский'],
                            current: _language,
                            onSelected: (value) => _setString(
                              _languageKey,
                              value,
                              (next) => _language = next,
                            ),
                          ),
                        ),
                        _SettingsValueTile(
                          icon: CupertinoIcons.money_dollar_circle,
                          title: 'Currency',
                          value: _currency,
                          onTap: () => _chooseValue(
                            title: 'Currency',
                            values: const ['RUB', 'BYN', 'EUR', 'USD'],
                            current: _currency,
                            onSelected: (value) => _setString(
                              _currencyKey,
                              value,
                              (next) => _currency = next,
                            ),
                          ),
                        ),
                      ],
                    ),
                    _SettingsSection(
                      title: 'Support',
                      children: [
                        const _SettingsInfoTile(
                          icon: CupertinoIcons.info,
                          title: 'App version',
                          value: '0.1.0',
                        ),
                        _SettingsActionTile(
                          icon: CupertinoIcons.doc_text,
                          title: 'Terms / Privacy policy',
                          subtitle: 'Read Atlas terms and privacy notes',
                          onTap: () => _showInfoDialog(
                            title: 'Terms / Privacy policy',
                            message:
                                'Atlas stores profile, preference, favorite, review, and trip data to provide recommendations and sync your travel activity. Add your final legal text or external policy links here before release.',
                          ),
                        ),
                        _SettingsActionTile(
                          icon: CupertinoIcons.mail,
                          title: 'Contact support / feedback',
                          subtitle: 'Send feedback to the Atlas team',
                          onTap: () => _showInfoDialog(
                            title: 'Contact support / feedback',
                            message:
                                'Email support@atlas.app with your feedback, bug reports, or feature ideas.',
                          ),
                        ),
                      ],
                    ),
                    _SettingsSection(
                      title: 'Account',
                      children: [
                        _SettingsActionTile(
                          icon: CupertinoIcons.square_arrow_right,
                          title: 'Log out',
                          subtitle: user?.email ?? 'Return to sign in',
                          onTap: isLoading
                              ? null
                              : () => context.read<AuthCubit>().signOut(),
                        ),
                        _SettingsActionTile(
                          icon: CupertinoIcons.delete_simple,
                          title: 'Delete account',
                          subtitle: 'Permanently remove your Atlas account',
                          isDestructive: true,
                          onTap: isLoading ? null : _confirmDeleteAccount,
                        ),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _clearLocalHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = getIt<FirebaseAuth>().currentUser?.uid;
    await prefs.remove(SearchPlacesCubit.recentQueriesKeyForUser(uid));
    await prefs.remove(SearchPlacesCubit.legacyRecentQueriesKey);
    if (mounted) {
      await context.read<SearchPlacesCubit>().clearRecentQueries();
    }
    if (!mounted) return;
    AppSnackbar.show(
      context,
      message: 'Local search history cleared.',
      type: SnackbarType.success,
    );
  }

  Future<void> _setPublicReviews(bool value) async {
    final previous = _publicReviews;
    await _setBool(_publicReviewsKey, value, (next) => _publicReviews = next);
    final result = await getIt<ProfileRepository>().setReviewsPublic(value);
    if (!mounted) return;

    result.fold(
      (error) {
        _setBool(_publicReviewsKey, previous, (next) => _publicReviews = next);
        AppSnackbar.show(
          context,
          message: error.message,
          type: SnackbarType.error,
        );
      },
      (_) => AppSnackbar.show(
        context,
        message: value ? 'Reviews are public.' : 'Reviews are private.',
        type: SnackbarType.success,
      ),
    );
  }

  String _distanceUnitLabel(String value) {
    return switch (value) {
      'mi' => 'Miles',
      _ => 'Kilometers',
    };
  }

  String _themeModeLabel(AppThemeMode value) {
    return switch (value) {
      AppThemeMode.light => 'Light',
      AppThemeMode.dark => 'Dark',
      AppThemeMode.system => 'System',
    };
  }

  Future<void> _chooseValue<T>({
    required String title,
    required List<T> values,
    Map<T, String> labels = const {},
    required T current,
    required ValueChanged<T> onSelected,
  }) async {
    final selected = await showModalBottomSheet<T>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              for (final value in values)
                ListTile(
                  title: Text(labels[value] ?? value.toString()),
                  trailing: value == current
                      ? const Icon(CupertinoIcons.checkmark)
                      : null,
                  onTap: () => Navigator.of(context).pop(value),
                ),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      onSelected(selected);
    }
  }

  Future<void> _showInfoDialog({
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final controller = TextEditingController();
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete account?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This removes your profile, favorites, reviews, and trips. Type DELETE to confirm.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(hintText: 'DELETE'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim() == 'DELETE'),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (shouldDelete == true && mounted) {
      context.read<AuthCubit>().deleteAccount();
    }
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          Column(children: children),
        ],
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      secondary: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.fromLTRB(16, 2, 12, 2),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDestructive;
  final VoidCallback? onTap;

  const _SettingsActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.redAccent : null;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w700, color: color),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(CupertinoIcons.chevron_right, size: 18),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class _SettingsValueTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _SettingsValueTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(value),
      trailing: const Icon(CupertinoIcons.chevron_right, size: 18),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class _SettingsInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _SettingsInfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(value),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
