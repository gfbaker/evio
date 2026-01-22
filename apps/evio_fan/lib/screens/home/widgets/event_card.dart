import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:evio_core/evio_core.dart';
import '../../../widgets/cached_event_image.dart';
import 'dart:ui';

/// Card de evento estilo Dice
/// ✅ Blur con transición suave (sin corte)
/// ✅ Efecto "humo" que mezcla colores de imagen
class EventCard extends StatelessWidget {
  final Event event;
  final bool isFeatured;

  const EventCard({
    super.key,
    required this.event,
    this.isFeatured = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth - (EvioSpacing.md * 2);
    final cardHeight = cardWidth * 1.15;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: EvioSpacing.md),
      child: GestureDetector(
        onTap: () => context.push('/event/${event.id}'),
        child: Container(
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // 🖼️ IMAGEN BASE
                Positioned.fill(
                  child: CachedEventImage(
                    imageUrl: event.imageUrl,
                    thumbnailUrl: event.thumbnailUrl,
                    fullImageUrl: event.fullImageUrl,
                    fit: BoxFit.cover,
                    width: cardWidth,
                    height: cardHeight,
                    memCacheHeight: (cardHeight * 2).toInt(),
                  ),
                ),

                // 🌫️ CAPA DE IMAGEN BLUREADA con máscara gradiente
                Positioned.fill(
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.5),
                          Colors.white,
                        ],
                        stops: const [0.0, 0.45, 0.65, 0.85],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                ),

                // 🎨 GRADIENTE oscuro para legibilidad
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.3),
                          Colors.black.withValues(alpha: 0.7),
                        ],
                        stops: const [0.0, 0.5, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),

                // ✅ CONTENIDO
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Etiqueta "DESTACADO"
                      if (isFeatured) ...[
                        Text(
                          'DESTACADO',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.0,
                          ),
                        ),
                        SizedBox(height: 6),
                      ],

                      // Título
                      Text(
                        event.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isFeatured ? 26 : 24,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6),

                      // Metadata
                      Text(
                        '${_formatDate(event.startDatetime)}, ${event.venueName}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final days = ['dom', 'lun', 'mar', 'mié', 'jue', 'vie', 'sáb'];
    final months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    final dayName = days[date.weekday % 7];
    final day = date.day;
    final month = months[date.month - 1];
    return '$dayName, $day $month';
  }
}
