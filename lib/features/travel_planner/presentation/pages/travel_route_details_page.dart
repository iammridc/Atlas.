import 'package:atlas/core/consts/app_colors.dart';
import 'package:atlas/core/utils/app_snackbar.dart';
import 'package:atlas/features/travel_planner/domain/entities/travel_route_entity.dart';
import 'package:atlas/features/travel_planner/presentation/bloc/travel_planner_cubit.dart';
import 'package:atlas/features/travel_planner/presentation/bloc/travel_planner_state.dart';
import 'package:atlas/features/travel_planner/presentation/widgets/travel_planner_formatters.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TravelRouteDetailsPage extends StatelessWidget {
  final String routeId;

  const TravelRouteDetailsPage({super.key, required this.routeId});

  @override
  Widget build(BuildContext context) {
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
        }
        if (state.actionStatus == TravelPlannerActionStatus.failed) {
          AppSnackbar.show(
            context,
            message: state.actionMessage,
            type: SnackbarType.error,
          );
        }
      },
      builder: (context, state) {
        final route = state.routes.firstWhere(
          (route) => route.id == routeId,
          orElse: () => state.selectedRoute!,
        );
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final backgroundColor = isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight;

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            title: const Text('Route details'),
            backgroundColor: backgroundColor,
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(18, 10, 18, 18),
            child: SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed:
                    state.actionStatus == TravelPlannerActionStatus.saving
                    ? null
                    : () =>
                          context.read<TravelPlannerCubit>().saveSelectedTrip(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? AppColors.appPrimaryWhite
                      : AppColors.appPrimaryBlack,
                  foregroundColor: isDark
                      ? AppColors.appPrimaryBlack
                      : AppColors.appPrimaryWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: state.actionStatus == TravelPlannerActionStatus.saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Add to Planned Trips',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    iconForTransport(route.transportType),
                    size: 34,
                    color: isDark ? Colors.white : Colors.black,
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
                            if (route.isMocked)
                              const _InfoPill(label: 'Mock flight'),
                            if (route.isEstimated)
                              const _InfoPill(label: 'Estimated'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'Itinerary',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              ...route.legs.map((leg) => _RouteLegTile(leg: leg)),
              if (state.selectedPointsOfInterest.isNotEmpty) ...[
                const SizedBox(height: 18),
                _SelectedStopsBlock(
                  title: 'Added places',
                  stops: state.selectedPointsOfInterest,
                ),
              ],
              if (state.selectedHotels.isNotEmpty) ...[
                const SizedBox(height: 18),
                _SelectedStopsBlock(
                  title: 'Added hotels',
                  stops: state.selectedHotels,
                ),
              ],
            ],
          ),
        );
      },
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

    if (instructions.length <= 1) {
      return Text(text, style: TextStyle(color: color, fontSize: 13));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Details',
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        ...instructions.map(
          (instruction) => Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              instruction,
              style: TextStyle(color: color, fontSize: 13, height: 1.3),
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectedStopsBlock extends StatelessWidget {
  final String title;
  final List<TravelStopEntity> stops;

  const _SelectedStopsBlock({required this.title, required this.stops});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        ...stops.map(
          (stop) => Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              children: [
                const Icon(CupertinoIcons.check_mark_circled_solid, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stop.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
