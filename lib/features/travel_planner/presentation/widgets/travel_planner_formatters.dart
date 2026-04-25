import 'package:atlas/features/travel_planner/domain/entities/travel_route_entity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

IconData iconForTransport(TravelTransportType type) {
  return switch (type) {
    TravelTransportType.best => CupertinoIcons.arrow_turn_up_right,
    TravelTransportType.car => CupertinoIcons.car_detailed,
    TravelTransportType.bus => CupertinoIcons.bus,
    TravelTransportType.train => CupertinoIcons.tram_fill,
    TravelTransportType.flight => CupertinoIcons.airplane,
  };
}

IconData iconForLeg(TravelLegType type) {
  return switch (type) {
    TravelLegType.car => CupertinoIcons.car_detailed,
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
