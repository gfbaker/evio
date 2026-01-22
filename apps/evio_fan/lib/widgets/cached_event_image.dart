import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

/// Widget reutilizable para imágenes de eventos con caché automático
class CachedEventImage extends StatelessWidget {
  final String? imageUrl;
  final String? thumbnailUrl;
  final String? fullImageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final bool useThumbnail;

  const CachedEventImage({
    super.key,
    required this.imageUrl,
    this.thumbnailUrl,
    this.fullImageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.memCacheWidth,
    this.memCacheHeight,
    this.useThumbnail = false,
  });

  @override
  Widget build(BuildContext context) {
    // Seleccionar URL con fallback en cascada
    final String? urlToUse = useThumbnail && thumbnailUrl != null
        ? thumbnailUrl
        : (imageUrl ?? thumbnailUrl ?? fullImageUrl);

    if (urlToUse == null || urlToUse.isEmpty) {
      return _buildPlaceholder();
    }

    final widget = CachedNetworkImage(
      imageUrl: urlToUse,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      placeholder: (context, url) => _buildShimmer(),
      errorWidget: (context, url, error) => _buildPlaceholder(),
      // ✅ Silenciar errores de imagen en consola
      errorListener: (error) {
        // Ignorar errores de formato de imagen silenciosamente
        // Estos errores ya se manejan con errorWidget
        debugPrint('⚠️ [CachedEventImage] Error cargando imagen: ${error.toString().split('\n').first}');
      },
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: widget,
      );
    }

    return widget;
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF252525),
      highlightColor: const Color(0xFF353535),
      child: Container(
        width: width,
        height: height,
        color: const Color(0xFF252525),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          size: (height != null && height! < 100) ? 40 : 80,
          color: Colors.grey[700],
        ),
      ),
    );
  }
}
