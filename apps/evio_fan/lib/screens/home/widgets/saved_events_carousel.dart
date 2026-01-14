import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:evio_core/evio_core.dart';
import '../../../widgets/cached_event_image.dart';
import '../../../providers/saved_events_provider.dart';
import 'gradient_section_title.dart';

/// Carousel de eventos guardados/favoritos REALES
/// ✅ Cards compactas en scroll horizontal
/// ✅ Usa savedEventsProvider para obtener eventos guardados
class SavedEventsCarousel extends ConsumerWidget {
  const SavedEventsCarousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedEventsAsync = ref.watch(savedEventsProvider);

    return savedEventsAsync.when(
      data: (savedEvents) {
        if (savedEvents.isEmpty) {
          return SizedBox.shrink(); // No mostrar si no hay guardados
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título con gradiente
            Padding(
              padding: EdgeInsets.symmetric(horizontal: EvioSpacing.md), // ⚡ Alineado
              child: GradientSectionTitle(text: 'Guardados'),
            ),
            SizedBox(height: 16),

            // Carousel horizontal
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 20),
                itemCount: savedEvents.length,
                itemBuilder: (context, index) {
                  final event = savedEvents[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == savedEvents.length - 1 ? 0 : 12,
                    ),
                    child: _SavedEventCard(event: event),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => SizedBox.shrink(), // No mostrar mientras carga
      error: (_, __) => SizedBox.shrink(), // No mostrar en error
    );
  }
}

class _SavedEventCard extends StatelessWidget {
  final Event event;

  const _SavedEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/event/${event.id}'),
      child: Container(
        width: 280,
        height: 110,
        decoration: BoxDecoration(
          color: EvioFanColors.card,
          borderRadius: BorderRadius.circular(EvioRadius.card),
          border: Border.all(
            color: EvioFanColors.border,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // ✅ Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(EvioRadius.card),
                bottomLeft: Radius.circular(EvioRadius.card),
              ),
              child: CachedEventImage(
                imageUrl: event.imageUrl,
                thumbnailUrl: event.thumbnailUrl,
                fullImageUrl: event.fullImageUrl,
                useThumbnail: true,
                width: 110,
                height: 110,
                fit: BoxFit.cover,
                memCacheWidth: 220,
              ),
            ),

            // Contenido
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Título
                    Text(
                      event.title,
                      style: TextStyle(
                        color: EvioFanColors.foreground,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Venue y fecha
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.venueName,
                          style: TextStyle(
                            color: EvioFanColors.mutedForeground,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          _formatDate(event.startDatetime),
                          style: TextStyle(
                            color: EvioFanColors.mutedForeground,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final days = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    final months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    final dayName = days[date.weekday % 7];
    final day = date.day;
    final month = months[date.month - 1];
    return '$dayName $day $month';
  }
}
