import 'package:atlas/core/consts/app_colors.dart';
import 'package:atlas/core/injections/injections.dart';
import 'package:atlas/core/router/app_router.dart';
import 'package:atlas/core/utils/google_places_photo.dart';
import 'package:atlas/features/profile/domain/entities/favorite_place_entity.dart';
import 'package:atlas/features/profile/domain/repositories/profile_repository.dart';
import 'package:atlas/features/profile/domain/services/favorite_places_sync_service.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class FavoritePlacesPage extends StatefulWidget {
  const FavoritePlacesPage({super.key});

  @override
  State<FavoritePlacesPage> createState() => _FavoritePlacesPageState();
}

class _FavoritePlacesPageState extends State<FavoritePlacesPage> {
  final _repository = getIt<ProfileRepository>();
  bool _isLoading = true;
  String? _errorMessage;
  List<FavoritePlaceEntity> _places = const [];
  StreamSubscription<int>? _favoritePlacesSubscription;

  @override
  void initState() {
    super.initState();
    _favoritePlacesSubscription = getIt<FavoritePlacesSyncService>().changes
        .listen((_) => _loadPlaces(showLoader: false));
    _loadPlaces();
  }

  @override
  void dispose() {
    _favoritePlacesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadPlaces({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      _errorMessage = null;
    }

    final result = await _repository.getFavoritePlaces();
    if (!mounted) return;

    result.fold(
      (error) => setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      }),
      (places) => setState(() {
        _isLoading = false;
        _places = places;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Favourite Places')),
      body: RefreshIndicator(
        onRefresh: _loadPlaces,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? ProfileCollectionErrorState(
                message: _errorMessage!,
                onRetry: _loadPlaces,
              )
            : _places.isEmpty
            ? const ProfileCollectionEmptyState(
                title: 'No favourite places yet',
                message:
                    'Save places you love from the place page, then revisit them here.',
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                itemCount: _places.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final place = _places[index];
                  return _FavoritePlaceCard(place: place);
                },
              ),
      ),
    );
  }
}

class _FavoritePlaceCard extends StatelessWidget {
  final FavoritePlaceEntity place;

  const _FavoritePlaceCard({required this.place});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.router.push(
        PlaceDetailsRoute(
          placeId: place.id,
          placeName: place.name,
          city: place.city,
          country: place.country,
          photoReference: place.photoReference,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: SizedBox(
          height: 118,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (place.photoReference != null &&
                  place.photoReference!.trim().isNotEmpty)
                Image.network(
                  buildGooglePlacePhotoUrl(
                    place.photoReference!,
                    maxWidthPx: 1200,
                  ),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const _FavoritePlacePlaceholder(),
                )
              else
                const _FavoritePlacePlaceholder(),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.78),
                        Colors.black.withValues(alpha: 0.44),
                        Colors.black.withValues(alpha: 0.12),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 18,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      place.name.isEmpty ? 'Unnamed place' : place.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _buildLocationLabel(place),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildLocationLabel(FavoritePlaceEntity place) {
    final parts = [
      place.city,
      place.country,
    ].map((part) => part.trim()).where((part) => part.isNotEmpty).toList();

    if (parts.isNotEmpty) {
      return parts.join(', ');
    }

    final fallback = place.location.trim();
    return fallback.isEmpty ? 'Explore this destination' : fallback;
  }
}

class _FavoritePlacePlaceholder extends StatelessWidget {
  const _FavoritePlacePlaceholder();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.08),
            isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.03),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          CupertinoIcons.photo,
          color: isDark
              ? Colors.white.withValues(alpha: 0.38)
              : Colors.black.withValues(alpha: 0.28),
          size: 30,
        ),
      ),
    );
  }
}

class ProfileManagementCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? body;
  final String trailing;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ProfileManagementCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
    required this.onDelete,
    this.body,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFF3F3F3),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    if (body != null && body!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        body!,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      trailing,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    onPressed: onTap,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileCollectionEmptyState extends StatelessWidget {
  final String title;
  final String message;

  const ProfileCollectionEmptyState({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 120, 28, 28),
          child: Column(
            children: [
              const Icon(Icons.inbox_outlined, size: 52),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white60
                      : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ProfileCollectionErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ProfileCollectionErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 120, 28, 28),
          child: Column(
            children: [
              const Icon(Icons.error_outline_rounded, size: 52),
              const SizedBox(height: 16),
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
      ],
    );
  }
}

String formatProfileDate(DateTime value) {
  final month = switch (value.month) {
    1 => 'Jan',
    2 => 'Feb',
    3 => 'Mar',
    4 => 'Apr',
    5 => 'May',
    6 => 'Jun',
    7 => 'Jul',
    8 => 'Aug',
    9 => 'Sep',
    10 => 'Oct',
    11 => 'Nov',
    _ => 'Dec',
  };
  return '$month ${value.day}, ${value.year}';
}
