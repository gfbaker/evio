import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Servicio para procesamiento de imágenes con optimización de memoria
/// 
/// Genera thumbnails y versiones optimizadas de imágenes para reducir
/// ancho de banda y mejorar performance de carga.
class ImageProcessor {
  /// Timeout para operaciones de procesamiento
  static const _processingTimeout = Duration(seconds: 30);

  /// Genera thumbnail 300x300 (cuadrado, centro-crop)
  /// 
  /// Usado para: Listas, carousels, previews
  /// Calidad: 85% JPEG
  /// 
  /// Throws [ImageProcessingException] si falla el procesamiento
  static Future<Uint8List> generateThumbnail(
    Uint8List originalBytes, {
    int size = 300,
    int quality = 85,
  }) async {
    try {
      return await _processWithTimeout(
        () => _generateThumbnailSync(originalBytes, size, quality),
      );
    } catch (e) {
      throw ImageProcessingException('Failed to generate thumbnail: $e');
    }
  }

  /// Genera medium 600x600 (cuadrado, centro-crop)
  /// 
  /// Usado para: Cards, featured sections
  /// Calidad: 90% JPEG
  /// 
  /// Throws [ImageProcessingException] si falla el procesamiento
  static Future<Uint8List> generateMedium(
    Uint8List originalBytes, {
    int size = 600,
    int quality = 90,
  }) async {
    try {
      return await _processWithTimeout(
        () => _generateThumbnailSync(originalBytes, size, quality),
      );
    } catch (e) {
      throw ImageProcessingException('Failed to generate medium: $e');
    }
  }

  /// Optimiza imagen full preservando aspect ratio
  /// 
  /// Max dimension: 1920px en lado más largo
  /// Calidad: 90% JPEG
  /// Si la imagen es menor a 1920px, retorna la original
  /// 
  /// Throws [ImageProcessingException] si falla el procesamiento
  static Future<Uint8List> optimizeFull(
    Uint8List originalBytes, {
    int maxDimension = 1920,
    int quality = 90,
  }) async {
    try {
      return await _processWithTimeout(
        () => _optimizeFullSync(originalBytes, maxDimension, quality),
      );
    } catch (e) {
      throw ImageProcessingException('Failed to optimize full image: $e');
    }
  }

  /// Procesa imagen completa: genera thumbnail, medium y optimiza full
  /// 
  /// Retorna mapa con todas las versiones procesadas
  /// Útil para upload en batch
  /// 
  /// Throws [ImageProcessingException] si falla algún procesamiento
  static Future<ProcessedImages> processAll(Uint8List originalBytes) async {
    try {
      // Procesar en paralelo para mejor performance
      final results = await Future.wait([
        generateThumbnail(originalBytes),
        generateMedium(originalBytes),
        optimizeFull(originalBytes),
      ]).timeout(_processingTimeout);

      return ProcessedImages(
        thumbnail: results[0],
        medium: results[1],
        full: results[2],
      );
    } catch (e) {
      throw ImageProcessingException('Failed to process all images: $e');
    }
  }

  // ============================================
  // MÉTODOS PRIVADOS (SÍNCRONOS)
  // ============================================

  static Uint8List _generateThumbnailSync(
    Uint8List bytes,
    int size,
    int quality,
  ) {
    final image = img.decodeImage(bytes);
    if (image == null) {
      throw ImageProcessingException('Invalid image format');
    }

    // Crop al centro y resize cuadrado
    final thumbnail = img.copyResizeCropSquare(image, size: size);

    // Encode con calidad especificada
    return Uint8List.fromList(img.encodeJpg(thumbnail, quality: quality));
  }

  static Uint8List _optimizeFullSync(
    Uint8List bytes,
    int maxDimension,
    int quality,
  ) {
    final image = img.decodeImage(bytes);
    if (image == null) {
      throw ImageProcessingException('Invalid image format');
    }

    // Si ya es pequeña, no procesar
    if (image.width <= maxDimension && image.height <= maxDimension) {
      return bytes;
    }

    // Resize manteniendo aspect ratio
    final img.Image resized;
    if (image.width > image.height) {
      resized = img.copyResize(image, width: maxDimension);
    } else {
      resized = img.copyResize(image, height: maxDimension);
    }

    return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
  }

  /// Wrapper para ejecutar función síncrona con timeout
  static Future<T> _processWithTimeout<T>(T Function() fn) async {
    return await Future<T>(() => fn()).timeout(
      _processingTimeout,
      onTimeout: () {
        throw ImageProcessingException(
          'Image processing timeout (>${_processingTimeout.inSeconds}s)',
        );
      },
    );
  }
}

// ============================================
// MODELOS
// ============================================

/// Resultado de procesar todas las versiones de una imagen
class ProcessedImages {
  final Uint8List thumbnail; // 300x300
  final Uint8List medium; // 600x600
  final Uint8List full; // Optimizado max 1920px

  const ProcessedImages({
    required this.thumbnail,
    required this.medium,
    required this.full,
  });
}

/// Excepción custom para errores de procesamiento de imágenes
class ImageProcessingException implements Exception {
  final String message;

  const ImageProcessingException(this.message);

  @override
  String toString() => 'ImageProcessingException: $message';
}
