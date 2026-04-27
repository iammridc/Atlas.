import 'dart:math' as math;

import 'package:atlas/core/consts/app_colors.dart';
import 'package:atlas/core/router/app_router.dart';
import 'package:atlas/features/home/presentation/bloc/home_map_cubit.dart';
import 'package:atlas/features/home/presentation/bloc/home_map_state.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapSection extends StatefulWidget {
  const MapSection({super.key});

  @override
  State<MapSection> createState() => _MapSectionState();
}

class _MapSectionState extends State<MapSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<HomeMapCubit>().state;
      if (state.status == HomeMapStatus.initial) {
        context.read<HomeMapCubit>().loadCurrentLocation();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeMapCubit, HomeMapState>(
      builder: (context, state) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = math.min(
              360.0,
              math.max(0.0, constraints.maxWidth - 32),
            );

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CurrentPlaceText(state: state),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => context.router.push(const HomeMapRoute()),
                      child: SizedBox(
                        width: width,
                        height: 250,
                        child: _MapPreviewCard(state: state),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _CurrentPlaceText extends StatelessWidget {
  final HomeMapState state;

  const _CurrentPlaceText({required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final place = state.currentPlace;
    final locationLabel = place != null && place.hasLocationLabel
        ? place.label
        : state.isLoading
        ? '...'
        : 'your selected area';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "You're currently in",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        Text(
          locationLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }
}

class _MapPreviewCard extends StatelessWidget {
  final HomeMapState state;

  const _MapPreviewCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final location = state.currentLocation;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (location == null)
            _MapPreviewPlaceholder(isLoading: state.isLoading)
          else
            IgnorePointer(
              child: GoogleMap(
                key: ValueKey(
                  '${location.latitude.toStringAsFixed(5)},'
                  '${location.longitude.toStringAsFixed(5)}',
                ),
                initialCameraPosition: CameraPosition(
                  target: LatLng(location.latitude, location.longitude),
                  zoom: 15.8,
                ),
                zoomControlsEnabled: false,
                compassEnabled: false,
                mapToolbarEnabled: false,
                myLocationButtonEnabled: false,
                rotateGesturesEnabled: false,
                scrollGesturesEnabled: false,
                tiltGesturesEnabled: false,
                zoomGesturesEnabled: false,
              ),
            ),
          if (location != null) const Center(child: _CurrentLocationDot()),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.08),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(26),
              ),
            ),
          ),
          if (location == null && !state.isLoading)
            Center(
              child: Icon(
                CupertinoIcons.location_slash,
                color: AppColors.errorColor.withValues(alpha: 0.85),
                size: 42,
              ),
            ),
        ],
      ),
    );
  }
}

class _MapPreviewPlaceholder extends StatelessWidget {
  final bool isLoading;

  const _MapPreviewPlaceholder({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MapPreviewPainter(
        isDark: Theme.of(context).brightness == Brightness.dark,
      ),
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _CurrentLocationDot extends StatelessWidget {
  const _CurrentLocationDot();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.all(3),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF1A73E8),
          ),
          child: SizedBox(width: 15, height: 15),
        ),
      ),
    );
  }
}

class _MapPreviewPainter extends CustomPainter {
  final bool isDark;

  const _MapPreviewPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..color = isDark ? const Color(0xFF1F242C) : const Color(0xFFE9EAEE);
    canvas.drawRect(Offset.zero & size, background);

    final minorRoad = Paint()
      ..color = isDark ? const Color(0xFF343B45) : Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final park = Paint()
      ..color = isDark ? const Color(0xFF24352C) : const Color(0xFFD4EAD9);

    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.54, size.height * 0.18, 38, 30),
      park,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.18, size.height * 0.7, 44, 28),
      park,
    );

    for (final x in [0.18, 0.34, 0.5, 0.66, 0.82]) {
      canvas.drawLine(
        Offset(size.width * x, 0),
        Offset(size.width * (x - 0.08), size.height),
        minorRoad,
      );
    }
    for (final y in [0.18, 0.34, 0.5, 0.66, 0.82]) {
      canvas.drawLine(
        Offset(0, size.height * y),
        Offset(size.width, size.height * (y - 0.02)),
        minorRoad,
      );
    }

    _drawRoute(
      canvas,
      size,
      color: const Color(0xFF65C66F),
      width: 8,
      points: const [
        Offset(0.02, 0.14),
        Offset(0.24, 0.12),
        Offset(0.58, 0.15),
        Offset(0.78, 0.14),
        Offset(0.83, 0.36),
        Offset(0.79, 0.6),
        Offset(0.8, 0.95),
      ],
    );
    _drawRoute(
      canvas,
      size,
      color: const Color(0xFFE06F49),
      width: 6,
      points: const [
        Offset(0.1, 0.0),
        Offset(0.22, 0.16),
        Offset(0.6, 0.18),
        Offset(0.82, 0.17),
        Offset(0.87, 0.42),
        Offset(0.84, 0.64),
        Offset(0.92, 1),
      ],
    );
  }

  void _drawRoute(
    Canvas canvas,
    Size size, {
    required Color color,
    required double width,
    required List<Offset> points,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(points.first.dx * size.width, points.first.dy * size.height);

    for (final point in points.skip(1)) {
      path.lineTo(point.dx * size.width, point.dy * size.height);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MapPreviewPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}
