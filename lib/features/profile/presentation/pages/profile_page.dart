import 'dart:convert';
import 'dart:async';

import 'package:atlas/core/consts/app_colors.dart';
import 'package:atlas/core/injections/injections.dart';
import 'package:atlas/core/utils/app_snackbar.dart';
import 'package:atlas/features/preferences/presentation/pages/preferences_page.dart';
import 'package:atlas/features/profile/domain/entities/profile_summary_entity.dart';
import 'package:atlas/features/profile/domain/services/favorite_places_sync_service.dart';
import 'package:atlas/features/profile/domain/services/profile_reviews_sync_service.dart';
import 'package:atlas/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:atlas/features/profile/presentation/bloc/profile_state.dart';
import 'package:atlas/features/profile/presentation/pages/favorite_places_page.dart';
import 'package:atlas/features/profile/presentation/pages/planned_trips_page.dart';
import 'package:atlas/features/profile/presentation/pages/profile_reviews_page.dart';
import 'package:atlas/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:atlas/features/profile/presentation/widgets/profile_section_button.dart';
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
  }

  @override
  void dispose() {
    _favoritePlacesSubscription?.cancel();
    _profileReviewsSubscription?.cancel();
    _usernameController.dispose();
    _usernameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<ProfileCubit, ProfileState>(
      listenWhen: (previous, current) =>
          previous.profile?.username != current.profile?.username,
      listener: (context, state) {
        final username = state.profile?.username;
        if (username == null) return;
        if (!_usernameFocusNode.hasFocus || _usernameController.text.isEmpty) {
          _usernameController.value = TextEditingValue(
            text: username,
            selection: TextSelection.collapsed(offset: username.length),
          );
        }
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
                return _ProfileErrorState(
                  message: state.errorMessage ?? 'Failed to load your profile.',
                  onRetry: () => context.read<ProfileCubit>().loadProfile(),
                );
              }

              if (profile == null) {
                return const SizedBox.shrink();
              }

              return RefreshIndicator(
                onRefresh: () =>
                    context.read<ProfileCubit>().loadProfile(showLoader: false),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 120),
                  children: [
                    Center(
                      child: ProfileAvatar(
                        avatarUrl: profile.avatarUrl,
                        size: 124,
                        isLoading: state.isSavingAvatar,
                        onTap: _handleAvatarTap,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _usernameController,
                      focusNode: _usernameFocusNode,
                      textAlign: TextAlign.center,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _saveUsername(),
                      decoration: InputDecoration(
                        hintText: 'Username',
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.05),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        'stats',
                        style: TextStyle(
                          fontSize: 18,
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: FilledButton(
                        onPressed: state.isSavingUsername
                            ? null
                            : _saveUsername,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        child: state.isSavingUsername
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save username'),
                      ),
                    ),
                    const SizedBox(height: 28),
                    ProfileSectionButton(
                      title: 'Preferences',
                      subtitle:
                          '${profile.preferences.length} categories selected',
                      icon: Icons.tune_rounded,
                      onTap: () => _openPreferences(profile),
                    ),
                    const SizedBox(height: 18),
                    ProfileSectionButton(
                      title: 'Favourite Places',
                      subtitle:
                          '${profile.favoritePlacesCount} saved place${profile.favoritePlacesCount == 1 ? '' : 's'}',
                      icon: Icons.favorite_border_rounded,
                      onTap: () =>
                          _openManagementPage(() => FavoritePlacesPage()),
                    ),
                    const SizedBox(height: 18),
                    ProfileSectionButton(
                      title: 'Reviews',
                      subtitle:
                          '${profile.reviewsCount} review${profile.reviewsCount == 1 ? '' : 's'}',
                      icon: Icons.rate_review_outlined,
                      onTap: () =>
                          _openManagementPage(() => ProfileReviewsPage()),
                    ),
                    const SizedBox(height: 18),
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

  Future<void> _saveUsername() async {
    final trimmed = _usernameController.text.trim();
    if (trimmed.isEmpty) {
      AppSnackbar.show(
        context,
        message: 'Username cannot be empty.',
        type: SnackbarType.error,
      );
      return;
    }

    final error = await context.read<ProfileCubit>().updateUsername(trimmed);
    if (!mounted) return;

    AppSnackbar.show(
      context,
      message: error ?? 'Username updated.',
      type: error == null ? SnackbarType.success : SnackbarType.error,
    );
  }

  Future<void> _handleAvatarTap() async {
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
      final error = await context.read<ProfileCubit>().updateAvatar(null);
      if (!mounted) return;
      AppSnackbar.show(
        context,
        message: error ?? 'Avatar removed.',
        type: error == null ? SnackbarType.success : SnackbarType.error,
      );
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

    final error = await context.read<ProfileCubit>().updateAvatar(dataUri);
    if (!mounted) return;

    AppSnackbar.show(
      context,
      message: error ?? 'Avatar updated.',
      type: error == null ? SnackbarType.success : SnackbarType.error,
    );
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
}

class _ProfileErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ProfileErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_off_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
