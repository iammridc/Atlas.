import 'package:atlas/core/consts/app_colors.dart';
import 'package:atlas/features/place_details/domain/entities/place_review_entity.dart';
import 'package:atlas/features/place_details/presentation/bloc/place_details_cubit.dart';
import 'package:atlas/features/place_details/presentation/bloc/place_details_state.dart';
import 'package:atlas/features/place_details/presentation/widgets/place_review_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PlaceReviewsPage extends StatelessWidget {
  const PlaceReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: BlocBuilder<PlaceDetailsCubit, PlaceDetailsState>(
          builder: (context, state) {
            if (state is! PlaceDetailsLoaded) {
              return const Center(child: CircularProgressIndicator());
            }

            final reviews = state.allReviews;

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _Header(
                      title: state.place.name,
                      rating: state.place.rating,
                      totalReviewCount: state.totalReviewCount,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  sliver: SliverList.list(
                    children: [
                      _Section(
                        reviews: reviews,
                        emptyMessage:
                            'No reviews are available for this place yet.',
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final double? rating;
  final int totalReviewCount;

  const _Header({
    required this.title,
    required this.totalReviewCount,
    this.rating,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor = isDark ? Colors.white54 : Colors.black45;
    final emphasisColor = isDark
        ? AppColors.appPrimaryWhite
        : AppColors.appPrimaryBlack;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              CupertinoIcons.back,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            if (rating != null) ...[
              Icon(CupertinoIcons.star_fill, size: 18, color: emphasisColor),
              const SizedBox(width: 6),
              Text(
                rating!.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 12),
            ],
            Text(
              '$totalReviewCount reviews',
              style: TextStyle(color: secondaryColor),
            ),
          ],
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final List<PlaceReviewEntity> reviews;
  final String emptyMessage;

  const _Section({required this.reviews, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (reviews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              emptyMessage,
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black45,
                height: 1.45,
              ),
            ),
          )
        else
          Column(
            children: reviews
                .map(
                  (review) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PlaceReviewCard(review: review),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}
