import 'package:atlas/core/consts/app_colors.dart';
import 'package:atlas/core/injections/injections.dart';
import 'package:atlas/core/router/app_router.dart';
import 'package:atlas/core/utils/app_snackbar.dart';
import 'package:atlas/core/widgets/transient_error_placeholder.dart';
import 'package:atlas/features/place_details/domain/entities/place_details_entity.dart';
import 'package:atlas/features/place_details/domain/entities/place_review_entity.dart';
import 'package:atlas/features/place_details/presentation/bloc/place_details_cubit.dart';
import 'package:atlas/features/place_details/presentation/bloc/place_details_state.dart';
import 'package:atlas/features/place_details/presentation/pages/place_reviews_page.dart';
import 'package:atlas/features/place_details/presentation/widgets/place_photo_gallery.dart';
import 'package:atlas/features/place_details/presentation/widgets/place_reviews_preview_block.dart';
import 'package:atlas/features/profile/presentation/pages/review_editor_page.dart';
import 'package:atlas/features/travel_planner/presentation/widgets/travel_planner_formatters.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class PlaceDetailsPage extends StatelessWidget {
  final String placeId;
  final String placeName;
  final String city;
  final String country;
  final String? photoReference;
  final bool openReviewsOnLoad;
  final bool openUserReviewOnLoad;

  const PlaceDetailsPage({
    super.key,
    required this.placeId,
    required this.placeName,
    required this.city,
    required this.country,
    this.photoReference,
    this.openReviewsOnLoad = false,
    this.openUserReviewOnLoad = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PlaceDetailsCubit>()
        ..loadPlace(
          placeId: placeId,
          placeName: placeName,
          city: city,
          country: country,
          photoReference: photoReference,
        ),
      child: _PlaceDetailsView(
        placeId: placeId,
        placeName: placeName,
        city: city,
        country: country,
        photoReference: photoReference,
        openReviewsOnLoad: openReviewsOnLoad,
        openUserReviewOnLoad: openUserReviewOnLoad,
      ),
    );
  }
}

class _PlaceDetailsView extends StatefulWidget {
  final String placeId;
  final String placeName;
  final String city;
  final String country;
  final String? photoReference;
  final bool openReviewsOnLoad;
  final bool openUserReviewOnLoad;

  const _PlaceDetailsView({
    required this.placeId,
    required this.placeName,
    required this.city,
    required this.country,
    this.photoReference,
    required this.openReviewsOnLoad,
    required this.openUserReviewOnLoad,
  });

  @override
  State<_PlaceDetailsView> createState() => _PlaceDetailsViewState();
}

class _PlaceDetailsViewState extends State<_PlaceDetailsView> {
  bool _didOpenReviews = false;
  bool _didOpenUserReview = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final topInset = MediaQuery.of(context).padding.top;
    Future<void> reloadPlace() => context.read<PlaceDetailsCubit>().loadPlace(
      placeId: widget.placeId,
      placeName: widget.placeName,
      city: widget.city,
      country: widget.country,
      photoReference: widget.photoReference,
    );

    return Scaffold(
      backgroundColor: pageColor,
      body: BlocBuilder<PlaceDetailsCubit, PlaceDetailsState>(
        builder: (context, state) {
          if (state is PlaceDetailsLoading || state is PlaceDetailsInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PlaceDetailsError) {
            return SafeArea(
              child: RefreshIndicator(
                onRefresh: reloadPlace,
                child: _ErrorView(message: state.message),
              ),
            );
          }

          final loadedState = state as PlaceDetailsLoaded;
          final place = loadedState.place;
          final previewReviews = _buildPreviewReviews(
            place.googleReviews,
            loadedState.communityReviews,
          );
          _openUserReviewAfterFirstLoadIfNeeded(loadedState);
          _openReviewsAfterFirstLoadIfNeeded();

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: reloadPlace,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _HeroSection(
                        photoNames: place.photoNames,
                        topInset: topInset,
                        onBackPressed: () => context.router.maybePop(),
                        isFavorite: loadedState.isFavorite,
                        isSavingFavorite: loadedState.isSavingFavorite,
                        onFavoritePressed: () async {
                          final result = await context
                              .read<PlaceDetailsCubit>()
                              .toggleFavoritePlace();
                          if (!context.mounted ||
                              result.status !=
                                  PlaceFavoriteActionStatus.failed) {
                            return;
                          }

                          AppSnackbar.show(
                            context,
                            message: result.message,
                            type: SnackbarType.error,
                          );
                        },
                      ),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _DetailsSheet(
                        place: place,
                        previewReviews: previewReviews,
                        totalReviewCount: loadedState.totalReviewCount,
                        onReviewsTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: context.read<PlaceDetailsCubit>(),
                              child: PlaceReviewsPage(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: plannerBottomButtonPadding(context),
                  child: SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => _openTravelPlanner(context, place),
                      style: plannerPrimaryButtonStyle(isDark),
                      child: const Text('Start a Journey!'),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<PlaceReviewEntity> _buildPreviewReviews(
    List<PlaceReviewEntity> googleReviews,
    List<PlaceReviewEntity> communityReviews,
  ) {
    if (communityReviews.isNotEmpty) {
      return [communityReviews.first];
    }
    if (googleReviews.isNotEmpty) {
      return [googleReviews.first];
    }
    return const [];
  }

  void _openTravelPlanner(BuildContext context, PlaceDetailsEntity place) {
    context.router.push(
      TravelPlannerRoute(
        placeId: place.id,
        placeName: place.name,
        address: place.formattedAddress,
        city: place.city,
        country: place.country,
        latitude: place.latitude,
        longitude: place.longitude,
        photoReference: place.photoNames.isEmpty
            ? null
            : place.photoNames.first,
      ),
    );
  }

  void _openReviewsAfterFirstLoadIfNeeded() {
    if (!widget.openReviewsOnLoad ||
        widget.openUserReviewOnLoad ||
        _didOpenReviews) {
      return;
    }
    _didOpenReviews = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<PlaceDetailsCubit>(),
            child: PlaceReviewsPage(),
          ),
        ),
      );
    });
  }

  void _openUserReviewAfterFirstLoadIfNeeded(PlaceDetailsLoaded state) {
    if (!widget.openUserReviewOnLoad || _didOpenUserReview) return;
    _didOpenUserReview = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _showCurrentUserReviewEditor(state);
    });
  }

  Future<void> _showCurrentUserReviewEditor(PlaceDetailsLoaded state) async {
    final cubit = context.read<PlaceDetailsCubit>();
    final existingReview = state.currentUserReview;
    final result = await Navigator.of(context).push<ReviewEditorResult>(
      MaterialPageRoute(
        builder: (_) => ReviewEditorPage(
          title: existingReview == null ? 'Add review' : 'Edit review',
          initialPlaceName: state.place.name,
          allowPlaceNameEditing: false,
          initialRating: existingReview?.rating.round() ?? 4,
          initialText: existingReview?.text ?? '',
          initialPhotoDataUrls: existingReview?.photoDataUrls ?? const [],
          placeSubtitle: [
            state.place.city,
            state.place.country,
          ].where((part) => part.trim().isNotEmpty).join(', '),
          photoReference: state.place.photoNames.isEmpty
              ? null
              : state.place.photoNames.first,
        ),
      ),
    );

    if (result == null || !mounted) return;

    final error = await cubit.saveCurrentUserReview(
      rating: result.rating.toDouble(),
      text: result.text,
      photoDataUrls: result.photoDataUrls,
    );
    if (!mounted) return;

    if (error != null) {
      AppSnackbar.show(context, message: error, type: SnackbarType.error);
      return;
    }

    await cubit.refreshReviews();
    if (!mounted) return;

    AppSnackbar.show(
      context,
      message: existingReview == null ? 'Review added.' : 'Review updated.',
      type: SnackbarType.success,
    );
  }
}

class _HeroSection extends StatelessWidget {
  final List<String> photoNames;
  final double topInset;
  final VoidCallback onBackPressed;
  final VoidCallback onFavoritePressed;
  final bool isFavorite;
  final bool isSavingFavorite;

  const _HeroSection({
    required this.photoNames,
    required this.topInset,
    required this.onBackPressed,
    required this.onFavoritePressed,
    required this.isFavorite,
    required this.isSavingFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PlacePhotoGallery(photoNames: photoNames, height: 320),
        Positioned(
          top: topInset + 16,
          left: 12,
          child: GestureDetector(
            onTap: onBackPressed,
            child: const _HeroIcon(CupertinoIcons.chevron_left),
          ),
        ),
        Positioned(
          top: topInset + 16,
          right: 16,
          child: GestureDetector(
            onTap: isSavingFavorite ? null : onFavoritePressed,
            child: _HeroIcon(
              isFavorite ? CupertinoIcons.star_fill : CupertinoIcons.star,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroIcon extends StatelessWidget {
  final IconData icon;

  const _HeroIcon(this.icon);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? AppColors.appPrimaryBlack : AppColors.appPrimaryWhite,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        color: isDark ? AppColors.appPrimaryWhite : AppColors.appPrimaryBlack,
        size: 22,
      ),
    );
  }
}

class _DetailsSheet extends StatelessWidget {
  final PlaceDetailsEntity place;
  final List<PlaceReviewEntity> previewReviews;
  final int totalReviewCount;
  final VoidCallback onReviewsTap;

  const _DetailsSheet({
    required this.place,
    required this.previewReviews,
    required this.totalReviewCount,
    required this.onReviewsTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final description = _buildDescription(place);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      decoration: BoxDecoration(
        color: sheetColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.08),
            blurRadius: 28,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TitleBlock(place: place),
          const SizedBox(height: 12),
          _TagWrap(tags: _buildTags(place), isDark: isDark),
          const SizedBox(height: 12),
          _ExpandableDescription(text: description),
          const SizedBox(height: 10),
          PlaceReviewsPreviewBlock(
            previewReviews: previewReviews,
            rating: place.rating,
            totalReviewCount: totalReviewCount,
            onTap: onReviewsTap,
          ),
        ],
      ),
    );
  }

  String _buildDescription(PlaceDetailsEntity place) {
    final rawDescription = place.description?.trim();
    if (rawDescription != null && rawDescription.isNotEmpty) {
      return rawDescription;
    }

    final location = [
      if (place.city.isNotEmpty) place.city,
      if (place.country.isNotEmpty) place.country,
    ].join(', ');

    if (location.isEmpty) {
      return '${place.name} is waiting to be explored. Detailed editorial description is not available for this place yet.';
    }

    return '${place.name} is located in $location. Detailed editorial description is not available for this place yet, but you can still explore photos and reviews before planning your visit.';
  }

  List<_PlaceTagData> _buildTags(PlaceDetailsEntity place) {
    final tags = <_PlaceTagData>[
      ...place.categories.take(3).map(_PlaceTagData.neutral),
    ];

    if ((place.rating ?? 0) >= 4.5 && place.userRatingCount >= 500) {
      tags.add(
        const _PlaceTagData.highlighted(
          'Must See',
          icon: CupertinoIcons.star_fill,
        ),
      );
    } else if (place.userRatingCount >= 500) {
      tags.add(const _PlaceTagData.highlighted('Popular'));
    }

    if (tags.isEmpty) {
      tags.add(const _PlaceTagData.neutral('Recommended'));
    }

    return tags.take(4).toList();
  }
}

class _TitleBlock extends StatelessWidget {
  final PlaceDetailsEntity place;

  const _TitleBlock({required this.place});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor = isDark ? Colors.white38 : Colors.black45;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          place.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            height: 1.08,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          place.formattedAddress,
          style: TextStyle(
            fontSize: 15,
            color: secondaryColor,
            fontWeight: FontWeight.w400,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _TagWrap extends StatelessWidget {
  final List<_PlaceTagData> tags;
  final bool isDark;

  const _TagWrap({required this.tags, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: tags
          .map(
            (tag) => _TagChip(
              label: tag.label,
              isDark: isDark,
              highlighted: tag.highlighted,
              icon: tag.icon,
            ),
          )
          .toList(),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final bool isDark;
  final bool highlighted;
  final IconData? icon;

  const _TagChip({
    required this.label,
    required this.isDark,
    required this.highlighted,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = highlighted
        ? (isDark
              ? Colors.white.withValues(alpha: 0.16)
              : Colors.black.withValues(alpha: 0.1))
        : (isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08));
    final foregroundColor = highlighted
        ? (isDark ? AppColors.appPrimaryWhite : AppColors.appPrimaryBlack)
        : (isDark ? Colors.white : Colors.black87);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foregroundColor),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableDescription extends StatefulWidget {
  final String text;

  const _ExpandableDescription({required this.text});

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shouldCollapse = widget.text.trim().length > 180;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          maxLines: !_expanded && shouldCollapse ? 4 : null,
          overflow: !_expanded && shouldCollapse
              ? TextOverflow.ellipsis
              : TextOverflow.visible,
          style: TextStyle(
            fontSize: 16,
            height: 1.45,
            color: isDark
                ? AppColors.appPrimaryWhite
                : AppColors.appPrimaryBlack,
          ),
        ),
        if (shouldCollapse) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded ? 'Show Less' : 'Read More',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white38 : Colors.black45,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PlaceTagData {
  final String label;
  final bool highlighted;
  final IconData? icon;

  const _PlaceTagData._(this.label, this.highlighted, this.icon);

  const _PlaceTagData.neutral(String label) : this._(label, false, null);

  const _PlaceTagData.highlighted(String label, {IconData? icon})
    : this._(label, true, icon);
}

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: [
          SizedBox(
            height: constraints.maxHeight,
            child: Stack(
              children: [
                Positioned(
                  top: 20,
                  left: 20,
                  child: GestureDetector(
                    onTap: () => context.router.maybePop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.appPrimaryBlack
                            : AppColors.appPrimaryWhite,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                      ),
                      child: Icon(
                        CupertinoIcons.back,
                        color: isDark
                            ? AppColors.appPrimaryWhite
                            : AppColors.appPrimaryBlack,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                TransientErrorPlaceholder(
                  icon: Icons.wrong_location_outlined,
                  title: 'Place unavailable',
                  message: message,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
