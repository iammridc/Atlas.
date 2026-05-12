import 'dart:math';

import 'package:atlas/core/consts/app_colors.dart';
import 'package:atlas/core/injections/injections.dart';
import 'package:atlas/core/localization/app_localizations.dart';
import 'package:atlas/core/router/app_router.dart';
import 'package:atlas/core/utils/app_snackbar.dart';
import 'package:atlas/core/utils/google_places_photo.dart';
import 'package:atlas/core/widgets/transient_error_placeholder.dart';
import 'package:atlas/features/home/domain/entity/home_map_entity.dart';
import 'package:atlas/features/home/domain/entity/recommendation_entity.dart';
import 'package:atlas/features/home/presentation/bloc/home_map_cubit.dart';
import 'package:atlas/features/home/presentation/bloc/home_map_state.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

@RoutePage()
class HomeMapPage extends StatelessWidget {
  const HomeMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<HomeMapCubit>()..loadCurrentLocation(includeNearbyPlaces: true),
      child: const _HomeMapView(),
    );
  }
}

class _HomeMapView extends StatefulWidget {
  const _HomeMapView();

  @override
  State<_HomeMapView> createState() => _HomeMapViewState();
}

class _HomeMapViewState extends State<_HomeMapView> {
  GoogleMapController? _controller;
  LatLng? _cameraTarget;
  double _zoom = 15;
  double _bearing = 0;
  bool _is3dMode = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final previewBottomOffset = bottomInset > 0
        ? max(18.0, bottomInset - 6)
        : 14.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: BlocConsumer<HomeMapCubit, HomeMapState>(
        listenWhen: (previous, current) =>
            current.status == HomeMapStatus.error &&
            current.errorMessage != null &&
            previous.errorMessage != current.errorMessage,
        listener: (context, state) {
          AppSnackbar.show(
            context,
            message: state.errorMessage!,
            type: SnackbarType.error,
          );
        },
        builder: (context, state) {
          final currentLocation = state.currentLocation;

          if (currentLocation == null) {
            return RefreshIndicator(
              onRefresh: () => context.read<HomeMapCubit>().loadCurrentLocation(
                includeNearbyPlaces: true,
              ),
              child: _LocationGate(
                isLoading: state.isLoading,
                message: state.errorMessage,
              ),
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    currentLocation.latitude,
                    currentLocation.longitude,
                  ),
                  zoom: 15,
                ),
                onMapCreated: (controller) {
                  _controller = controller;
                  _cameraTarget = LatLng(
                    currentLocation.latitude,
                    currentLocation.longitude,
                  );
                },
                onCameraMove: (position) {
                  _cameraTarget = position.target;
                  _bearing = position.bearing;
                  setState(() => _zoom = position.zoom);
                },
                onCameraIdle: _resolveCameraCenter,
                onTap: (position) => _inspectMapPoint(context, position),
                markers: const {},
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
                buildingsEnabled: true,
                tiltGesturesEnabled: true,
                rotateGesturesEnabled: _is3dMode,
                gestureRecognizers: {
                  Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                },
              ),
              Positioned(
                top: topInset + 12,
                left: 24,
                child: _MapButton(
                  isDark: isDark,
                  icon: CupertinoIcons.chevron_left,
                  onPressed: () => context.router.maybePop(),
                  tooltip: context.l10n.t('back'),
                ),
              ),
              Positioned(
                top: topInset + 12,
                left: 78,
                right: 78,
                child: _MapLocationPill(
                  isDark: isDark,
                  label:
                      state.cameraPlace?.label ?? context.l10n.t('mapLocation'),
                ),
              ),
              Positioned(
                top: topInset + 12,
                right: 24,
                child: _MapControlColumn(
                  isDark: isDark,
                  is3dMode: _is3dMode,
                  onLocate: () => _focusCurrentLocation(currentLocation),
                  onZoomIn: _zoomIn,
                  onZoomOut: _zoomOut,
                  onToggleMode: () => _setMapMode(!_is3dMode),
                ),
              ),
              if (state.status == HomeMapStatus.inspectingPlace)
                Positioned(
                  left: 12,
                  bottom: previewBottomOffset,
                  child: _MapSurface(
                    isDark: isDark,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          context.l10n.t('loadingPlaceInfo'),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              if (state.selectedPlace case final place?)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: previewBottomOffset,
                  child: _PlacePreview(
                    place: place,
                    isDark: isDark,
                    onTap: () => _openPlaceDetails(context, place),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _focusCurrentLocation(HomeMapCoordinateEntity location) async {
    await _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(location.latitude, location.longitude),
        16,
      ),
    );
  }

  Future<void> _zoomIn() async {
    await _setZoom(_zoom + 1);
  }

  Future<void> _zoomOut() async {
    await _setZoom(_zoom - 1);
  }

  Future<void> _setZoom(double zoom) async {
    final nextZoom = zoom.clamp(3.0, 20.0).toDouble();
    setState(() => _zoom = nextZoom);
    await _controller?.animateCamera(CameraUpdate.zoomTo(nextZoom));
  }

  Future<void> _setMapMode(bool is3dMode) async {
    if (_is3dMode == is3dMode) return;

    final target = _cameraTarget;
    if (target == null) {
      setState(() => _is3dMode = is3dMode);
      return;
    }

    final nextZoom = is3dMode ? max(_zoom, 17.0) : _zoom;
    setState(() {
      _is3dMode = is3dMode;
      _zoom = nextZoom;
    });

    await _controller?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          zoom: nextZoom,
          tilt: is3dMode ? 60 : 0,
          bearing: is3dMode ? (_bearing == 0 ? 35 : _bearing) : 0,
        ),
      ),
    );
  }

  void _inspectMapPoint(BuildContext context, LatLng position) {
    context.read<HomeMapCubit>().inspectMapPoint(
      HomeMapCoordinateEntity(
        latitude: position.latitude,
        longitude: position.longitude,
      ),
    );
  }

  void _resolveCameraCenter() {
    final target = _cameraTarget;
    if (target == null) return;

    context.read<HomeMapCubit>().resolveCameraLocation(
      HomeMapCoordinateEntity(
        latitude: target.latitude,
        longitude: target.longitude,
      ),
    );
  }

  void _openPlaceDetails(BuildContext context, RecommendationEntity place) {
    context.router.push(
      PlaceDetailsRoute(
        placeId: place.id,
        placeName: place.name,
        city: place.city,
        country: place.country,
        photoReference: place.photoReference,
      ),
    );
  }
}

class _MapControlColumn extends StatelessWidget {
  final bool isDark;
  final bool is3dMode;
  final VoidCallback onLocate;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onToggleMode;

  const _MapControlColumn({
    required this.isDark,
    required this.is3dMode,
    required this.onLocate,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onToggleMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MapButton(
          isDark: isDark,
          icon: CupertinoIcons.location,
          onPressed: onLocate,
          tooltip: context.l10n.t('currentPosition'),
        ),
        const SizedBox(height: 10),
        _MapButton(
          isDark: isDark,
          icon: CupertinoIcons.plus,
          onPressed: onZoomIn,
          tooltip: context.l10n.t('closer'),
        ),
        const SizedBox(height: 10),
        _MapButton(
          isDark: isDark,
          icon: CupertinoIcons.minus,
          onPressed: onZoomOut,
          tooltip: context.l10n.t('farther'),
        ),
        const SizedBox(height: 10),
        _MapModeButton(
          isDark: isDark,
          label: is3dMode ? '2D' : '3D',
          onPressed: onToggleMode,
        ),
      ],
    );
  }
}

class _MapModeButton extends StatelessWidget {
  final bool isDark;
  final String label;
  final VoidCallback onPressed;

  const _MapModeButton({
    required this.isDark,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isDark
        ? AppColors.appPrimaryWhite
        : AppColors.appPrimaryBlack;

    return Tooltip(
      message: context.l10n.named('switchToMapMode', {'label': label}),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.appPrimaryBlack
                : AppColors.appPrimaryWhite,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _MapLocationPill extends StatelessWidget {
  final bool isDark;
  final String label;

  const _MapLocationPill({required this.isDark, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.appPrimaryBlack : AppColors.appPrimaryWhite,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isDark ? AppColors.appPrimaryWhite : AppColors.appPrimaryBlack,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _PlacePreview extends StatelessWidget {
  final RecommendationEntity place;
  final bool isDark;
  final VoidCallback onTap;

  const _PlacePreview({
    required this.place,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locationLabel = _locationLabel(context, place);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: _MapSurface(
        isDark: isDark,
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 70,
                height: 70,
                child: place.photoReference == null
                    ? const _PreviewPlaceholder()
                    : Image.network(
                        buildGooglePlacePhotoUrl(
                          place.photoReference!,
                          maxWidthPx: 300,
                        ),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const _PreviewPlaceholder(),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    place.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    locationLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.62)
                          : Colors.black.withValues(alpha: 0.58),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(CupertinoIcons.chevron_right),
          ],
        ),
      ),
    );
  }

  String _locationLabel(BuildContext context, RecommendationEntity place) {
    final parts = [
      place.city,
      place.country,
    ].where((part) => part.trim().isNotEmpty).toList();

    return parts.isEmpty ? context.l10n.t('nearbyPlace') : parts.join(', ');
  }
}

class _PreviewPlaceholder extends StatelessWidget {
  const _PreviewPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.08),
      child: const Icon(CupertinoIcons.photo),
    );
  }
}

class _MapButton extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  const _MapButton({
    required this.isDark,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.appPrimaryBlack
                : AppColors.appPrimaryWhite,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            size: 22,
            color: isDark
                ? AppColors.appPrimaryWhite
                : AppColors.appPrimaryBlack,
          ),
        ),
      ),
    );
  }
}

class _MapSurface extends StatelessWidget {
  final bool isDark;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _MapSurface({
    required this.isDark,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.74)
            : Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.26 : 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _LocationGate extends StatelessWidget {
  final bool isLoading;
  final String? message;

  const _LocationGate({required this.isLoading, required this.message});

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      return ScrollableTransientErrorPlaceholder(
        icon: CupertinoIcons.location_slash,
        title: context.l10n.t('locationUnavailable'),
        message: _localizedLocationMessage(context, message),
      );
    }

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                context.l10n.t('findingCurrentLocation'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _localizedLocationMessage(BuildContext context, String? message) {
  return switch (message) {
    'No place information found here.' => context.l10n.t('noPlaceInfoHere'),
    null => context.l10n.t('pullToTryAgain'),
    _ => message,
  };
}
