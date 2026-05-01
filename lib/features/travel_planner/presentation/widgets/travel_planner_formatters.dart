import 'package:atlas/core/consts/app_colors.dart';
import 'package:atlas/features/travel_planner/domain/entities/travel_route_entity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

IconData iconForTransport(TravelTransportType type) {
  return switch (type) {
    TravelTransportType.best => CupertinoIcons.arrow_turn_up_right,
    TravelTransportType.car => CupertinoIcons.car,
    TravelTransportType.bus => CupertinoIcons.bus,
    TravelTransportType.train => CupertinoIcons.tram_fill,
    TravelTransportType.flight => CupertinoIcons.airplane,
  };
}

IconData iconForLeg(TravelLegType type) {
  return switch (type) {
    TravelLegType.car => CupertinoIcons.car,
    TravelLegType.bus => CupertinoIcons.bus,
    TravelLegType.train => CupertinoIcons.tram_fill,
    TravelLegType.subway => CupertinoIcons.tram_fill,
    TravelLegType.tram => CupertinoIcons.tram_fill,
    TravelLegType.walking => Icons.directions_walk_rounded,
    TravelLegType.bicycle => Icons.pedal_bike_rounded,
    TravelLegType.flight => CupertinoIcons.airplane,
    TravelLegType.transfer => CupertinoIcons.arrow_right,
  };
}

String formatDuration(Duration duration) {
  final days = duration.inDays;
  final hours = duration.inHours.remainder(24);
  final minutes = duration.inMinutes.remainder(60);

  if (days > 0) {
    return hours > 0 ? '${days}d ${hours}h' : '${days}d';
  }
  if (hours > 0) {
    return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
  }
  return '${minutes}m';
}

String routeDurationLabel(TravelRouteEntity route) {
  if (route.transportType != TravelTransportType.flight) {
    return route.durationLabel;
  }

  TravelRouteLegEntity? flightLeg;
  for (final leg in route.legs) {
    if (leg.type == TravelLegType.flight) {
      flightLeg = leg;
      break;
    }
  }

  return formatDuration(flightLeg?.duration ?? route.duration);
}

String routeTransferLabel(TravelRouteEntity route) {
  if (route.transportType == TravelTransportType.flight) {
    return 'Direct';
  }

  return route.transferCount == 0
      ? 'Direct'
      : '${route.transferCount} transfers';
}

String routeSummaryLabel(TravelRouteEntity route) {
  if (route.transportType == TravelTransportType.flight) {
    return 'Direct flight';
  }

  return route.summary;
}

String legTitleLabel(TravelRouteLegEntity leg) {
  if (leg.type == TravelLegType.flight) {
    return 'Direct flight';
  }

  return leg.title;
}

ButtonStyle plannerPrimaryButtonStyle(bool isDark) {
  return ElevatedButton.styleFrom(
    backgroundColor: isDark
        ? AppColors.appPrimaryWhite
        : AppColors.appPrimaryBlack,
    foregroundColor: isDark
        ? AppColors.appPrimaryBlack
        : AppColors.appPrimaryWhite,
    disabledBackgroundColor: isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08),
    disabledForegroundColor: isDark ? Colors.white38 : Colors.black38,
    elevation: 0,
    minimumSize: const Size.fromHeight(54),
    side: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
    textStyle: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.2,
    ),
  );
}

EdgeInsets plannerBottomButtonPadding(BuildContext context) {
  final bottomInset = MediaQuery.paddingOf(context).bottom;
  final bottomPadding = bottomInset > 15 ? bottomInset - 15 : 0.0;

  return EdgeInsets.fromLTRB(24, 0, 24, bottomPadding);
}
