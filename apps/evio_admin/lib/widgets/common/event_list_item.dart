import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:evio_core/evio_core.dart';
import '../../providers/event_providers.dart';

class EventListItem extends StatefulWidget {
  final Event event;

  const EventListItem({required this.event, super.key});

  @override
  State<EventListItem> createState() => _EventListItemState();
}

class _EventListItemState extends State<EventListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('d MMM yyyy', 'es');
    final price = widget.event.minPrice != null
        ? '\$${widget.event.minPrice}'
        : 'Gratis';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => context.push('/admin/events/${widget.event.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(EvioSpacing.md),
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
          child: Row(
            children: [
              // 1. IMAGEN
              ClipRRect(
                borderRadius: BorderRadius.circular(EvioRadius.md),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: widget.event.imageUrl != null
                      ? Image.network(
                          widget.event.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                ),
              ),

              SizedBox(width: EvioSpacing.lg),

              // 2. INFO PRINCIPAL
              // 2. INFO PRINCIPAL
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Fila Título + Badge
                    Row(
                      children: [
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
                        SizedBox(width: EvioSpacing.xs),
                        _StatusBadge(event: widget.event),
                      ],
                    ),
                    SizedBox(height: EvioSpacing.xxs),
                    // Subtítulo
                    Text(
                      '${widget.event.genre ?? 'General'} • ${widget.event.venueName}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: EvioLightColors.mutedForeground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              SizedBox(width: EvioSpacing.lg),

              // 3. COLUMNAS DE DATOS
              _DataColumn(
                label: 'Fecha',
                value: dateFormatter.format(widget.event.startDatetime),
                width: 100,
              ),

              _DataColumn(
                label: 'Capacidad',
                value:
                    '${widget.event.soldCount}/${widget.event.totalCapacity}',
                width: 100,
              ),

              _DataColumn(label: 'Precio', value: price, width: 80),

              SizedBox(width: EvioSpacing.sm),

              // 4. MENU
              _buildMenu(context),
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

  Widget _buildMenu(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: EvioLightColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(EvioRadius.xs),
            side: BorderSide(color: EvioLightColors.border),
          ),
          elevation: 4,
        ),
      ),
      child: PopupMenuButton<String>(
        icon: Icon(
          Icons.more_vert,
          size: EvioSpacing.iconM,
          color: EvioLightColors.foreground,
        ),
        tooltip: 'Opciones',
        offset: const Offset(0, 40),
        onSelected: (value) {
          if (value == 'details') {
            context.push('/admin/events/${widget.event.id}');
          } else if (value == 'edit') {
            context.push('/admin/events/${widget.event.id}/edit');
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: 'details',
            height: 40,
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
          PopupMenuItem<String>(
            value: 'edit',
            height: 40,
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
      ),
    );
  }
}

class _DataColumn extends StatelessWidget {
  final String label;
  final String value;
  final double width;

  const _DataColumn({
    required this.label,
    required this.value,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: EvioLightColors.mutedForeground,
            ),
          ),
          SizedBox(height: EvioSpacing.xxs),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: EvioLightColors.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final Event event;
  const _StatusBadge({required this.event});

  @override
  Widget build(BuildContext context) {
    String label = 'Próximo';
    Color bgColor = const Color(0xFFDBEAFE);
    Color textColor = const Color(0xFF1E40AF);

    if (event.isPast) {
      label = 'Finalizado';
      bgColor = const Color(0xFFF3F4F6);
      textColor = const Color(0xFF1F2937);
    } else if (event.isOngoing) {
      label = 'En curso';
      bgColor = const Color(0xFFD1FAE5);
      textColor = const Color(0xFF065F46);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: EvioSpacing.xs, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(EvioRadius.button),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}
