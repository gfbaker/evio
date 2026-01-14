import 'package:flutter/foundation.dart';
import 'package:evio_core/evio_core.dart';

/// Utilidad para diagnosticar y reparar URLs de imágenes
class ImageUrlValidator {
  static const String supabaseStorageUrl = 
    'https://ebddvgvlsjjrwdxgjqdh.supabase.co/storage/v1/object/public/events/';

  /// Valida si una URL de imagen es válida
  static bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    
    // Debe ser HTTPS
    if (!url.startsWith('https://')) return false;
    
    // Debe apuntar a Supabase Storage
    if (!url.contains('.supabase.co/storage/v1/object/public/')) return false;
    
    // Debe tener una extensión de imagen válida
    final validExtensions = ['.jpg', '.jpeg', '.png', '.webp', '.gif'];
    final hasValidExtension = validExtensions.any((ext) => 
      url.toLowerCase().contains(ext)
    );
    
    return hasValidExtension;
  }

  /// Construye URL de thumbnail a partir de URL de imagen
  static String? buildThumbnailUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    
    try {
      // Si ya es thumbnail, retornar
      if (imageUrl.contains('/thumbs/')) return imageUrl;
      
      // Reemplazar /medium/ por /thumbs/
      if (imageUrl.contains('/medium/')) {
        return imageUrl.replaceAll('/medium/', '/thumbs/');
      }
      
      // Construir desde cero si no tiene formato esperado
      final filename = imageUrl.split('/').last.split('?').first;
      return '${supabaseStorageUrl}thumbs/$filename';
    } catch (e) {
      debugPrint('❌ Error building thumbnail URL: $e');
      return null;
    }
  }

  /// Repara URLs de un evento
  static Map<String, String?> repairEventUrls(Event event) {
    final repairs = <String, String?>{};
    
    // Validar image_url
    if (!isValidImageUrl(event.imageUrl)) {
      debugPrint('⚠️ Invalid image_url for event: ${event.title}');
      repairs['image_url'] = null;
    }
    
    // Reparar thumbnail_url si falta
    if (event.thumbnailUrl == null || !isValidImageUrl(event.thumbnailUrl)) {
      final repairedThumb = buildThumbnailUrl(event.imageUrl);
      if (repairedThumb != null) {
        debugPrint('🔧 Repaired thumbnail_url for event: ${event.title}');
        repairs['thumbnail_url'] = repairedThumb;
      }
    }
    
    // Usar image_url como fallback para full_image_url
    if (event.fullImageUrl == null || !isValidImageUrl(event.fullImageUrl)) {
      if (isValidImageUrl(event.imageUrl)) {
        debugPrint('🔧 Using image_url as full_image_url for: ${event.title}');
        repairs['full_image_url'] = event.imageUrl;
      }
    }
    
    return repairs;
  }

  /// Ejecuta diagnóstico completo de todos los eventos
  static Future<void> diagnoseAllEvents() async {
    debugPrint('🔍 Starting image URL diagnosis...');
    
    try {
      final eventRepo = EventRepository();
      final events = await eventRepo.getAllEvents();
      
      int validCount = 0;
      int invalidCount = 0;
      int repairedCount = 0;
      
      for (final event in events) {
        final isValid = isValidImageUrl(event.imageUrl) &&
                       isValidImageUrl(event.thumbnailUrl);
        
        if (isValid) {
          validCount++;
        } else {
          invalidCount++;
          final repairs = repairEventUrls(event);
          if (repairs.isNotEmpty) {
            repairedCount++;
            debugPrint('📝 Event: ${event.title}');
            debugPrint('   Current image_url: ${event.imageUrl}');
            debugPrint('   Current thumbnail_url: ${event.thumbnailUrl}');
            debugPrint('   Suggested repairs: $repairs');
          }
        }
      }
      
      debugPrint('');
      debugPrint('✅ Diagnosis complete:');
      debugPrint('   ✅ Valid: $validCount events');
      debugPrint('   ⚠️  Invalid: $invalidCount events');
      debugPrint('   🔧 Can be repaired: $repairedCount events');
      debugPrint('');
      
    } catch (e, stack) {
      debugPrint('❌ Diagnosis failed: $e');
      debugPrint('Stack: $stack');
    }
  }
}
