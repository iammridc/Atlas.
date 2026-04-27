import 'package:atlas/core/consts/app_colors.dart';
import 'package:atlas/features/home/presentation/bloc/hot_places_cubit.dart';
import 'package:atlas/features/home/presentation/bloc/hot_places_state.dart';
import 'package:atlas/features/home/presentation/widgets/recommendation_card.dart';
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
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                "Today's hot picks",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            if (isLoading)
              const SizedBox(
                height: 260,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (isError)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: isReloading
                    ? null
                    : () => context.read<HotPlacesCubit>().reload(),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: isReloading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: isDark ? Colors.white38 : Colors.black38,
                            strokeWidth: 2,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.exclamationmark_circle,
                              size: 54,
                              color: AppColors.errorColor,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Hot places are unavailable.\nTap to retry.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                          ],
                        ),
                ),
              )
            else if (places.isEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
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
                      'No community favourites yet.',
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
              SizedBox(
                height: 260,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: places.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 24),
                  itemBuilder: (context, index) =>
                      RecommendationCard(recommendation: places[index]),
                ),
              ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
