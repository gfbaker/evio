import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'image_processor.dart';

/// Servicio para gestión de archivos en Supabase Storage
/// 
/// Maneja uploads de imágenes con generación automática de thumbnails
/// y versiones optimizadas. Implementa retry logic y timeouts.
class StorageService {
  final SupabaseClient _client;

  /// Timeout para operaciones de upload
  static const _uploadTimeout = Duration(seconds: 60);

  /// Número máximo de reintentos en caso de fallo
  static const _maxRetries = 3;

  StorageService(this._client);

  /// Upload de imagen de evento con generación automática de versiones
  /// 
  /// Genera y sube 3 versiones:
  /// - thumbnail (300x300) → /events/thumbs/{eventId}_300x300.jpg
  /// - medium (600x600) → /events/medium/{eventId}_600x600.jpg
  /// - full (optimizado) → /events/{eventId}.jpg
  /// 
  /// Returns URLs públicas de las 3 versiones
  /// Throws [StorageException] si falla el upload
  Future<EventImageUrls> uploadEventImage({
    required String eventId,
    required Uint8List imageBytes,
    String extension = 'jpg',
  }) async {
    try {
      debugPrint('📤 [StorageService] Iniciando procesamiento de imágenes...');
      debugPrint('   eventId: $eventId');
      debugPrint('   imageBytes size: ${imageBytes.length}');
      
      // 0. 🗑️ LIMPIAR ARCHIVOS VIEJOS PRIMERO
      debugPrint('🗑️ [StorageService] Eliminando archivos anteriores si existen...');
      try {
        await deleteEventImage(eventId: eventId, extension: extension);
        debugPrint('✅ [StorageService] Archivos anteriores eliminados');
      } catch (e) {
        debugPrint('⚠️ [StorageService] No había archivos anteriores o error eliminando: $e');
      }
      
      // 1. Procesar imágenes en paralelo
      final processed = await ImageProcessor.processAll(imageBytes);
      
      debugPrint('✅ [StorageService] Imágenes procesadas:');
      debugPrint('   thumbnail size: ${processed.thumbnail.length}');
      debugPrint('   medium size: ${processed.medium.length}');
      debugPrint('   full size: ${processed.full.length}');

      // 2. Upload de las 3 versiones con retry logic
      final thumbPath = 'thumbs/${eventId}_300x300.$extension';
      final mediumPath = 'medium/${eventId}_600x600.$extension';
      final fullPath = '$eventId.$extension';
      
      debugPrint('📤 [StorageService] Paths de upload:');
      debugPrint('   thumbnail: $thumbPath');
      debugPrint('   medium: $mediumPath');
      debugPrint('   full: $fullPath');
      
      // 2. Upload SECUENCIAL para mejor control de errores
      debugPrint('📤 [StorageService] Subiendo thumbnail...');
      final thumbnailUrl = await _uploadWithRetry(
        bucket: 'events',
        path: thumbPath,
        bytes: processed.thumbnail,
      );
      debugPrint('✅ [StorageService] Thumbnail uploaded: $thumbnailUrl');
      
      debugPrint('📤 [StorageService] Subiendo medium...');
      final mediumUrl = await _uploadWithRetry(
        bucket: 'events',
        path: mediumPath,
        bytes: processed.medium,
      );
      debugPrint('✅ [StorageService] Medium uploaded: $mediumUrl');
      
      debugPrint('📤 [StorageService] Subiendo full...');
      final fullUrl = await _uploadWithRetry(
        bucket: 'events',
        path: fullPath,
        bytes: processed.full,
      );
      debugPrint('✅ [StorageService] Full uploaded: $fullUrl');
      
      debugPrint('✅ [StorageService] URLs generadas:');
      debugPrint('   thumbnail: $thumbnailUrl');
      debugPrint('   medium: $mediumUrl');
      debugPrint('   full: $fullUrl');

      return EventImageUrls(
        thumbnailUrl: thumbnailUrl,
        imageUrl: mediumUrl,
        fullImageUrl: fullUrl,
      );
    } catch (e) {
      debugPrint('❌ [StorageService] Error: $e');
      throw EventImageUploadException('Failed to upload event image: $e');
    }
  }

  /// Elimina todas las versiones de una imagen de evento
  /// 
  /// Útil al actualizar o eliminar un evento
  /// No lanza error si los archivos no existen
  Future<void> deleteEventImage({
    required String eventId,
    String extension = 'jpg',
  }) async {
    try {
      // Eliminar las 3 versiones (sin await para hacer en paralelo)
      await Future.wait([
        _deleteFile('events', 'thumbs/${eventId}_300x300.$extension'),
        _deleteFile('events', 'medium/${eventId}_600x600.$extension'),
        _deleteFile('events', '$eventId.$extension'),
      ]);
    } catch (e) {
      // Ignorar errores de archivos no existentes
      if (!e.toString().contains('not found')) {
        throw EventImageUploadException('Failed to delete event image: $e');
      }
    }
  }

  /// Obtiene URL pública de un archivo
  /// 
  /// El CDN de Supabase cachea automáticamente
  String getPublicUrl(String bucket, String path) {
    return _client.storage.from(bucket).getPublicUrl(path);
  }

  // ============================================
  // MÉTODOS PRIVADOS
  // ============================================

  /// Upload con retry logic y timeout
  Future<String> _uploadWithRetry({
    required String bucket,
    required String path,
    required Uint8List bytes,
    int attempt = 1,
  }) async {
    try {
      await _client.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '31536000', // 1 año (inmutable)
              upsert: true, // Sobrescribir si existe
            ),
          ).timeout(_uploadTimeout);

      // 🔥 HARDCODED: Construir URL manualmente SIN usar getPublicUrl()
      const baseUrl = 'https://ebddvgvlsjjrwdxgjqdh.supabase.co/storage/v1/object/public';
      final publicUrl = '$baseUrl/$bucket/$path';
      
      debugPrint('✅ [_uploadWithRetry] URL hardcoded: $publicUrl');
      return publicUrl;
    } catch (e) {
      // Retry si no es el último intento
      if (attempt < _maxRetries) {
        await Future.delayed(Duration(seconds: attempt)); // Backoff exponencial
        return _uploadWithRetry(
          bucket: bucket,
          path: path,
          bytes: bytes,
          attempt: attempt + 1,
        );
      }
      rethrow;
    }
  }

  /// Elimina un archivo del storage
  Future<void> _deleteFile(String bucket, String path) async {
    try {
      await _client.storage.from(bucket).remove([path]);
    } catch (e) {
      // Ignorar errores de archivo no existente
      if (!e.toString().contains('not found')) {
        rethrow;
      }
    }
  }
}

// ============================================
// MODELOS
// ============================================

/// URLs de las versiones de una imagen de evento
class EventImageUrls {
  final String thumbnailUrl; // 300x300
  final String imageUrl; // 600x600
  final String fullImageUrl; // Optimizado full

  const EventImageUrls({
    required this.thumbnailUrl,
    required this.imageUrl,
    required this.fullImageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'thumbnail_url': thumbnailUrl,
      'image_url': imageUrl,
      'full_image_url': fullImageUrl,
    };
  }
}

/// Excepción custom para errores de storage de eventos
class EventImageUploadException implements Exception {
  final String message;

  const EventImageUploadException(this.message);

  @override
  String toString() => 'EventImageUploadException: $message';
}
