import 'package:atlas/core/router/app_router.dart';
import 'package:atlas/core/utils/google_places_photo.dart';
import 'package:atlas/features/home/domain/entity/recommendation_entity.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

class RecommendationCard extends StatelessWidget {
  final RecommendationEntity recommendation;

  const RecommendationCard({super.key, required this.recommendation});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.router.push(
        PlaceDetailsRoute(
          placeId: recommendation.id,
          placeName: recommendation.name,
          city: recommendation.city,
          country: recommendation.country,
          photoReference: recommendation.photoReference,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: SizedBox(
          width: 360,
          height: 250,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (recommendation.photoReference != null)
                Image.network(
                  buildGooglePlacePhotoUrl(
                    recommendation.photoReference!,
                    maxWidthPx: 800,
                  ),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _photoPlaceholder(),
                )
              else
                _photoPlaceholder(),

              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.85),
                      ],
                      stops: const [0.0, 0.4, 0.7, 1.0],
                    ),
                  ),
                ),
              ),

              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      recommendation.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _locationLabel,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoPlaceholder() => Container(
    color: Colors.grey[300],
    child: const Center(
      child: Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
    ),
  );

  String get _locationLabel {
    final parts = [
      recommendation.city,
      recommendation.country,
    ].where((part) => part.trim().isNotEmpty).toList();

    return parts.isEmpty ? 'Atlas favourite' : parts.join(', ');
  }
}
