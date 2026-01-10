import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

/// Widget reutilizable para imágenes de eventos con caché automático
class CachedEventImage extends StatelessWidget {
  final String? imageUrl;
  final String? thumbnailUrl; // Thumbnail pequeño para listas
  final String? fullImageUrl; // ✅ AGREGADO: Fallback para eventos viejos
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final bool useThumbnail; // Si true, usa thumbnailUrl cuando esté disponible

  const CachedEventImage({
    super.key,
    required this.imageUrl,
    this.thumbnailUrl,
    this.fullImageUrl, // ✅ AGREGADO
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
    // ✅ Decidir qué URL usar con cascada de fallbacks
    final String? urlToUse = useThumbnail && thumbnailUrl != null
        ? thumbnailUrl
        : (imageUrl ?? thumbnailUrl ?? fullImageUrl); // Cascada: imageUrl -> thumbnailUrl -> fullImageUrl
    
    // 🔍 DEBUG: Logs para diagnosticar
    if (kDebugMode) {
      debugPrint('🖼️ [CachedEventImage] Debug:');
      debugPrint('   useThumbnail: $useThumbnail');
      debugPrint('   thumbnailUrl: $thumbnailUrl');
      debugPrint('   imageUrl: $imageUrl');
      debugPrint('   fullImageUrl: $fullImageUrl');
      debugPrint('   ➡️ urlToUse: $urlToUse');
    }

    if (urlToUse == null || urlToUse.isEmpty) {
      if (kDebugMode) {
        debugPrint('⚠️ [CachedEventImage] NO URL - mostrando placeholder');
      }
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
      color: const Color(0xFF252525),
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
