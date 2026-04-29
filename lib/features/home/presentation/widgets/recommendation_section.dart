import 'package:atlas/core/widgets/transient_error_placeholder.dart';
import 'package:atlas/features/home/domain/entity/recommendation_entity.dart';
import 'package:atlas/features/home/presentation/bloc/recommendation_cubit.dart';
import 'package:atlas/features/home/presentation/bloc/recommendations_state.dart';
import 'package:atlas/features/home/presentation/widgets/recommendation_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RecommendationsSection extends StatelessWidget {
  static const _loadMoreThreshold = 220.0;

  final List<RecommendationEntity> recommendations;
  final bool isLoadingMore;
  final bool hasError;
  final bool isReloading;

  const RecommendationsSection({
    super.key,
    required this.recommendations,
    this.isLoadingMore = false,
    this.hasError = false,
    this.isReloading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 4),
          child: Text(
            'Picked for you',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ),
        if (hasError)
          SizedBox(
            height: 250,
            child: isReloading
                ? Center(
                    child: CircularProgressIndicator(
                      color: isDark ? Colors.white38 : Colors.black38,
                      strokeWidth: 2,
                    ),
                  )
                : const TransientErrorPlaceholder(
                    icon: CupertinoIcons.square_grid_2x2,
                    title: 'Recommendations unavailable',
                    message: 'Pull down from the top to refresh.',
                  ),
          )
        else if (recommendations.isEmpty)
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
                  CupertinoIcons.sparkles,
                  size: 54,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                const SizedBox(height: 10),
                Text(
                  'No recommendations yet.',
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
              final cardWidth = (constraints.maxWidth - 48).clamp(0.0, 360.0);

              return SizedBox(
                height: 260,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) =>
                      _handleScrollNotification(context, notification),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: recommendations.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 24),
                    itemBuilder: (context, index) => RecommendationCard(
                      recommendation: recommendations[index],
                      width: cardWidth,
                    ),
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  bool _handleScrollNotification(
    BuildContext context,
    ScrollNotification notification,
  ) {
    if (notification.metrics.axis != Axis.horizontal) return false;

    final isRelevantScroll =
        notification is ScrollUpdateNotification ||
        notification is OverscrollNotification;
    if (!isRelevantScroll) return false;

    if (notification.metrics.extentAfter > _loadMoreThreshold) {
      return false;
    }

    final cubit = context.read<RecommendationsCubit>();
    final state = cubit.state;
    if (state is RecommendationsLoaded && !state.isLoadingMore) {
      cubit.loadMore();
    }

    return false;
  }
}
