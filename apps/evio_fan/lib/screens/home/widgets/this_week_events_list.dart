import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:evio_core/evio_core.dart';
import '../../../widgets/cached_event_image.dart';
import 'gradient_section_title.dart';

/// Lista de eventos de esta semana (lunes a domingo)
/// ✅ Filtrado automático por semana actual
/// ✅ Estilo igual a "Próximos"
class ThisWeekEventsList extends StatelessWidget {
  final List<Event> events;

  const ThisWeekEventsList({
    super.key,
    required this.events,
  });

  /// Obtiene el lunes de la semana actual
  DateTime _getMondayOfWeek(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day - (weekday - 1));
  }

  /// Filtra eventos de lunes a domingo de la semana actual
  List<Event> _getThisWeekEvents() {
    final now = DateTime.now();
    final monday = _getMondayOfWeek(now);
    final sunday = monday.add(Duration(days: 6, hours: 23, minutes: 59));

    return events.where((event) {
      final eventDate = event.startDatetime;
      return eventDate.isAfter(monday.subtract(Duration(seconds: 1))) &&
             eventDate.isBefore(sunday.add(Duration(seconds: 1)));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final thisWeekEvents = _getThisWeekEvents();

    if (thisWeekEvents.isEmpty) {
      return SizedBox.shrink(); // No mostrar sección si no hay eventos
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título con gradiente
        Padding(
          padding: EdgeInsets.symmetric(horizontal: EvioSpacing.md), // ⚡ Alineado
          child: GradientSectionTitle(text: 'Esta Semana'),
        ),
        SizedBox(height: 16),

        // Lista
        ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20),
          itemCount: thisWeekEvents.length,
          separatorBuilder: (context, index) => SizedBox(height: 12),
          itemBuilder: (context, index) {
            final event = thisWeekEvents[index];
            return _ThisWeekEventCard(event: event);
          },
        ),
      ],
    );
  }
}

class _ThisWeekEventCard extends ConsumerWidget {
  final Event event;

  const _ThisWeekEventCard({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => context.push('/event/${event.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Imagen (sin Hero)
          CachedEventImage(
            imageUrl: event.imageUrl,
            thumbnailUrl: event.thumbnailUrl,
            fullImageUrl: event.fullImageUrl,
            useThumbnail: true,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(8),
            memCacheWidth: 160,
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
