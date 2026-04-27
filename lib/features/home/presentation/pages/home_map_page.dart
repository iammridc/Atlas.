import 'dart:math';

import 'package:atlas/core/consts/app_colors.dart';
import 'package:atlas/core/injections/injections.dart';
import 'package:atlas/core/router/app_router.dart';
import 'package:atlas/core/utils/app_snackbar.dart';
import 'package:atlas/core/utils/google_places_photo.dart';
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
            return _LocationGate(
              isLoading: state.isLoading,
              message: state.errorMessage,
              onRetry: () => context.read<HomeMapCubit>().loadCurrentLocation(
                includeNearbyPlaces: true,
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
                left: 12,
                right: 12,
                child: _MapTopBar(
                  isDark: isDark,
                  isLoading: state.isLoading,
                  onBack: () => context.router.maybePop(),
                  onLocate: () => _focusCurrentLocation(currentLocation),
                  onRefresh: () =>
                      context.read<HomeMapCubit>().loadNearbyPlaces(),
                ),
              ),
              Positioned(
                top: topInset + 78,
                right: 12,
                child: _ZoomControls(
                  isDark: isDark,
                  onZoomIn: _zoomIn,
                  onZoomOut: _zoomOut,
                ),
              ),
              Positioned(
                top: topInset + 190,
                right: 12,
                child: _MapModeSwitch(
                  isDark: isDark,
                  is3dMode: _is3dMode,
                  onChanged: _setMapMode,
                ),
              ),
              if (state.status == HomeMapStatus.inspectingPlace)
                Positioned(
                  left: 12,
                  bottom: bottomInset + 14,
                  child: _MapSurface(
                    isDark: isDark,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Loading place info...',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              if (state.selectedPlace case final place?)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: bottomInset + 14,
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

class _MapTopBar extends StatelessWidget {
  final bool isDark;
  final bool isLoading;
  final VoidCallback onBack;
  final VoidCallback onLocate;
  final VoidCallback onRefresh;

  const _MapTopBar({
    required this.isDark,
    required this.isLoading,
    required this.onBack,
    required this.onLocate,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MapButton(
          isDark: isDark,
          icon: CupertinoIcons.chevron_left,
          onPressed: onBack,
          tooltip: 'Back',
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MapSurface(
            isDark: isDark,
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.location_fill,
                  size: 17,
                  color: isDark ? Colors.white : AppColors.appPrimaryBlack,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Nearby map',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        _MapButton(
          isDark: isDark,
          icon: CupertinoIcons.location,
          onPressed: onLocate,
          tooltip: 'Locate me',
        ),
        const SizedBox(width: 10),
        _MapButton(
          isDark: isDark,
          icon: CupertinoIcons.arrow_clockwise,
          onPressed: onRefresh,
          tooltip: 'Refresh',
        ),
      ],
    );
  }
}

class _ZoomControls extends StatelessWidget {
  final bool isDark;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const _ZoomControls({
    required this.isDark,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MapButton(
          isDark: isDark,
          icon: CupertinoIcons.plus,
          onPressed: onZoomIn,
          tooltip: 'Zoom in',
        ),
        const SizedBox(height: 10),
        _MapButton(
          isDark: isDark,
          icon: CupertinoIcons.minus,
          onPressed: onZoomOut,
          tooltip: 'Zoom out',
        ),
      ],
    );
  }
}

class _MapModeSwitch extends StatelessWidget {
  final bool isDark;
  final bool is3dMode;
  final ValueChanged<bool> onChanged;

  const _MapModeSwitch({
    required this.isDark,
    required this.is3dMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _MapSurface(
      isDark: isDark,
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MapModeSegment(
            label: '2D',
            isSelected: !is3dMode,
            onTap: () => onChanged(false),
          ),
          _MapModeSegment(
            label: '3D',
            isSelected: is3dMode,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _MapModeSegment extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MapModeSegment({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A73E8) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : null,
            fontWeight: FontWeight.w900,
          ),
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
    final locationLabel = _locationLabel(place);

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
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
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

  String _locationLabel(RecommendationEntity place) {
    final parts = [
      place.city,
      place.country,
    ].where((part) => part.trim().isNotEmpty).toList();

    return parts.isEmpty ? 'Nearby place' : parts.join(', ');
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
    return _MapSurface(
      isDark: isDark,
      padding: EdgeInsets.zero,
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon, size: 20),
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
        borderRadius: BorderRadius.circular(8),
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
  final VoidCallback onRetry;

  const _LocationGate({
    required this.isLoading,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                const CircularProgressIndicator()
              else
                Icon(
                  CupertinoIcons.location_slash,
                  size: 54,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              const SizedBox(height: 16),
              Text(
                isLoading
                    ? 'Finding your current location...'
                    : message ?? 'Location is unavailable.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      ),
    );
  }
}
