import 'package:atlas/core/consts/app_colors.dart';
import 'package:atlas/core/injections/injections.dart';
import 'package:atlas/core/localization/app_localizations.dart';
import 'package:atlas/core/localization/locale_cubit.dart';
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
import 'package:atlas/features/profile/presentation/bloc/profile_cubit.dart';
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
  late final ProfileCubit _profileCubit;
  late List<String> _categoryTypes;
  int _selectedIndex = 0;
  int _searchActivationToken = 0;

  @override
  void initState() {
    super.initState();
    _categoryTypes = List<String>.from(widget.categoryTypes);
    _hotPlacesCubit = getIt<HotPlacesCubit>()..loadHotPlaces();
    _recommendationsCubit = getIt<RecommendationsCubit>()
      ..loadRecommendations(_categoryTypes);
    _searchPlacesCubit = getIt<SearchPlacesCubit>()..initialize();
    _homeMapCubit = getIt<HomeMapCubit>();
    _profileCubit = getIt<ProfileCubit>()..loadProfile();
  }

  @override
  void dispose() {
    _hotPlacesCubit.close();
    _recommendationsCubit.close();
    _searchPlacesCubit.close();
    _homeMapCubit.close();
    _profileCubit.close();
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
        BlocProvider.value(value: _profileCubit),
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
                    isActive: _selectedIndex == 1,
                    activationToken: _searchActivationToken,
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
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: HomeBottomNavBar(
                        selectedIndex: _selectedIndex,
                        onSelected: (index) => setState(() {
                          _selectedIndex = index;
                          if (index == 1) {
                            _searchActivationToken++;
                          }
                        }),
                        items: [
                          HomeBottomNavBarItem(
                            icon: CupertinoIcons.house_fill,
                            label: context.l10n.t('home'),
                          ),
                          HomeBottomNavBarItem(
                            icon: CupertinoIcons.search,
                            label: context.l10n.t('search'),
                          ),
                          HomeBottomNavBarItem(
                            icon: CupertinoIcons.person_fill,
                            label: context.l10n.t('profile'),
                          ),
                          HomeBottomNavBarItem(
                            icon: CupertinoIcons.gear_alt_fill,
                            label: context.l10n.t('settings'),
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
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          context.read<HotPlacesCubit>().reload(),
          context.read<RecommendationsCubit>().reload(),
        ]);
      },
      child: CustomScrollView(
        key: const PageStorageKey('recommendations-tab-scroll'),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
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
          const SliverToBoxAdapter(
            child: SizedBox(height: _bottomNavClearance),
          ),
        ],
      ),
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
    final user = getIt<FirebaseAuth>().currentUser;
    final l10n = context.l10n;
    final locale = context.watch<LocaleCubit>().state;

    return SafeArea(
      bottom: false,
      child: BlocProvider.value(
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
          child: BlocBuilder<AuthCubit, AuthState>(
            buildWhen: (previous, current) =>
                previous is AuthLoading || current is AuthLoading,
            builder: (context, state) {
              final isLoading = state is AuthLoading;

              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  _bottomNavClearance,
                ),
                children: [
                  Text(
                    l10n.t('settings'),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.t('settingsSubtitle'),
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
                      title: l10n.t('appearance'),
                      children: [
                        BlocBuilder<ThemeCubit, AppThemeMode>(
                          bloc: getIt<ThemeCubit>(),
                          builder: (context, themeMode) {
                            return _SettingsValueTile(
                              icon: CupertinoIcons.moon_stars,
                              title: l10n.t('theme'),
                              value: _themeModeLabel(themeMode),
                              onTap: () => _chooseValue<AppThemeMode>(
                                title: l10n.t('theme'),
                                values: AppThemeMode.values,
                                labels: {
                                  AppThemeMode.light: l10n.t('light'),
                                  AppThemeMode.dark: l10n.t('dark'),
                                  AppThemeMode.system: l10n.t('system'),
                                },
                                current: themeMode,
                                onSelected: (value) => getIt<ThemeCubit>()
                                    .setTheme(value, userId: user?.uid),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    _SettingsSection(
                      title: l10n.t('personalization'),
                      children: [
                        _SettingsSwitchTile(
                          icon: CupertinoIcons.heart,
                          title: l10n.t('useFavorites'),
                          subtitle: l10n.t('useFavoritesSubtitle'),
                          value: _useFavorites,
                          onChanged: (value) => _setBool(
                            _useFavoritesKey,
                            value,
                            (next) => _useFavorites = next,
                          ),
                        ),
                        _SettingsSwitchTile(
                          icon: CupertinoIcons.star,
                          title: l10n.t('useReviews'),
                          subtitle: l10n.t('useReviewsSubtitle'),
                          value: _useReviews,
                          onChanged: (value) => _setBool(
                            _useReviewsKey,
                            value,
                            (next) => _useReviews = next,
                          ),
                        ),
                        _SettingsSwitchTile(
                          icon: CupertinoIcons.bell,
                          title: l10n.t('recommendationNotifications'),
                          subtitle: l10n.t(
                            'recommendationNotificationsSubtitle',
                          ),
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
                      title: l10n.t('privacyData'),
                      children: [
                        _SettingsSwitchTile(
                          icon: CupertinoIcons.eye,
                          title: l10n.t('publicReviews'),
                          subtitle: _publicReviews
                              ? l10n.t('reviewsPublicSubtitle')
                              : l10n.t('reviewsPrivateSubtitle'),
                          value: _publicReviews,
                          onChanged: _setPublicReviews,
                        ),
                        _SettingsActionTile(
                          icon: CupertinoIcons.trash,
                          title: l10n.t('clearLocalCache'),
                          subtitle: l10n.t('clearLocalCacheSubtitle'),
                          onTap: _clearLocalHistory,
                        ),
                      ],
                    ),
                    _SettingsSection(
                      title: l10n.t('region'),
                      children: [
                        _SettingsValueTile(
                          icon: CupertinoIcons.location,
                          title: l10n.t('distanceUnit'),
                          value: _distanceUnitLabel(_distanceUnit),
                          onTap: () => _chooseValue(
                            title: l10n.t('distanceUnit'),
                            values: const ['km', 'mi'],
                            labels: {
                              'km': l10n.t('kilometers'),
                              'mi': l10n.t('miles'),
                            },
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
                          title: l10n.t('language'),
                          value: LocaleCubit.labelForLocale(locale),
                          onTap: () => _chooseValue(
                            title: l10n.t('language'),
                            values: const [
                              LocaleCubit.englishLabel,
                              LocaleCubit.russianLabel,
                            ],
                            current: LocaleCubit.labelForLocale(locale),
                            onSelected: (value) async {
                              setState(() => _language = value);
                              await getIt<LocaleCubit>().setLanguageLabel(
                                value,
                              );
                            },
                          ),
                        ),
                        _SettingsValueTile(
                          icon: CupertinoIcons.money_dollar_circle,
                          title: l10n.t('currency'),
                          value: _currency,
                          onTap: () => _chooseValue(
                            title: l10n.t('currency'),
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
                      title: l10n.t('support'),
                      children: [
                        _SettingsInfoTile(
                          icon: CupertinoIcons.info,
                          title: l10n.t('appVersion'),
                          value: '0.1.0',
                        ),
                        _SettingsActionTile(
                          icon: CupertinoIcons.doc_text,
                          title: l10n.t('termsPrivacy'),
                          subtitle: l10n.t('termsPrivacySubtitle'),
                          onTap: () => _showInfoDialog(
                            title: l10n.t('termsPrivacy'),
                            message: l10n.t('termsPrivacyMessage'),
                          ),
                        ),
                        _SettingsActionTile(
                          icon: CupertinoIcons.mail,
                          title: l10n.t('contactSupport'),
                          subtitle: l10n.t('contactSupportSubtitle'),
                          onTap: () => _showInfoDialog(
                            title: l10n.t('contactSupport'),
                            message: l10n.t('contactSupportMessage'),
                          ),
                        ),
                      ],
                    ),
                    _SettingsSection(
                      title: l10n.t('account'),
                      children: [
                        _SettingsActionTile(
                          icon: CupertinoIcons.square_arrow_right,
                          title: l10n.t('logOut'),
                          subtitle: user?.email ?? l10n.t('returnToSignIn'),
                          onTap: isLoading
                              ? null
                              : () => getIt<AuthCubit>().signOut(),
                        ),
                        _SettingsActionTile(
                          icon: CupertinoIcons.delete_simple,
                          title: l10n.t('deleteAccount'),
                          subtitle: l10n.t('deleteAccountSubtitle'),
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
      message: context.l10n.t('localHistoryCleared'),
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
        message: value
            ? context.l10n.t('reviewsArePublic')
            : context.l10n.t('reviewsArePrivate'),
        type: SnackbarType.success,
      ),
    );
  }

  String _distanceUnitLabel(String value) {
    return switch (value) {
      'mi' => context.l10n.t('miles'),
      _ => context.l10n.t('kilometers'),
    };
  }

  String _themeModeLabel(AppThemeMode value) {
    return switch (value) {
      AppThemeMode.light => context.l10n.t('light'),
      AppThemeMode.dark => context.l10n.t('dark'),
      AppThemeMode.system => context.l10n.t('system'),
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              for (final value in values)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(value),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(labels[value] ?? value.toString()),
                        ),
                        SizedBox(
                          width: 24,
                          child: value == current
                              ? const Icon(CupertinoIcons.checkmark)
                              : null,
                        ),
                      ],
                    ),
                  ),
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
            child: Text(context.l10n.t('ok')),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );

    if (shouldDelete == true && mounted) {
      getIt<AuthCubit>().deleteAccount();
    }
  }
}

class _DeleteAccountDialog extends StatelessWidget {
  const _DeleteAccountDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.t('deleteAccountTitle')),
      content: Text(context.l10n.t('deleteAccountMessage')),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.l10n.t('cancel')),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(context.l10n.t('delete')),
        ),
      ],
    );
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
              fontWeight: FontWeight.bold,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.white60 : Colors.black54;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 10, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _SettingsTileIcon(icon: icon, color: titleColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch.adaptive(value: value, onChanged: onChanged),
          ],
        ),
      ),
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

    return _SettingsPlainTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      titleColor: color,
      iconColor: color,
      trailing: const Icon(CupertinoIcons.chevron_right, size: 18),
      onTap: onTap,
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
    return _SettingsPlainTile(
      icon: icon,
      title: title,
      subtitle: value,
      trailing: const Icon(CupertinoIcons.chevron_right, size: 18),
      onTap: onTap,
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
    return _SettingsPlainTile(icon: icon, title: title, subtitle: value);
  }
}

class _SettingsPlainTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? titleColor;
  final Color? iconColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsPlainTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.titleColor,
    this.iconColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveTitleColor =
        titleColor ?? (isDark ? Colors.white : Colors.black);
    final subtitleColor = isDark ? Colors.white60 : Colors.black54;

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 8, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _SettingsTileIcon(
            icon: icon,
            color: iconColor ?? effectiveTitleColor,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: effectiveTitleColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );

    if (onTap == null) return content;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: content,
    );
  }
}

class _SettingsTileIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _SettingsTileIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05),
      ),
      child: Icon(icon, size: 24, color: color),
    );
  }
}
