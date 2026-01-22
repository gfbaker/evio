import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:evio_core/evio_core.dart';
import '../../../widgets/cached_event_image.dart';
import 'dart:ui';

/// Card destacada estilo Venti con glassmorphism
/// ✅ Marco = imagen blur (mismos colores)
/// ✅ Badge "DESTACADO" arriba
/// ✅ Info abajo de la card
class FeaturedEventCard extends StatelessWidget {
  final Event event;

  const FeaturedEventCard({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // ⚡ ARREGLADO: Usar md (16px) en vez de lg para coincidir con el padding
    final cardWidth = screenWidth - (EvioSpacing.md * 2);
    final imageHeight = cardWidth * 1.1; // Imagen más cuadrada
    final infoHeight = 100.0; // Altura para la info abajo
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: EvioSpacing.md), // ⚡ Mismo padding que títulos (md = 16px)
      child: GestureDetector(
        onTap: () => context.push('/event/${event.id}'),
        child: Container(
          width: cardWidth,
          height: imageHeight + 24 + infoHeight, // Total: imagen + marco + info
          child: Stack(
            children: [
              // 🌫️ MARCO BLUR - Imagen difuminada de fondo
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // Imagen blur para el marco
                      Positioned.fill(
                        child: CachedEventImage(
                          imageUrl: event.imageUrl,
                          thumbnailUrl: event.thumbnailUrl,
                          fullImageUrl: event.fullImageUrl,
                          fit: BoxFit.cover,
                          width: cardWidth,
                          height: imageHeight + 24 + infoHeight,
                        ),
                      ),
                      // Blur intenso
                      Positioned.fill(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 🖼️ IMAGEN PRINCIPAL (centrada arriba, mismo padding)
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

                        // ✅ BADGE FECHA - Top right (gris/negro)
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Mes
                                Text(
                                  _getMonth(event.startDatetime).toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                // Día
                                Text(
                                  event.startDatetime.day.toString(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    height: 1.0,
                                  ),
                                ),
                              ],
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
                    // ✅ BADGE "DESTACADO" - Estilo mate con borde
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: EvioFanColors.primary.withValues(alpha: 0.8),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'DESTACADO',
                        style: TextStyle(
                          color: EvioFanColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    SizedBox(height: EvioSpacing.sm),

                    // Título
                    Text(
                      event.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
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
                    SizedBox(height: 4),

                    // Venue + Ciudad
                    Text(
                      '${event.venueName} · ${event.city}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
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

  String _getMonth(DateTime date) {
    final months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return months[date.month - 1];
  }
}
