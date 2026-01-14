import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Cache Manager personalizado para imágenes de eventos
/// ✅ Configurado para NO hacer reintentos infinitos
class EventImageCacheManager {
  static const key = 'evio_event_images';
  
  static CacheManager get instance => CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 7), // 7 días de caché
      maxNrOfCacheObjects: 200, // Máximo 200 imágenes
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(), // Sin reintentos automáticos
    ),
  );
}
