import 'dart:async';

import 'package:atlas/core/consts/app_colors.dart';
import 'package:atlas/core/injections/injections.dart';
import 'package:atlas/core/utils/app_snackbar.dart';
import 'package:atlas/core/utils/google_places_photo.dart';
import 'package:atlas/features/profile/domain/entities/planned_trip_entity.dart';
import 'package:atlas/features/profile/domain/repositories/profile_repository.dart';
import 'package:atlas/features/profile/domain/services/planned_trips_sync_service.dart';
import 'package:atlas/features/profile/presentation/pages/favorite_places_page.dart';
import 'package:atlas/features/profile/presentation/pages/planned_trip_details_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PlannedTripsPage extends StatefulWidget {
  const PlannedTripsPage({super.key});

  @override
  State<PlannedTripsPage> createState() => _PlannedTripsPageState();
}

class _PlannedTripsPageState extends State<PlannedTripsPage> {
  final _repository = getIt<ProfileRepository>();
  bool _isLoading = true;
  String? _errorMessage;
  List<PlannedTripEntity> _trips = const [];
  StreamSubscription<int>? _plannedTripsSubscription;

  @override
  void initState() {
    super.initState();
    _plannedTripsSubscription = getIt<PlannedTripsSyncService>().changes.listen(
      (_) => _loadTrips(showLoader: false),
    );
    _loadTrips();
  }

  @override
  void dispose() {
    _plannedTripsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadTrips({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      _errorMessage = null;
    }

    final result = await _repository.getPlannedTrips();
    if (!mounted) return;

    result.fold(
      (error) => setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      }),
      (trips) => setState(() {
        _isLoading = false;
        _trips = trips;
      }),
    );
  }

  Future<void> _openTripDetails(PlannedTripEntity trip) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlannedTripDetailsPage(
          trip: trip,
          onDelete: (trip) async {
            final deleted = await _deleteTrip(trip);
            if (deleted && mounted) Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  Future<bool> _deleteTrip(PlannedTripEntity trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete trip?'),
          content: Text('Remove "${trip.title}" from your planned trips?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return false;

    final result = await _repository.deletePlannedTrip(trip.id);
    if (!mounted) return false;

    return await result.fold<Future<bool>>(
      (error) async {
        AppSnackbar.show(
          context,
          message: error.message,
          type: SnackbarType.error,
        );
        return false;
      },
      (_) async {
        setState(() {
          _trips = _trips.where((item) => item.id != trip.id).toList();
        });
        AppSnackbar.show(
          context,
          message: 'Trip deleted.',
          type: SnackbarType.success,
        );
        getIt<PlannedTripsSyncService>().notifyChanged();
        return true;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Planned Trips')),
      body: RefreshIndicator(
        onRefresh: _loadTrips,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? ProfileCollectionErrorState(
                message: _errorMessage!,
                onRetry: _loadTrips,
              )
            : _trips.isEmpty
            ? const ProfileCollectionEmptyState(
                title: 'No trips planned yet',
                message:
                    'Save a route from the planner so it is ready when you need it.',
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                itemCount: _trips.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final trip = _trips[index];
                  return _PlannedTripCard(
                    trip: trip,
                    onTap: () => _openTripDetails(trip),
                  );
                },
              ),
      ),
    );
  }
}

class _PlannedTripCard extends StatelessWidget {
  final PlannedTripEntity trip;
  final VoidCallback onTap;

  const _PlannedTripCard({required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final photoReference = trip.destination?.photoReference?.trim();

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: SizedBox(
          height: 138,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (photoReference != null && photoReference.isNotEmpty)
                Image.network(
                  buildGooglePlacePhotoUrl(photoReference, maxWidthPx: 1200),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const _PlannedTripPlaceholder(),
                )
              else
                const _PlannedTripPlaceholder(),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.82),
                        Colors.black.withValues(alpha: 0.48),
                        Colors.black.withValues(alpha: 0.16),
                      ],
                      stops: const [0.0, 0.48, 1.0],
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
                      trip.title.isEmpty ? 'Saved route' : trip.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      trip.routeSummary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatProfileDate(trip.updatedAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.58),
                        fontSize: 12,
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
}

class _PlannedTripPlaceholder extends StatelessWidget {
  const _PlannedTripPlaceholder();

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
          CupertinoIcons.map,
          color: isDark
              ? Colors.white.withValues(alpha: 0.38)
              : Colors.black.withValues(alpha: 0.28),
          size: 30,
        ),
      ),
    );
  }
}
