import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:evio_core/evio_core.dart';
import '../../../widgets/cached_event_image.dart';

/// Card para mostrar un evento guardado en la lista de favoritos
class SavedEventCard extends StatefulWidget {
  final Event event;

  const SavedEventCard({super.key, required this.event});

  @override
  State<SavedEventCard> createState() => _SavedEventCardState();
}

class _SavedEventCardState extends State<SavedEventCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/event/${widget.event.id}'),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(EvioSpacing.sm),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(EvioRadius.card),
            border: Border.all(
              color: _isHovered
                  ? EvioFanColors.primary.withValues(alpha: 0.3)
                  : EvioFanColors.border,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Imagen
              CachedEventImage(
                imageUrl: widget.event.imageUrl,
                thumbnailUrl: widget.event.thumbnailUrl,
                fullImageUrl: widget.event.fullImageUrl,
                useThumbnail: true,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(EvioRadius.button),
                memCacheWidth: 180,
              ),

              SizedBox(width: EvioSpacing.md),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.event.title,
                      style: EvioTypography.labelLarge.copyWith(
                        color: EvioFanColors.foreground,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: EvioSpacing.xxs),
                    Text(
                      _formatDate(widget.event.startDatetime),
                      style: EvioTypography.bodySmall.copyWith(
                        color: EvioFanColors.mutedForeground,
                      ),
                    ),
                    SizedBox(height: EvioSpacing.xxs),
                    Text(
                      widget.event.venueName,
                      style: EvioTypography.bodySmall.copyWith(
                        color: EvioFanColors.mutedForeground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right,
                color: EvioFanColors.mutedForeground,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const days = ['domingo', 'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado'];
    const months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

    final dayName = days[date.weekday % 7];
    final day = date.day;
    final month = months[date.month - 1];

    return '$dayName $day.$month';
  }
}
