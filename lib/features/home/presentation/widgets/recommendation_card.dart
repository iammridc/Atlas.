import 'package:atlas/features/home/domain/entity/recommendation_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RecommendationCard extends StatelessWidget {
  final RecommendationEntity recommendation;

  const RecommendationCard({super.key, required this.recommendation});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 250,
          height: 250,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (recommendation.photoReference != null)
                Image.network(
                  _buildPhotoUrl(recommendation.photoReference!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _photoPlaceholder(),
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
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.85),
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
                      '${recommendation.city}, ${recommendation.country}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
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

  String _buildPhotoUrl(String photoName) =>
      'https://places.googleapis.com/v1/$photoName/media'
      '?maxWidthPx=800&key=${dotenv.env['GOOGLE_API_KEY'] ?? ''}';

  Widget _photoPlaceholder() => Container(
    color: Colors.grey[300],
    child: const Center(
      child: Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
    ),
  );
}
