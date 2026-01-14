import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:evio_core/evio_core.dart';

import '../../providers/event_providers.dart';

class EventListItem extends ConsumerStatefulWidget {
  final Event event;

  const EventListItem({required this.event, super.key});

  @override
  ConsumerState<EventListItem> createState() => _EventListItemState();
}

class _EventListItemState extends ConsumerState<EventListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    
    // ✅ Obtener stats reales del provider
    final statsAsync = ref.watch(eventStatsProvider(event.id));
    
    final totalCapacity = event.totalCapacity ?? 0;
    final soldCount = statsAsync.maybeWhen(
      data: (stats) => stats.soldCount,
      orElse: () => 0,
    );
    final occupancy = totalCapacity > 0
        ? (soldCount / totalCapacity)
        : 0.0;
    final occupancyPercent = (occupancy * 100).round();
    
    // Contar DJs del lineup
    final djCount = event.lineup.length;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => context.push('/admin/events/${event.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(EvioSpacing.md),
          decoration: BoxDecoration(
            color: EvioLightColors.card,
            borderRadius: BorderRadius.circular(EvioRadius.card),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              // Row principal
              Row(
                children: [
                  // Imagen
                  ClipRRect(
                    borderRadius: BorderRadius.circular(EvioRadius.button),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: event.imageUrl != null
                          ? Image.network(
                              event.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildPlaceholder(),
                            )
                          : _buildPlaceholder(),
                    ),
                  ),

                  SizedBox(width: EvioSpacing.md),

                  // Info principal
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título
                        Text(
                          event.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: EvioLightColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        SizedBox(height: 4),
                        
                        // Venue
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: EvioLightColors.mutedForeground,
                            ),
                            SizedBox(width: 4),
                            Text(
                              event.venueName,
                              style: TextStyle(
                                fontSize: 13,
                                color: EvioLightColors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 6),
                        
                        // Info row: fecha, tickets, DJs
                        Row(
                          children: [
                            // Fecha
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: EvioLightColors.mutedForeground,
                            ),
                            SizedBox(width: 4),
                            Text(
                              DateFormat('d \'de\' MMMM', 'es').format(event.startDatetime),
                              style: TextStyle(
                                fontSize: 13,
                                color: EvioLightColors.mutedForeground,
                              ),
                            ),
                            
                            SizedBox(width: EvioSpacing.md),
                            
                            // Tickets
                            Icon(
                              Icons.confirmation_number_outlined,
                              size: 14,
                              color: EvioLightColors.mutedForeground,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${soldCount}/${totalCapacity} tickets',
                              style: TextStyle(
                                fontSize: 13,
                                color: EvioLightColors.mutedForeground,
                              ),
                            ),
                            
                            SizedBox(width: EvioSpacing.md),
                            
                            // DJs
                            Icon(
                              Icons.music_note_outlined,
                              size: 14,
                              color: EvioLightColors.mutedForeground,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '$djCount DJs',
                              style: TextStyle(
                                fontSize: 13,
                                color: EvioLightColors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: EvioSpacing.lg),

                  // Genre badge
                  if (event.genre != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: EvioSpacing.sm,
                        vertical: EvioSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: EvioLightColors.muted,
                        borderRadius: BorderRadius.circular(EvioRadius.button),
                      ),
                      child: Text(
                        event.genre!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: EvioLightColors.textPrimary,
                        ),
                      ),
                    ),
                ],
              ),

              SizedBox(height: EvioSpacing.md),

              // Progress bar row
              Row(
                children: [
                  // Progress bar
                  Expanded(
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: EvioLightColors.muted,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: occupancy.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: EvioLightColors.accent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(width: EvioSpacing.md),
                  
                  // Percentage
                  Text(
                    '$occupancyPercent%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: EvioLightColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: EvioLightColors.muted,
      child: Icon(
        Icons.image_outlined,
        size: 24,
        color: EvioLightColors.mutedForeground,
      ),
    );
  }
}
