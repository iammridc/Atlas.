import 'dart:async';

import 'package:atlas/core/consts/app_colors.dart';
import 'package:atlas/core/injections/injections.dart';
import 'package:atlas/core/utils/app_snackbar.dart';
import 'package:atlas/core/utils/google_places_photo.dart';
import 'package:atlas/features/travel_planner/domain/entities/travel_location_entity.dart';
import 'package:atlas/features/travel_planner/domain/entities/travel_route_entity.dart';
import 'package:atlas/features/travel_planner/presentation/bloc/travel_planner_cubit.dart';
import 'package:atlas/features/travel_planner/presentation/bloc/travel_planner_state.dart';
import 'package:atlas/features/travel_planner/presentation/pages/travel_route_details_page.dart';
import 'package:atlas/features/travel_planner/presentation/widgets/travel_planner_formatters.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class TravelPlannerPage extends StatelessWidget {
  final String placeId;
  final String placeName;
  final String address;
  final String city;
  final String country;
  final double latitude;
  final double longitude;
  final String? photoReference;

  const TravelPlannerPage({
    super.key,
    required this.placeId,
    required this.placeName,
    required this.address,
    required this.city,
    required this.country,
    required this.latitude,
    required this.longitude,
    this.photoReference,
  });

  @override
  Widget build(BuildContext context) {
    final destination = TravelLocationEntity(
      id: placeId,
      name: placeName,
      address: address,
      city: city,
      country: country,
      latitude: latitude,
      longitude: longitude,
      photoReference: photoReference,
    );

    return BlocProvider(
      create: (_) =>
          getIt<TravelPlannerCubit>(param1: destination)..initialize(),
      child: const _TravelPlannerView(),
    );
  }
}

class _TravelPlannerView extends StatelessWidget {
  const _TravelPlannerView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;

    return BlocConsumer<TravelPlannerCubit, TravelPlannerState>(
      listenWhen: (previous, current) =>
          previous.actionStatus != current.actionStatus,
      listener: (context, state) {
        if (state.actionStatus == TravelPlannerActionStatus.saved) {
          AppSnackbar.show(
            context,
            message: state.actionMessage,
            type: SnackbarType.success,
          );
        } else if (state.actionStatus == TravelPlannerActionStatus.failed) {
          AppSnackbar.show(
            context,
            message: state.actionMessage,
            type: SnackbarType.error,
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea(
            top: false,
            bottom: false,
            child: RefreshIndicator(
              onRefresh: () => context.read<TravelPlannerCubit>().buildPlan(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                children: [
                  const _PlannerHeader(),
                  _LocationFields(state: state),
                  const SizedBox(height: 18),
                  if (state.isResolvingLocation)
                    const _InlineLoading(
                      label: 'Finding your current location...',
                    )
                  else if (state.origin == null)
                    _OriginMissingBlock(
                      onChoose: () => _showLocationSearch(
                        context,
                        title: 'Choose start point',
                        onSelected: context
                            .read<TravelPlannerCubit>()
                            .setOrigin,
                      ),
                    )
                  else if (state.isLoadingPlan)
                    const _InlineLoading(label: 'Building routes...')
                  else if (state.errorMessage.isNotEmpty)
                    _InlineError(
                      message: state.errorMessage,
                      onRetry: () =>
                          context.read<TravelPlannerCubit>().buildPlan(),
                    )
                  else ...[
                    _RoutesSection(state: state),
                    if (state.pointsOfInterest.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      _StopCarousel(
                        title: 'You can also visit',
                        stops: state.pointsOfInterest,
                        selectedIds: state.selectedPointIds,
                        onTap: context
                            .read<TravelPlannerCubit>()
                            .togglePointOfInterest,
                      ),
                    ],
                    if (state.hotels.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      _StopCarousel(
                        title: 'Hotels nearby',
                        stops: state.hotels,
                        selectedIds: state.selectedHotelIds,
                        onTap: context.read<TravelPlannerCubit>().toggleHotel,
                      ),
                    ],
                    const SizedBox(height: 18),
                    _StartJourneyButton(state: state),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showLocationSearch(
    BuildContext context, {
    required String title,
    required FutureOr<void> Function(TravelLocationEntity) onSelected,
  }) async {
    final cubit = context.read<TravelPlannerCubit>();
    final selectedLocation = await showModalBottomSheet<TravelLocationEntity>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _LocationSearchSheet(title: title),
      ),
    );

    if (selectedLocation != null && context.mounted) {
      await onSelected(selectedLocation);
    }
  }
}

class _PlannerHeader extends StatelessWidget {
  const _PlannerHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4,
        bottom: 2,
      ),
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            IconButton(
              onPressed: () => context.router.maybePop(),
              icon: const Icon(CupertinoIcons.arrow_uturn_left),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => context.router.maybePop(),
              icon: const Icon(CupertinoIcons.xmark),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationFields extends StatelessWidget {
  final TravelPlannerState state;

  const _LocationFields({required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          children: [
            Icon(
              CupertinoIcons.circle,
              size: 22,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
            Container(
              width: 2,
              height: 34,
              margin: const EdgeInsets.symmetric(vertical: 3),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white38
                    : Colors.black38,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const Icon(CupertinoIcons.location_solid, color: Colors.red),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            children: [
              _LocationInput(
                label: state.origin?.displayAddress ?? 'Choose start point',
                onTap: () => _showLocationSearch(
                  context,
                  title: 'Choose start point',
                  onSelected: context.read<TravelPlannerCubit>().setOrigin,
                ),
              ),
              const SizedBox(height: 10),
              _LocationInput(
                label: state.destination.displayAddress,
                onTap: () => _showLocationSearch(
                  context,
                  title: 'Choose destination',
                  onSelected: context.read<TravelPlannerCubit>().setDestination,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showLocationSearch(
    BuildContext context, {
    required String title,
    required FutureOr<void> Function(TravelLocationEntity) onSelected,
  }) async {
    final cubit = context.read<TravelPlannerCubit>();
    final selectedLocation = await showModalBottomSheet<TravelLocationEntity>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _LocationSearchSheet(title: title),
      ),
    );

    if (selectedLocation != null && context.mounted) {
      await onSelected(selectedLocation);
    }
  }
}

class _LocationInput extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LocationInput({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }
}

class _StartJourneyButton extends StatelessWidget {
  final TravelPlannerState state;

  const _StartJourneyButton({required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSaving = state.actionStatus == TravelPlannerActionStatus.saving;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: state.selectedRoute == null || isSaving
              ? null
              : () => context.read<TravelPlannerCubit>().saveSelectedTrip(),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark
                ? AppColors.appPrimaryWhite
                : AppColors.appPrimaryBlack,
            foregroundColor: isDark
                ? AppColors.appPrimaryBlack
                : AppColors.appPrimaryWhite,
            disabledBackgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
            elevation: 0,
          ),
          child: isSaving
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isDark
                        ? AppColors.appPrimaryBlack
                        : AppColors.appPrimaryWhite,
                  ),
                )
              : const Text(
                  'Start a Journey!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }
}

class _RoutesSection extends StatelessWidget {
  final TravelPlannerState state;

  const _RoutesSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final routes = state.routes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          routes.isEmpty ? 'No routes found' : 'Found ${routes.length} Ways',
          style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        if (routes.isEmpty)
          const _RoutesEmptyPlaceholder()
        else
          ...routes.map(
            (route) => _RouteCard(
              route: route,
              selected: route.id == state.selectedRouteId,
              onTap: () {
                context.read<TravelPlannerCubit>().selectRoute(route.id);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<TravelPlannerCubit>(),
                      child: TravelRouteDetailsPage(routeId: route.id),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _RoutesEmptyPlaceholder extends StatelessWidget {
  const _RoutesEmptyPlaceholder();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.exclamationmark_circle,
            size: 34,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          const SizedBox(height: 12),
          const Text(
            'No routes are available for these locations right now.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Try another start point, destination, or check API coverage later.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.35,
              color: isDark ? Colors.white60 : Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final TravelRouteEntity route;
  final bool selected;
  final VoidCallback onTap;

  const _RouteCard({
    required this.route,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? isDark
                      ? AppColors.appPrimaryWhite
                      : AppColors.appPrimaryBlack
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(iconForTransport(route.transportType), size: 34),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 19,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    route.summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (route.priceLabel != null || route.isMocked) ...[
                    const SizedBox(height: 7),
                    Text(
                      [
                        if (route.priceLabel != null) route.priceLabel!,
                        if (route.isMocked) 'mock flight',
                        if (route.isEstimated) 'estimated',
                      ].join(' · '),
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.black45,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              route.durationLabel,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _StopCarousel extends StatelessWidget {
  final String title;
  final List<TravelStopEntity> stops;
  final Set<String> selectedIds;
  final ValueChanged<String> onTap;

  const _StopCarousel({
    required this.title,
    required this.stops,
    required this.selectedIds,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (stops.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 154,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: stops.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final stop = stops[index];
              return _StopCard(
                stop: stop,
                selected: selectedIds.contains(stop.id),
                onTap: () => onTap(stop.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StopCard extends StatelessWidget {
  final TravelStopEntity stop;
  final bool selected;
  final VoidCallback onTap;

  const _StopCard({
    required this.stop,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedBorderColor = isDark
        ? AppColors.appPrimaryWhite
        : AppColors.appPrimaryBlack;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 190,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? selectedBorderColor : Colors.transparent,
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

class _InlineLoading extends StatelessWidget {
  final String label;

  const _InlineLoading({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InlineError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

class _OriginMissingBlock extends StatelessWidget {
  final VoidCallback onChoose;

  const _OriginMissingBlock({required this.onChoose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          const Text(
            'Atlas needs a start point to build Google routes.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onChoose, child: const Text('Choose origin')),
        ],
      ),
    );
  }
}

class _LocationSearchSheet extends StatefulWidget {
  final String title;

  const _LocationSearchSheet({required this.title});

  @override
  State<_LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<_LocationSearchSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  bool _isLoading = false;
  List<TravelLocationEntity> _results = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      setState(() => _results = const []);
      return;
    }

    setState(() => _isLoading = true);
    final results = await context.read<TravelPlannerCubit>().searchLocations(
      trimmedQuery,
    );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _results = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          18,
          18,
          MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Search city, airport, station, address...',
                prefixIcon: Icon(CupertinoIcons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(
                  const Duration(milliseconds: 350),
                  () => _search(value),
                );
              },
              onSubmitted: _search,
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(18),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final location = _results[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(CupertinoIcons.location),
                      title: Text(location.name),
                      subtitle: Text(
                        location.displayAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => Navigator.of(context).pop(location),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
