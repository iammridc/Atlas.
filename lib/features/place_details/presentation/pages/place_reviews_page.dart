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
                  sliver: const SliverToBoxAdapter(child: _Header()),
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
  const _Header();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emphasisColor = isDark
        ? AppColors.appPrimaryWhite
        : AppColors.appPrimaryBlack;

    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const _HeaderIcon(CupertinoIcons.arrow_left),
            ),
          ),
          Text(
            'Reviews',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: emphasisColor,
              height: 1,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {},
              child: const _HeaderIcon(CupertinoIcons.add),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;

  const _HeaderIcon(this.icon);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark
        ? AppColors.appPrimaryWhite
        : AppColors.appPrimaryBlack;

    return SizedBox(
      width: 44,
      height: 44,
      child: Center(child: Icon(icon, color: iconColor, size: 32)),
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
