import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:evio_core/evio_core.dart';
import '../../../widgets/cached_event_image.dart';

class FeaturedCarousel extends StatelessWidget {
  final List<Event> events;

  const FeaturedCarousel({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Destacados',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 16),

        // Carousel
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 20),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return _FeaturedCard(event: event);
            },
          ),
        ),
      ],
    );
  }
}

class _FeaturedCard extends ConsumerWidget {
  final Event event;

  const _FeaturedCard({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/event/${event.id}'),
      child: Container(
        width: 150,
        margin: EdgeInsets.only(right: 12),
        child: Stack(
          children: [
            // ✅ HERO: Imagen con tag único
            Hero(
              tag: 'event-image-${event.id}',
              child: CachedEventImage(
                imageUrl: event.imageUrl,
                thumbnailUrl: event.thumbnailUrl,
                fullImageUrl: event.fullImageUrl,
                useThumbnail: true,
                width: 150,
                height: 200,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(12),
                memCacheWidth: 300,
              ),
            ),

            // Gradiente oscuro abajo
            Hero(
              tag: 'event-gradient-${event.id}',
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    stops: [0.5, 1.0],
                  ),
                ),
              ),
            ),

            // Texto superpuesto
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.mainArtist,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    event.venueName,
                    style: TextStyle(color: Colors.grey[400], fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
