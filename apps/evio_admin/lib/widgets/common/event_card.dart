import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:evio_core/evio_core.dart';

import '../../providers/event_providers.dart';

class EventCard extends ConsumerStatefulWidget {
  final Event event;

  const EventCard({required this.event, super.key});

  @override
  ConsumerState<EventCard> createState() => _EventCardState();
}

class _EventCardState extends ConsumerState<EventCard> {
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

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => context.push('/admin/events/${event.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: EvioLightColors.card,
            borderRadius: BorderRadius.circular(EvioRadius.card),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen con menú
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(EvioRadius.card),
                    ),
                    child: SizedBox(
                      height: 160,
                      width: double.infinity,
                      child: event.imageUrl != null
                          ? Image.network(
                              event.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildPlaceholder(),
                            )
                          : _buildPlaceholder(),
                    ),
                  ),
                  Positioned(
                    top: EvioSpacing.sm,
                    right: EvioSpacing.sm,
                    child: _EventCardMenu(eventId: event.id),
                  ),
                ],
              ),

              // Contenido
              Padding(
                padding: EdgeInsets.all(EvioSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date badge + Title + Venue
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DateBadge(date: event.startDatetime),
                        SizedBox(width: EvioSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                              SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: EvioLightColors.mutedForeground,
                                  ),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      event.venueName,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: EvioLightColors.mutedForeground,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: EvioSpacing.sm),

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

                    SizedBox(height: EvioSpacing.md),

                    // Vendidos row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Vendidos',
                          style: TextStyle(
                            fontSize: 13,
                            color: EvioLightColors.mutedForeground,
                          ),
                        ),
                        Text(
                          '${soldCount}/${totalCapacity}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: EvioLightColors.textPrimary,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: EvioSpacing.xs),

                    // Progress bar
                    Container(
                      height: 8,
                      width: double.infinity,
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

                    SizedBox(height: EvioSpacing.xs),

                    // Ocupación
                    Text(
                      'Ocupación: $occupancyPercent%',
                      style: TextStyle(
                        fontSize: 12,
                        color: EvioLightColors.mutedForeground,
                      ),
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

  Widget _buildPlaceholder() {
    return Container(
      color: EvioLightColors.muted,
      child: Center(
        child: Icon(
          Icons.image,
          size: 48,
          color: EvioLightColors.mutedForeground.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// DATE BADGE
// -----------------------------------------------------------------------------

class _DateBadge extends StatelessWidget {
  final DateTime date;

  const _DateBadge({required this.date});

  @override
  Widget build(BuildContext context) {
    final day = date.day.toString();
    final month = DateFormat('MMM', 'es').format(date).toUpperCase();

    return Container(
      width: 48,
      padding: EdgeInsets.symmetric(vertical: EvioSpacing.xs),
      decoration: BoxDecoration(
        color: EvioLightColors.muted,
        borderRadius: BorderRadius.circular(EvioRadius.button),
      ),
      child: Column(
        children: [
          Text(
            day,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: EvioLightColors.textPrimary,
              height: 1,
            ),
          ),
          Text(
            month,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: EvioLightColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// MENU
// -----------------------------------------------------------------------------

class _EventCardMenu extends StatelessWidget {
  final String eventId;

  const _EventCardMenu({required this.eventId});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (ctx) => InkWell(
        onTap: () => _showCustomMenu(ctx, context, eventId),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(EvioRadius.button),
          ),
          child: Icon(
            Icons.more_vert,
            size: 18,
            color: EvioLightColors.textPrimary,
          ),
        ),
      ),
    );
  }

  void _showCustomMenu(
    BuildContext buttonContext,
    BuildContext navContext,
    String eventId,
  ) {
    final RenderBox renderBox = buttonContext.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    final RenderBox overlay =
        Navigator.of(navContext).overlay!.context.findRenderObject()
            as RenderBox;

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromLTWH(
        offset.dx,
        offset.dy + size.height,
        size.width,
        0,
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: navContext,
      position: position,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(EvioRadius.button),
      ),
      color: Colors.white,
      items: [
        PopupMenuItem(
          height: 40,
          onTap: () => Future.delayed(
            Duration.zero,
            () => navContext.push('/admin/events/$eventId'),
          ),
          child: Row(
            children: [
              Icon(
                Icons.visibility_outlined,
                size: 18,
                color: EvioLightColors.mutedForeground,
              ),
              SizedBox(width: EvioSpacing.xs),
              Text('Ver Detalles', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        PopupMenuItem(
          height: 40,
          onTap: () => Future.delayed(
            Duration.zero,
            () => navContext.push('/admin/events/$eventId/edit'),
          ),
          child: Row(
            children: [
              Icon(
                Icons.edit_outlined,
                size: 18,
                color: EvioLightColors.mutedForeground,
              ),
              SizedBox(width: EvioSpacing.xs),
              Text('Editar', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}
