import 'package:atlas/core/consts/app_colors.dart';
import 'package:atlas/core/utils/google_places_photo.dart';
import 'package:atlas/features/profile/domain/entities/planned_trip_entity.dart';
import 'package:atlas/features/travel_planner/domain/entities/travel_location_entity.dart';
import 'package:atlas/features/travel_planner/domain/entities/travel_route_entity.dart';
import 'package:atlas/features/travel_planner/presentation/widgets/travel_planner_formatters.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PlannedTripDetailsPage extends StatelessWidget {
  final PlannedTripEntity trip;
  final Future<void> Function(PlannedTripEntity trip) onDelete;

  const PlannedTripDetailsPage({
    super.key,
    required this.trip,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Saved route'),
        backgroundColor: backgroundColor,
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        child: SizedBox(
          height: 54,
          child: FilledButton(
            onPressed: () => onDelete(trip),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.errorColor,
              foregroundColor: AppColors.appPrimaryWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text(
              'Not interesting anymore',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
      body: trip.hasRouteSnapshot
          ? _RouteSnapshotView(trip: trip)
          : _TextOnlyTripView(trip: trip),
    );
  }
}

class _RouteSnapshotView extends StatelessWidget {
  final PlannedTripEntity trip;

  const _RouteSnapshotView({required this.trip});

  @override
  Widget build(BuildContext context) {
    final route = trip.route!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        _FixedLocationFields(
          origin: trip.origin!,
          destination: trip.destination!,
        ),
        const SizedBox(height: 22),
        _SavedRouteHeader(route: route),
        const SizedBox(height: 22),
        const Text(
          'Fixed route',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        ...route.legs.map((leg) => _RouteLegTile(leg: leg)),
        if (trip.selectedPointsOfInterest.isNotEmpty) ...[
          const SizedBox(height: 18),
          _SavedStopsSection(
            title: 'Chosen places',
            stops: trip.selectedPointsOfInterest,
          ),
        ],
        if (trip.selectedHotels.isNotEmpty) ...[
          const SizedBox(height: 18),
          _SavedStopsSection(
            title: 'Chosen hotels',
            stops: trip.selectedHotels,
          ),
        ],
      ],
    );
  }
}

class _FixedLocationFields extends StatelessWidget {
  final TravelLocationEntity origin;
  final TravelLocationEntity destination;

  const _FixedLocationFields({required this.origin, required this.destination});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark
        ? AppColors.appPrimaryWhite
        : AppColors.appPrimaryBlack;
    final secondary = isDark ? Colors.white38 : Colors.black38;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          children: [
            Icon(CupertinoIcons.circle, size: 22, color: primary),
            Container(
              width: 2,
              height: 34,
              margin: const EdgeInsets.symmetric(vertical: 3),
              decoration: BoxDecoration(
                color: secondary,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            Icon(CupertinoIcons.location_solid, color: AppColors.errorColor),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            children: [
              _FixedLocationInput(label: origin.displayAddress),
              const SizedBox(height: 10),
              _FixedLocationInput(label: destination.displayAddress),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Icon(CupertinoIcons.lock_fill, size: 22, color: secondary),
      ],
    );
  }
}

class _FixedLocationInput extends StatelessWidget {
  final String label;

  const _FixedLocationInput({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white70 : Colors.black54),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _SavedRouteHeader extends StatelessWidget {
  final TravelRouteEntity route;

  const _SavedRouteHeader({required this.route});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          iconForTransport(route.transportType),
          size: 34,
          color: isDark ? AppColors.appPrimaryWhite : AppColors.appPrimaryBlack,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                route.title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.04,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _InfoPill(label: route.durationLabel),
                  if (route.priceLabel != null)
                    _InfoPill(label: route.priceLabel!),
                  _InfoPill(
                    label: route.transferCount == 0
                        ? 'Direct'
                        : '${route.transferCount} transfers',
                  ),
                  if (route.isMocked) const _InfoPill(label: 'Mock flight'),
                  if (route.isEstimated) const _InfoPill(label: 'Estimated'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;

  const _InfoPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.black.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _RouteLegTile extends StatelessWidget {
  final TravelRouteLegEntity leg;

  const _RouteLegTile({required this.leg});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark ? Colors.white60 : Colors.black54;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(iconForLeg(leg.type), size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leg.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${leg.fromName} -> ${leg.toName}',
                  style: TextStyle(
                    color: secondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if ((leg.operatorName ?? '').isNotEmpty ||
                    (leg.lineName ?? '').isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    [leg.operatorName, leg.lineName]
                        .whereType<String>()
                        .where((value) => value.trim().isNotEmpty)
                        .join(' · '),
                    style: TextStyle(color: secondary, fontSize: 13),
                  ),
                ],
                if (leg.instructions.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _LegInstructions(text: leg.instructions, color: secondary),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            formatDuration(leg.duration),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _LegInstructions extends StatelessWidget {
  final String text;
  final Color color;

  const _LegInstructions({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final instructions = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: instructions
          .map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                line,
                style: TextStyle(color: color, fontSize: 13, height: 1.3),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SavedStopsSection extends StatelessWidget {
  final String title;
  final List<TravelStopEntity> stops;

  const _SavedStopsSection({required this.title, required this.stops});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 154,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: stops.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _SavedStopCard(stop: stops[index]),
          ),
        ),
      ],
    );
  }
}

class _SavedStopCard extends StatelessWidget {
  final TravelStopEntity stop;

  const _SavedStopCard({required this.stop});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 190,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.appPrimaryWhite : AppColors.appPrimaryBlack,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (stop.photoReference != null)
              Image.network(
                buildGooglePlacePhotoUrl(stop.photoReference!),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _PhotoPlaceholder(),
              )
            else
              const _PhotoPlaceholder(),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.02),
                      Colors.black.withValues(alpha: 0.42),
                      Colors.black.withValues(alpha: 0.78),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    stop.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      height: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stop.rating == null
                        ? stop.category
                        : '${stop.category} · ${stop.rating!.toStringAsFixed(1)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white12
          : Colors.black12,
      child: const Center(child: Icon(CupertinoIcons.photo, size: 30)),
    );
  }
}

class _TextOnlyTripView extends StatelessWidget {
  final PlannedTripEntity trip;

  const _TextOnlyTripView({required this.trip});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark ? Colors.white60 : Colors.black54;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        Text(
          trip.title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.04,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          trip.routeSummary,
          style: TextStyle(
            color: secondary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (trip.note.trim().isNotEmpty) ...[
          const SizedBox(height: 22),
          const Text(
            'Saved notes',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            trip.note,
            style: TextStyle(color: secondary, fontSize: 15, height: 1.4),
          ),
        ],
      ],
    );
  }
}
