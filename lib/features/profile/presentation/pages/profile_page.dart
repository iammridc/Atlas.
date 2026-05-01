import 'dart:convert';
import 'dart:async';

import 'package:atlas/core/consts/app_colors.dart';
import 'package:atlas/core/injections/injections.dart';
import 'package:atlas/core/utils/app_snackbar.dart';
import 'package:atlas/core/widgets/transient_error_placeholder.dart';
import 'package:atlas/features/preferences/presentation/pages/preferences_page.dart';
import 'package:atlas/features/profile/domain/entities/profile_gamification_entity.dart';
import 'package:atlas/features/profile/domain/entities/profile_summary_entity.dart';
import 'package:atlas/features/profile/domain/services/favorite_places_sync_service.dart';
import 'package:atlas/features/profile/domain/services/planned_trips_sync_service.dart';
import 'package:atlas/features/profile/domain/services/profile_reviews_sync_service.dart';
import 'package:atlas/features/profile/presentation/pages/achievements_page.dart';
import 'package:atlas/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:atlas/features/profile/presentation/bloc/profile_state.dart';
import 'package:atlas/features/profile/presentation/pages/favorite_places_page.dart';
import 'package:atlas/features/profile/presentation/pages/planned_trips_page.dart';
import 'package:atlas/features/profile/presentation/pages/profile_reviews_page.dart';
import 'package:atlas/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:atlas/features/profile/presentation/widgets/profile_section_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatelessWidget {
  final ValueChanged<List<String>>? onPreferencesUpdated;

  const ProfilePage({super.key, this.onPreferencesUpdated});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileCubit>()..loadProfile(),
      child: _ProfileView(onPreferencesUpdated: onPreferencesUpdated),
    );
  }
}

class _ProfileView extends StatefulWidget {
  final ValueChanged<List<String>>? onPreferencesUpdated;

  const _ProfileView({this.onPreferencesUpdated});

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  final _usernameController = TextEditingController();
  final _usernameFocusNode = FocusNode();
  final _imagePicker = ImagePicker();
  StreamSubscription<int>? _favoritePlacesSubscription;
  StreamSubscription<int>? _profileReviewsSubscription;
  StreamSubscription<int>? _plannedTripsSubscription;
  bool _isEditingProfile = false;
  String? _draftAvatarUrl;

  @override
  void initState() {
    super.initState();
    _favoritePlacesSubscription = getIt<FavoritePlacesSyncService>().changes
        .listen((_) {
          if (!mounted) return;
          context.read<ProfileCubit>().loadProfile(showLoader: false);
        });
    _profileReviewsSubscription = getIt<ProfileReviewsSyncService>().changes
        .listen((_) {
          if (!mounted) return;
          context.read<ProfileCubit>().loadProfile(showLoader: false);
        });
    _plannedTripsSubscription = getIt<PlannedTripsSyncService>().changes.listen(
      (_) {
        if (!mounted) return;
        context.read<ProfileCubit>().loadProfile(showLoader: false);
      },
    );
  }

  @override
  void dispose() {
    _favoritePlacesSubscription?.cancel();
    _profileReviewsSubscription?.cancel();
    _plannedTripsSubscription?.cancel();
    _usernameController.dispose();
    _usernameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<ProfileCubit, ProfileState>(
      listenWhen: (previous, current) =>
          previous.profile?.username != current.profile?.username ||
          previous.profile?.avatarUrl != current.profile?.avatarUrl,
      listener: (context, state) {
        final profile = state.profile;
        if (profile == null || _isEditingProfile) return;

        final username = profile.username;
        if (!_usernameFocusNode.hasFocus || _usernameController.text.isEmpty) {
          _usernameController.value = TextEditingValue(
            text: username,
            selection: TextSelection.collapsed(offset: username.length),
          );
        }
        setState(() => _draftAvatarUrl = profile.avatarUrl);
      },
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, state) {
              final profile = state.profile;

              if (state.status == ProfileStatus.loading && profile == null) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.status == ProfileStatus.error && profile == null) {
                return RefreshIndicator(
                  onRefresh: () => context.read<ProfileCubit>().loadProfile(),
                  child: _ProfileErrorState(
                    message:
                        state.errorMessage ?? 'Failed to load your profile.',
                  ),
                );
              }

              if (profile == null) {
                return const SizedBox.shrink();
              }

              return RefreshIndicator(
                onRefresh: () =>
                    context.read<ProfileCubit>().loadProfile(showLoader: false),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 94),
                  children: [
                    Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ProfileAvatar(
                            avatarUrl: _isEditingProfile
                                ? _draftAvatarUrl
                                : profile.avatarUrl,
                            size: 122,
                            canEdit:
                                _isEditingProfile &&
                                !state.isSavingAvatar &&
                                !state.isSavingUsername,
                            onTap: _handleAvatarTap,
                          ),
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: _ProfileAvatarEditButton(
                              isEditing: _isEditingProfile,
                              isSaving:
                                  state.isSavingAvatar ||
                                  state.isSavingUsername,
                              onPressed: () => _toggleEditMode(profile),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _usernameController,
                      focusNode: _usernameFocusNode,
                      textAlign: TextAlign.center,
                      textInputAction: TextInputAction.done,
                      readOnly: !_isEditingProfile || state.isSavingUsername,
                      onSubmitted: (_) => _usernameFocusNode.unfocus(),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Username',
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ProfileStatsLine(
                      profile: profile,
                      levelName: state.gamification?.level.title,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 18),
                    ProfileSectionButton(
                      title: 'Preferences',
                      subtitle:
                          '${profile.preferences.length} categories selected',
                      icon: Icons.tune_rounded,
                      onTap: () => _openPreferences(profile),
                    ),
                    const SizedBox(height: 10),
                    if (state.gamification != null) ...[
                      ProfileSectionButton(
                        title: 'Achievements',
                        subtitle: _achievementsSubtitle(state.gamification!),
                        icon: CupertinoIcons.rosette,
                        onTap: () => _openAchievements(state.gamification!),
                      ),
                      const SizedBox(height: 10),
                    ],
                    ProfileSectionButton(
                      title: 'Favourite Places',
                      subtitle:
                          '${profile.favoritePlacesCount} saved place${profile.favoritePlacesCount == 1 ? '' : 's'}',
                      icon: Icons.favorite_border_rounded,
                      onTap: () =>
                          _openManagementPage(() => FavoritePlacesPage()),
                    ),
                    const SizedBox(height: 10),
                    ProfileSectionButton(
                      title: 'Reviews',
                      subtitle:
                          '${profile.reviewsCount} review${profile.reviewsCount == 1 ? '' : 's'}',
                      icon: Icons.rate_review_outlined,
                      onTap: () =>
                          _openManagementPage(() => ProfileReviewsPage()),
                    ),
                    const SizedBox(height: 10),
                    ProfileSectionButton(
                      title: 'Planned Trips',
                      subtitle:
                          '${profile.plannedTripsCount} trip${profile.plannedTripsCount == 1 ? '' : 's'} planned',
                      icon: Icons.map_outlined,
                      onTap: () =>
                          _openManagementPage(() => PlannedTripsPage()),
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

  Future<void> _toggleEditMode(ProfileSummaryEntity profile) async {
    if (!_isEditingProfile) {
      setState(() {
        _isEditingProfile = true;
        _draftAvatarUrl = profile.avatarUrl;
        _usernameController.value = TextEditingValue(
          text: profile.username,
          selection: TextSelection.collapsed(offset: profile.username.length),
        );
      });
      return;
    }

    final trimmed = _usernameController.text.trim();
    if (trimmed.isEmpty) {
      AppSnackbar.show(
        context,
        message: 'Username cannot be empty.',
        type: SnackbarType.error,
      );
      return;
    }

    _usernameFocusNode.unfocus();

    final cubit = context.read<ProfileCubit>();
    String? error;
    if (trimmed != profile.username.trim()) {
      error = await cubit.updateUsername(trimmed);
    }

    if (!mounted) return;
    if (error == null && (_draftAvatarUrl ?? '') != (profile.avatarUrl ?? '')) {
      error = await cubit.updateAvatar(_draftAvatarUrl);
    }

    if (!mounted) return;

    if (error == null) {
      setState(() => _isEditingProfile = false);
    }

    AppSnackbar.show(
      context,
      message: error ?? 'Profile updated.',
      type: error == null ? SnackbarType.success : SnackbarType.error,
    );
  }

  Future<void> _handleAvatarTap() async {
    if (!_isEditingProfile) return;

    final shouldRemove = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.of(context).pop(false),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: const Text('Remove avatar'),
                onTap: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || shouldRemove == null) return;

    if (shouldRemove) {
      setState(() => _draftAvatarUrl = null);
      return;
    }

    XFile? pickedFile;
    try {
      pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 78,
      );
    } on PlatformException catch (error) {
      if (!mounted) return;

      final message = error.code == 'channel-error'
          ? 'Avatar picker is not ready yet. Please fully stop the app and run it again.'
          : 'Failed to open photo library. Please try again.';

      AppSnackbar.show(context, message: message, type: SnackbarType.error);
      return;
    } catch (_) {
      if (!mounted) return;

      AppSnackbar.show(
        context,
        message: 'Failed to open photo library. Please try again.',
        type: SnackbarType.error,
      );
      return;
    }

    if (pickedFile == null || !mounted) return;

    final bytes = await pickedFile.readAsBytes();
    if (!mounted) return;
    final mimeType = _mimeTypeForPath(pickedFile.path);
    final dataUri = 'data:$mimeType;base64,${base64Encode(bytes)}';

    setState(() => _draftAvatarUrl = dataUri);
  }

  Future<void> _openPreferences(ProfileSummaryEntity profile) async {
    final result = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => PreferencesPage(
          uid: profile.userId,
          replaceStackOnSave: false,
          showSkipAction: false,
          allowEmptySelection: true,
          initialSelectedCategoryIds: profile.preferences,
        ),
      ),
    );

    if (!mounted) return;
    if (result != null) {
      widget.onPreferencesUpdated?.call(result);
      AppSnackbar.show(
        context,
        message: 'Preferences updated.',
        type: SnackbarType.success,
      );
      await context.read<ProfileCubit>().loadProfile(showLoader: false);
    }
  }

  Future<void> _openAchievements(ProfileGamificationEntity gamification) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AchievementsPage(gamification: gamification),
      ),
    );
  }

  Future<void> _openManagementPage(Widget Function() createPage) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => createPage()));

    if (!mounted) return;
    await context.read<ProfileCubit>().loadProfile(showLoader: false);
  }

  String _mimeTypeForPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  String _achievementsSubtitle(ProfileGamificationEntity gamification) {
    final unlocked = gamification.badges
        .where((badge) => badge.isUnlocked)
        .length;
    final total = gamification.badges.length;
    return '$unlocked/$total unlocked';
  }
}

class _ProfileStatsLine extends StatelessWidget {
  final ProfileSummaryEntity profile;
  final String? levelName;
  final bool isDark;

  const _ProfileStatsLine({
    required this.profile,
    required this.levelName,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final level = levelName?.trim().isNotEmpty == true
        ? levelName!.trim()
        : 'New Explorer';

    return Text(
      '${profile.reviewsCount} review${profile.reviewsCount == 1 ? '' : 's'} · $level',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: isDark ? Colors.white60 : Colors.black54,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ProfileAvatarEditButton extends StatelessWidget {
  final bool isEditing;
  final bool isSaving;
  final VoidCallback onPressed;

  const _ProfileAvatarEditButton({
    required this.isEditing,
    required this.isSaving,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: isEditing ? 'Apply profile changes' : 'Edit profile',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isSaving ? null : onPressed,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? AppColors.appPrimaryBlack : Colors.white,
            border: Border.all(
              color: isDark ? Colors.white24 : Colors.black12,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.12),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: isSaving
              ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  isEditing ? CupertinoIcons.checkmark : CupertinoIcons.pencil,
                  size: 17,
                  color: isDark
                      ? AppColors.appPrimaryWhite
                      : AppColors.appPrimaryBlack,
                ),
        ),
      ),
    );
  }
}

class _ProfileErrorState extends StatelessWidget {
  final String message;

  const _ProfileErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return ScrollableTransientErrorPlaceholder(
      icon: Icons.person_off_outlined,
      title: 'Profile unavailable',
      message: message,
    );
  }
}
