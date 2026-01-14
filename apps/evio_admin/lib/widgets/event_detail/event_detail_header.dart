import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:evio_core/evio_core.dart';

/// Header del detalle del evento con imagen, título, metadata y acciones.
class EventDetailHeader extends StatelessWidget {
  final Event event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const EventDetailHeader({
    required this.event,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  String get _statusLabel {
    if (!event.isPublished) return 'Borrador';
    return event.isPast ? 'Finalizado' : 'Publicado';
  }

  Color get _statusColor {
    switch (_statusLabel) {
      case 'Borrador':
        return Colors.orange.shade600;
      case 'Publicado':
        return EvioLightColors.statusUpcoming;
      case 'Finalizado':
        return EvioLightColors.statusCompleted;
      default:
        return EvioLightColors.statusCancelled;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(EvioSpacing.xl),
      color: EvioLightColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila de botones
          Row(
            children: [
              _HeaderButton(
                icon: Icons.arrow_back,
                label: 'Volver',
                onTap: () => context.pop(),
              ),
              const Spacer(),
              _HeaderButton(
                icon: Icons.edit_outlined,
                label: 'Editar',
                onTap: onEdit,
              ),
              SizedBox(width: EvioSpacing.xs),
              _HeaderButton(
                icon: Icons.delete_outline,
                label: 'Eliminar',
                onTap: onDelete,
                isDestructive: true,
              ),
            ],
          ),
          SizedBox(height: EvioSpacing.lg),
          
          // Info del evento
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(EvioRadius.card),
                  color: EvioLightColors.muted,
                ),
                clipBehavior: Clip.antiAlias,
                child: event.imageUrl != null
                    ? Image.network(
                        event.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _ImagePlaceholder(),
                      )
                    : _ImagePlaceholder(),
              ),
              SizedBox(width: EvioSpacing.lg),
              
              // Título y metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título + Badge
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            event.title,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: EvioLightColors.textPrimary,
                            ),
                          ),
                        ),
                        SizedBox(width: EvioSpacing.sm),
                        _StatusBadge(
                          label: _statusLabel,
                          color: _statusColor,
                        ),
                      ],
                    ),
                    SizedBox(height: EvioSpacing.md),
                    
                    // Metadata
                    Wrap(
                      spacing: EvioSpacing.lg,
                      runSpacing: EvioSpacing.sm,
                      children: [
                        _MetaItem(
                          icon: Icons.calendar_today,
                          text: DateFormat('EEEE, d MMMM yyyy', 'es')
                              .format(event.startDatetime),
                        ),
                        _MetaItem(
                          icon: Icons.access_time,
                          text: DateFormat('HH:mm').format(event.startDatetime),
                        ),
                        _MetaItem(
                          icon: Icons.location_on,
                          text: event.venueName,
                        ),
                        if (event.genre != null)
                          _MetaItem(
                            icon: Icons.music_note,
                            text: event.genre!,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// WIDGETS PRIVADOS
// -----------------------------------------------------------------------------

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _HeaderButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isDestructive) {
      return FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: EvioLightColors.destructive,
          foregroundColor: EvioLightColors.destructiveForeground,
          padding: EdgeInsets.symmetric(horizontal: EvioSpacing.md),
          minimumSize: Size(0, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(EvioRadius.button),
          ),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: EvioLightColors.textPrimary,
        backgroundColor: EvioLightColors.card,
        side: BorderSide(color: EvioLightColors.border),
        padding: EdgeInsets.symmetric(horizontal: EvioSpacing.md),
        minimumSize: Size(0, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EvioRadius.button),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: EvioLightColors.mutedForeground),
        SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: EvioLightColors.mutedForeground,
          ),
        ),
      ],
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: EvioLightColors.muted,
      child: Center(
        child: Icon(
          Icons.image,
          size: 40,
          color: EvioLightColors.mutedForeground,
        ),
      ),
    );
  }
}
