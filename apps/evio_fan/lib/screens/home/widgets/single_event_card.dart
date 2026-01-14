import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:evio_core/evio_core.dart';
import '../../../widgets/cached_event_image.dart';
import 'dart:ui';

/// Card de evento individual con glassmorphism sutil
/// ✅ Marco blur negro (no imagen)
/// ✅ Info abajo con fecha en texto
/// ✅ Sin badge destacado
class SingleEventCard extends StatelessWidget {
  final Event event;

  const SingleEventCard({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // ⚡ ARREGLADO: Usar md (16px) en vez de lg para coincidir con el padding
    final cardWidth = screenWidth - (EvioSpacing.md * 2);
    final imageHeight = cardWidth * 1.1;
    final infoHeight = 80.0; // Info más compacta que el hero
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: EvioSpacing.md), // ⚡ Mismo padding que títulos (md = 16px)
      child: GestureDetector(
        onTap: () => context.push('/event/${event.id}'),
        child: Container(
          width: cardWidth,
          height: imageHeight + 24 + infoHeight,
          child: Stack(
            children: [
              // 🌫️ MARCO BLUR GRIS - Fondo con blur gris sutil
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        // ⚡ Gris oscuro en vez de negro puro
                        color: Color(0xFF1a1a1a).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                        // ⚡ Sin borde
                      ),
                    ),
                  ),
                ),
              ),

              // 🖼️ IMAGEN PRINCIPAL
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Container(
                  width: cardWidth - 24,
                  height: imageHeight - 12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        // Imagen principal
                        Positioned.fill(
                          child: CachedEventImage(
                            imageUrl: event.imageUrl,
                            thumbnailUrl: event.thumbnailUrl,
                            fullImageUrl: event.fullImageUrl,
                            fit: BoxFit.cover,
                            width: cardWidth - 24,
                            height: imageHeight - 12,
                            memCacheHeight: (imageHeight * 2).toInt(),
                          ),
                        ),

                        // Gradiente sutil
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.2),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ✅ INFO DENTRO DEL MARCO (abajo)
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    Text(
                      event.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            offset: Offset(0, 1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6),

                    // Fecha
                    Text(
                      _formatDate(event.startDatetime),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            offset: Offset(0, 1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 2),

                    // Venue + Ciudad
                    Text(
                      '${event.venueName} · ${event.city}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            offset: Offset(0, 1),
                            blurRadius: 4,
                          ),
                        ],
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
