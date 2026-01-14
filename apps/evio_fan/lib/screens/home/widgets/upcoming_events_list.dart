import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:evio_core/evio_core.dart';
import '../../../providers/event_provider.dart';
import '../../../providers/spotify_provider.dart';
import '../../../providers/ticket_provider.dart';
import '../../../widgets/cached_event_image.dart';

class UpcomingEventsList extends StatelessWidget {
  final List<Event> events;

  const UpcomingEventsList({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Próximos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 16),

        // Lista
        ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20),
          itemCount: events.length,
          separatorBuilder: (context, index) => SizedBox(height: 12),
          itemBuilder: (context, index) {
            final event = events[index];
            return _UpcomingEventCard(event: event);
          },
        ),
      ],
    );
  }
}

class _UpcomingEventCard extends ConsumerWidget {
  final Event event;

  const _UpcomingEventCard({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ Cargar precio mínimo del evento
    final minPriceAsync = ref.watch(eventMinPriceProvider(event.id));

    return InkWell(
      onTap: () => context.push('/event/${event.id}'),

      // ✅ PREFETCH: Solo info estática (cached)
      onHover: (_) {
        // Precachear info del evento
        ref.read(eventInfoProvider(event.id));

        // Precachear imágenes de artistas
        if (event.lineup.isNotEmpty) {
          for (final artist in event.lineup.take(3)) {
            ref.read(artistImageProvider(artist.name));
          }
        }

        // ❌ NO prefetch tickets (datos críticos, siempre fresh)
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ HERO: Imagen con badge de precio
          Stack(
            children: [
              Hero(
                tag: 'event-image-${event.id}',
                child: CachedEventImage(
                imageUrl: event.imageUrl,
                thumbnailUrl: event.thumbnailUrl,
                fullImageUrl: event.fullImageUrl, // ✅ Fallback
                useThumbnail: true, // Usar thumbnail en lista
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(8),
                memCacheWidth: 160, // 2x para retina
                ),
              ),

              // Badge de precio (solo si tiene tandas)
              minPriceAsync.when(
                data: (minPrice) {
                  if (minPrice == null) return const SizedBox.shrink();

                  return Positioned(
                    left: 6,
                    bottom: 6,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFFFFD700),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        minPrice == 0
                            ? 'Gratis'
                            : '\${(minPrice / 100).toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),

          SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                Text(
                  event.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6),

                // Fecha
                Text(
                  _formatDate(event.startDatetime),
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
                SizedBox(height: 4),

                // Ubicación
                Text(
                  '${event.city} · ${event.venueName}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final days = [
      'domingo',
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
    ];
    final months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];

    final dayName = days[date.weekday % 7];
    final day = date.day;
    final month = months[date.month - 1];

    return '$dayName $day.$month';
  }
}
