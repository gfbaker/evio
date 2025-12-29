import 'package:flutter/material.dart';
import 'package:evio_core/evio_core.dart';
import 'package:url_launcher/url_launcher.dart';

class EventVideoSection extends StatelessWidget {
  final Event event;

  const EventVideoSection({super.key, required this.event});

  Future<void> _openYouTube(BuildContext context) async {
    if (event.videoUrl == null || event.videoUrl!.isEmpty) return;

    final uri = Uri.parse(event.videoUrl!);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication, // Abre app de YouTube si está instalada
      );
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo abrir el video'),
            backgroundColor: EvioFanColors.error,
          ),
        );
      }
    }
  }

  String? _getThumbnailUrl() {
    if (event.videoUrl == null || event.videoUrl!.isEmpty) return null;
    
    // Extraer video ID de la URL de YouTube
    final videoId = _extractVideoId(event.videoUrl!);
    if (videoId == null) return null;
    
    // URL del thumbnail de YouTube (maxresdefault = mejor calidad)
    return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
  }

  String? _extractVideoId(String url) {
    // Expresiones regulares para diferentes formatos de URL de YouTube
    final patterns = [
      RegExp(r'youtube\.com/watch\?v=([^&]+)'),
      RegExp(r'youtu\.be/([^?]+)'),
      RegExp(r'youtube\.com/embed/([^?]+)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null && match.groupCount >= 1) {
        return match.group(1);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (event.videoUrl == null || event.videoUrl!.isEmpty) {
      return SizedBox.shrink();
    }

    final thumbnailUrl = _getThumbnailUrl();

    return Container(
      padding: EdgeInsets.all(EvioSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            EvioFanColors.primary.withValues(alpha: 0.05),
            EvioFanColors.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(EvioRadius.card),
        border: Border.all(
          color: EvioFanColors.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con icono
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(EvioSpacing.xs),
                decoration: BoxDecoration(
                  color: EvioFanColors.primary,
                  borderRadius: BorderRadius.circular(EvioRadius.button),
                ),
                child: Icon(
                  Icons.play_circle_filled,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: EvioSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Video Destacado',
                    style: TextStyle(
                      color: EvioFanColors.foreground,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Toca para ver en YouTube',
                    style: TextStyle(
                      color: EvioFanColors.mutedForeground,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          SizedBox(height: EvioSpacing.md),
          
          // Thumbnail clickeable
          GestureDetector(
            onTap: () => _openYouTube(context),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(EvioRadius.card),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(EvioRadius.card),
                child: Stack(
                  children: [
                    // Thumbnail
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: thumbnailUrl != null
                          ? Image.network(
                              thumbnailUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholder();
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return _buildPlaceholder();
                              },
                            )
                          : _buildPlaceholder(),
                    ),
                    
                    // Overlay oscuro
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.3),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Botón de play centrado
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: EvioFanColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: EvioFanColors.primary.withValues(alpha: 0.5),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                    
                    // Logo de YouTube en esquina
                    Positioned(
                      bottom: EvioSpacing.sm,
                      right: EvioSpacing.sm,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: EvioSpacing.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 2),
                            Text(
                              'YouTube',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
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
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade800,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_circle_outline,
              size: 64,
              color: Colors.grey.shade600,
            ),
            SizedBox(height: 8),
            Text(
              'Video',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
