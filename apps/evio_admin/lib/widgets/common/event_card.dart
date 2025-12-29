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
    final statusColors = _getStatusColors(widget.event);
    
    // ✅ Cargar categorías para obtener tier activo
    final categoriesAsync = ref.watch(
      eventTicketCategoriesProvider(widget.event.id),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => context.push('/admin/events/${widget.event.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: EvioLightColors.card,
            borderRadius: BorderRadius.circular(EvioRadius.xl),
            border: Border.all(color: EvioLightColors.border),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen + Badges
              SizedBox(
                height: 192,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(EvioRadius.xl),
                        topRight: Radius.circular(EvioRadius.xl),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: widget.event.imageUrl != null
                            ? Image.network(
                                widget.event.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildPlaceholder(),
                              )
                            : _buildPlaceholder(),
                      ),
                    ),
                    Positioned(
                      top: EvioSpacing.sm,
                      left: EvioSpacing.sm,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: EvioSpacing.xs,
                          vertical: EvioSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: statusColors['bg'],
                          borderRadius: BorderRadius.circular(
                            EvioRadius.button,
                          ),
                        ),
                        child: Text(
                          _getStatusLabel(widget.event),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: statusColors['text'],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: EvioSpacing.sm,
                      right: EvioSpacing.sm,
                      child: _EventCardMenu(eventId: widget.event.id),
                    ),
                  ],
                ),
              ),

              // Contenido
              Padding(
                padding: EdgeInsets.only(
                  left: EvioSpacing.md,
                  right: EvioSpacing.md,
                  top: EvioSpacing.md,
                  bottom: EvioSpacing.sm, // ✅ Reducido de md a sm
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título - Estilo Grid
                    Text(
                      widget.event.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: EvioLightColors.foreground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: EvioSpacing.xxs),

                    // Género - Estilo Grid
                    Text(
                      widget.event.genre ?? 'Música Electrónica',
                      style: const TextStyle(
                        fontSize: 14,
                        color: EvioLightColors.mutedForeground,
                      ),
                    ),
                    SizedBox(height: EvioSpacing.sm),

                    // Fecha y Hora
                    _InfoRow(
                      icon: Icons.calendar_today,
                      text: DateFormat(
                        'd MMM yyyy • HH:mm',
                        'es',
                      ).format(widget.event.startDatetime),
                    ),
                    SizedBox(height: EvioSpacing.xs),

                    // Ubicación
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      text: '${widget.event.venueName}, ${widget.event.city}',
                    ),

                    // Divisor
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: EvioSpacing.sm),
                      child: Divider(height: 1, color: EvioLightColors.border),
                    ),

                    // Stats Footer
                    categoriesAsync.when(
                      data: (categories) {
                        final activeTier = _getActiveTier(categories);
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.confirmation_number_outlined,
                                  size: EvioSpacing.iconS,
                                  color: EvioLightColors.mutedForeground,
                                ),
                                SizedBox(width: EvioSpacing.xxs),
                                const Text(
                                  'Etapa de Venta',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: EvioLightColors.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: EvioSpacing.xs,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: EvioLightColors.muted,
                                borderRadius: BorderRadius.circular(
                                  EvioRadius.button,
                                ),
                                border: Border.all(color: EvioLightColors.border),
                              ),
                              child: Text(
                                activeTier ?? 'Sin venta',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.confirmation_number_outlined,
                                size: EvioSpacing.iconS,
                                color: EvioLightColors.mutedForeground,
                              ),
                              SizedBox(width: EvioSpacing.xxs),
                              const Text(
                                'Etapa de Venta',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: EvioLightColors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            width: 60,
                            height: 20,
                            child: Center(
                              child: SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      error: (_, __) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.confirmation_number_outlined,
                                size: EvioSpacing.iconS,
                                color: EvioLightColors.mutedForeground,
                              ),
                              SizedBox(width: EvioSpacing.xxs),
                              const Text(
                                'Etapa de Venta',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: EvioLightColors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: EvioSpacing.xs,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: EvioLightColors.muted,
                              borderRadius: BorderRadius.circular(
                                EvioRadius.button,
                              ),
                              border: Border.all(color: EvioLightColors.border),
                            ),
                            child: const Text(
                              'Sin venta',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: EvioSpacing.xxs), // ✅ Reducido de xs a xxs

                    // Asistencia
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: EvioSpacing.iconS,
                              color: EvioLightColors.mutedForeground,
                            ),
                            SizedBox(width: EvioSpacing.xxs),
                            const Text(
                              'Asistencia',
                              style: TextStyle(
                                fontSize: 12,
                                color: EvioLightColors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${widget.event.soldCount}/${widget.event.totalCapacity}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: EvioLightColors.foreground,
                          ),
                        ),
                      ],
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

  Map<String, Color> _getStatusColors(Event event) {
    if (event.isPast) {
      return {'bg': const Color(0xFFF3F4F6), 'text': const Color(0xFF1F2937)};
    }
    if (event.isOngoing) {
      return {'bg': const Color(0xFFD1FAE5), 'text': const Color(0xFF065F46)};
    }
    return {'bg': const Color(0xFFDBEAFE), 'text': const Color(0xFF1E40AF)};
  }

  String _getStatusLabel(Event event) {
    if (event.isPast) return 'Finalizado';
    if (event.isOngoing) return 'En curso';
    return 'Próximo';
  }

  // ✅ Determinar tier activo
  String? _getActiveTier(List<TicketCategory> categories) {
    if (categories.isEmpty) return null;
    
    final now = DateTime.now();
    
    // Buscar en todas las categorías
    for (final category in categories) {
      for (final tier in category.tiers) {
        // Verificar si el tier está activo y en rango de fechas
        if (!tier.isActive) continue;
        
        // Si tiene fechas de venta, verificar rango
        if (tier.saleStartsAt != null || tier.saleEndsAt != null) {
          final startsAt = tier.saleStartsAt;
          final endsAt = tier.saleEndsAt;
          
          final isInRange = (startsAt == null || now.isAfter(startsAt)) &&
                           (endsAt == null || now.isBefore(endsAt));
          
          if (isInRange) {
            return tier.name;
          }
        } else {
          // Sin fechas = siempre activo si isActive = true
          return tier.name;
        }
      }
    }
    
    return null;
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: EvioSpacing.iconS,
          color: EvioLightColors.mutedForeground,
        ),
        SizedBox(width: EvioSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: EvioLightColors.mutedForeground,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

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
            size: EvioSpacing.iconS,
            color: EvioLightColors.foreground,
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
      Rect.fromPoints(
        offset.translate(0, size.height),
        offset.translate(size.width, size.height + 80),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: navContext,
      position: position,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(EvioRadius.xs),
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
                size: EvioSpacing.iconS,
                color: EvioLightColors.mutedForeground,
              ),
              SizedBox(width: EvioSpacing.xs),
              const Text('Ver Detalles', style: TextStyle(fontSize: 14)),
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
                size: EvioSpacing.iconS,
                color: EvioLightColors.mutedForeground,
              ),
              SizedBox(width: EvioSpacing.xs),
              const Text('Editar', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}
