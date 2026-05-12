import 'package:atlas/core/consts/app_colors.dart';
import 'package:atlas/core/localization/app_localizations.dart';
import 'package:atlas/core/theme/app_theme.dart';
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

String formatDurationLocalized(BuildContext context, Duration duration) {
  final days = duration.inDays;
  final hours = duration.inHours.remainder(24);
  final minutes = duration.inMinutes.remainder(60);

  if (days > 0) {
    final dayLabel = context.l10n.t(days == 1 ? 'dayWord' : 'daysWord');
    final hoursPart = hours > 0 ? ' ${_hoursLabel(context, hours)}' : '';
    final minutesPart = minutes > 0
        ? ' ${_minutesLabel(context, minutes)}'
        : '';
    return '$days $dayLabel$hoursPart$minutesPart';
  }
  if (hours > 0) {
    final minutesPart = minutes > 0
        ? ' ${_minutesLabel(context, minutes)}'
        : '';
    return '${_hoursLabel(context, hours)}$minutesPart';
  }
  return _minutesLabel(context, minutes);
}

String _hoursLabel(BuildContext context, int hours) {
  final key = isRussianLocale(context)
      ? _russianHourLocalizationKey(hours)
      : hours == 1
      ? 'hourWord'
      : 'hoursWord';
  return '$hours ${context.l10n.t(key)}';
}

String _russianHourLocalizationKey(int hours) {
  final mod100 = hours % 100;
  if (mod100 >= 11 && mod100 <= 14) return 'hoursManyWord';

  return switch (hours % 10) {
    1 => 'hourWord',
    2 || 3 || 4 => 'hoursFewWord',
    _ => 'hoursManyWord',
  };
}

String _minutesLabel(BuildContext context, int minutes) {
  return '$minutes ${context.l10n.t('minutesWord')}';
}

String routeDurationLabel(BuildContext context, TravelRouteEntity route) {
  if (route.transportType != TravelTransportType.flight) {
    return formatDurationLocalized(context, route.duration);
  }

  TravelRouteLegEntity? flightLeg;
  for (final leg in route.legs) {
    if (leg.type == TravelLegType.flight) {
      flightLeg = leg;
      break;
    }
  }

  return formatDurationLocalized(
    context,
    flightLeg?.duration ?? route.duration,
  );
}

String routeTransferLabel(BuildContext context, TravelRouteEntity route) {
  if (route.transportType == TravelTransportType.flight) {
    return context.l10n.t('directRoute');
  }

  return route.transferCount == 0
      ? context.l10n.t('directRoute')
      : context.l10n.named(
          route.transferCount == 1 ? 'transferRoute' : 'transfersRoute',
          {'count': route.transferCount},
        );
}

String routeSummaryLabel(BuildContext context, TravelRouteEntity route) {
  if (route.transportType == TravelTransportType.flight) {
    return context.l10n.t('directFlight');
  }

  return switch (route.summary) {
    'Driving route' => context.l10n.t('routeCar'),
    'Bus route' => context.l10n.t('routeBus'),
    'Train route' => context.l10n.t('routeTrain'),
    'Flight route' => context.l10n.t('routeFlight'),
    'Recommended route' => context.l10n.t('routeBest'),
    'Public transport' => context.l10n.t('publicTransport'),
    _ => route.summary.replaceAll(' to ', ' → '),
  };
}

String routeTitleLabel(BuildContext context, TravelRouteEntity route) {
  final title = route.title;

  if (title.startsWith('Drive to ')) {
    return context.l10n.named('driveTo', {'place': title.substring(9)});
  }
  if (title.startsWith('Bus to ')) {
    return context.l10n.named('busTo', {'place': title.substring(7)});
  }
  if (title.startsWith('Train to ')) {
    return context.l10n.named('trainTo', {'place': title.substring(9)});
  }
  if (title.startsWith('Fly to ')) {
    return context.l10n.named('flyTo', {'place': title.substring(7)});
  }

  return title.replaceAll(' to ', ' → ');
}

String legTitleLabel(BuildContext context, TravelRouteLegEntity leg) {
  if (leg.type == TravelLegType.flight) {
    return context.l10n.t('directFlight');
  }

  return switch (leg.type) {
    TravelLegType.car => context.l10n.t('drive'),
    TravelLegType.walking => context.l10n.t('walk'),
    TravelLegType.bicycle => context.l10n.t('bike'),
    TravelLegType.flight => context.l10n.t('flight'),
    TravelLegType.bus => context.l10n.t('bus'),
    TravelLegType.train => context.l10n.t('train'),
    TravelLegType.subway => context.l10n.t('subway'),
    TravelLegType.tram => context.l10n.t('tram'),
    TravelLegType.transfer => context.l10n.t('transfer'),
  };
}

String legFromToLabel(BuildContext context, TravelRouteLegEntity leg) {
  return context.l10n.named('fromTo', {'from': leg.fromName, 'to': leg.toName});
}

String routePriceLabel(BuildContext context, String priceLabel) {
  const prefix = 'from ';
  if (!priceLabel.startsWith(prefix)) return priceLabel;
  return context.l10n.named('fromPrice', {
    'price': priceLabel.substring(prefix.length),
  });
}

String foundWaysLabel(BuildContext context, int count) {
  if (!isRussianLocale(context)) {
    return context.l10n.named(count == 1 ? 'foundOneWay' : 'foundWays', {
      'count': count,
    });
  }

  final mod100 = count % 100;
  final key = mod100 >= 11 && mod100 <= 14
      ? 'foundWays'
      : switch (count % 10) {
          1 => 'foundOneWay',
          2 || 3 || 4 => 'foundFewWays',
          _ => 'foundWays',
        };

  return context.l10n.named(key, {'count': count});
}

bool isRussianLocale(BuildContext context) {
  return Localizations.localeOf(context).languageCode == 'ru';
}

TextStyle plannerSectionTitleStyle(BuildContext context) {
  return const TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.08,
  );
}

TextStyle plannerRouteTitleStyle(BuildContext context) {
  return TextStyle(
    fontSize: isRussianLocale(context) ? 16 : 18,
    height: 1.14,
    fontWeight: FontWeight.bold,
  );
}

TextStyle plannerBodyTextStyle(BuildContext context) {
  return TextStyle(
    fontSize: isRussianLocale(context) ? 14 : 16,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );
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

TextStyle plannerPrimaryButtonTextStyle(BuildContext _) {
  return const TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontFamilyFallback: AppTheme.fontFamilyFallback,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
}

EdgeInsets plannerBottomButtonPadding(BuildContext context) {
  final bottomInset = MediaQuery.paddingOf(context).bottom;
  final bottomPadding = bottomInset > 15 ? bottomInset - 15 : 0.0;

  return EdgeInsets.fromLTRB(24, 0, 24, bottomPadding);
}
