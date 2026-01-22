import 'package:flutter/material.dart';
import 'package:evio_core/evio_core.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Tile minimalista de notificación
/// - Sin card backgrounds
/// - Foto del evento o logo EVIO
class NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const NotificationTile({
    required this.notification,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: EvioSpacing.md,
          vertical: EvioSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar: Foto evento o Logo EVIO
            _buildAvatar(),
            SizedBox(width: EvioSpacing.md),

            // Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título + tiempo en la misma línea
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: notification.isUnread
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: EvioFanColors.foreground,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: EvioSpacing.xs),
                      Text(
                        _formatTime(),
                        style: TextStyle(
                          fontSize: 13,
                          color: EvioFanColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),

                  // Body
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.body,
                          style: TextStyle(
                            fontSize: 14,
                            color: notification.isUnread
                                ? EvioFanColors.secondary
                                : EvioFanColors.mutedForeground,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Dot indicador no leído
                      if (notification.isUnread) ...[
                        SizedBox(width: EvioSpacing.sm),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: EvioFanColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    const double size = 48;

    // Si tiene imagen de evento, mostrarla
    if (notification.hasEventImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: CachedNetworkImage(
          imageUrl: notification.imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _buildEvioLogo(size),
          errorWidget: (_, __, ___) => _buildEvioLogo(size),
        ),
      );
    }

    // Sin imagen: Logo EVIO (círculo amarillo con E negra)
    return _buildEvioLogo(size);
  }

  Widget _buildEvioLogo(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: EvioFanColors.primary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          'E',
          style: TextStyle(
            fontSize: size * 0.5,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            height: 1,
          ),
        ),
      ),
    );
  }

  String _formatTime() {
    final now = DateTime.now();
    final diff = now.difference(notification.createdAt);

    // Menos de 1 minuto
    if (diff.inMinutes < 1) return 'ahora';

    // Menos de 1 hora: "Xm"
    if (diff.inHours < 1) return '${diff.inMinutes}m';

    // Menos de 24 horas: "Xh"
    if (diff.inHours < 24) return '${diff.inHours}h';

    // Menos de 7 días: "Xd"
    if (diff.inDays < 7) return '${diff.inDays}d';

    // Más de 7 días: "Xsem"
    return '${(diff.inDays / 7).floor()}sem';
  }
}
