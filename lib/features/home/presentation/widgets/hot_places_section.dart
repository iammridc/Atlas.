import 'package:atlas/core/localization/app_localizations.dart';
import 'package:atlas/core/widgets/fitted_single_line_text.dart';
import 'package:atlas/core/widgets/transient_error_placeholder.dart';
import 'package:atlas/features/home/presentation/bloc/hot_places_cubit.dart';
import 'package:atlas/features/home/presentation/bloc/hot_places_state.dart';
import 'package:atlas/features/home/presentation/widgets/recommendation_card.dart';
import 'package:atlas/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:atlas/features/profile/presentation/bloc/profile_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HotPlacesSection extends StatelessWidget {
  const HotPlacesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<HotPlacesCubit, HotPlacesState>(
      builder: (context, state) {
        final places = state is HotPlacesLoaded ? state.places : const [];
        final isLoading = state is HotPlacesLoading;
        final isError = state is HotPlacesError;
        final isReloading = state is HotPlacesError && state.isReloading;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BlocBuilder<ProfileCubit, ProfileState>(
              buildWhen: (previous, current) =>
                  previous.profile?.username != current.profile?.username,
              builder: (context, profileState) {
                final username = profileState.profile?.username.trim();
                if (username == null || username.isEmpty) {
                  return const SizedBox(height: 16);
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 2),
                  child: FittedSingleLineText(
                    context.l10n.named('welcomeUser', {'username': username}),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
              child: FittedSingleLineText(
                context.l10n.t('trendingToday'),
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            if (isLoading)
              const SizedBox(
                height: 260,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (isError)
              SizedBox(
                height: 250,
                child: isReloading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: isDark ? Colors.white38 : Colors.black38,
                          strokeWidth: 2,
                        ),
                      )
                    : TransientErrorPlaceholder(
                        icon: CupertinoIcons.flame,
                        title: context.l10n.t('hotPlacesUnavailable'),
                        message: context.l10n.t('pullToRefresh'),
                      ),
              )
            else if (places.isEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.flame,
                      size: 54,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      context.l10n.t('noCommunityFavourites'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth - 48).clamp(
                    0.0,
                    360.0,
                  );

                  return SizedBox(
                    height: 260,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: places.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 24),
                      itemBuilder: (context, index) => RecommendationCard(
                        recommendation: places[index],
                        width: cardWidth,
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
