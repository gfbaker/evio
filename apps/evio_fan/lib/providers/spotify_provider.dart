import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:evio_core/evio_core.dart';

// Provider del servicio de Spotify
final spotifyServiceProvider = Provider<SpotifyService>((ref) {
  return SpotifyService();
});

// ============================================
// CACHE DE IMÁGENES DE ARTISTAS
// ============================================

/// Cache en memoria de imágenes de artistas resueltas
/// Key: nombre del artista, Value: URL de imagen (o null si no existe)
final artistImageCacheProvider = StateProvider<Map<String, String?>>((ref) => {});

/// Provider para obtener imagen de un artista específico
/// Primero busca en cache, luego en Spotify
final artistImageProvider = FutureProvider.family<String?, String>((
  ref,
  artistName,
) async {
  // 1. Buscar en cache primero
  final cache = ref.read(artistImageCacheProvider);
  if (cache.containsKey(artistName)) {
    return cache[artistName];
  }
  
  // 2. Buscar en Spotify
  final spotify = ref.watch(spotifyServiceProvider);
  final imageUrl = await spotify.getArtistImageUrl(artistName);
  
  // 3. Guardar en cache
  ref.read(artistImageCacheProvider.notifier).update((state) => {
    ...state,
    artistName: imageUrl,
  });
  
  return imageUrl;
});

// Provider para obtener imágenes de múltiples artistas
final artistImagesProvider = FutureProvider.family<Map<String, String?>, List<String>>((
  ref,
  artistNames,
) async {
  final spotify = ref.watch(spotifyServiceProvider);
  return spotify.getArtistImages(artistNames);
});

// ============================================
// PRECARGA DE IMÁGENES DE ARTISTAS
// ============================================

/// Estado de precarga
class ArtistImagePreloadState {
  final bool isLoading;
  final bool isComplete;
  final int totalArtists;
  final int loadedArtists;

  const ArtistImagePreloadState({
    this.isLoading = false,
    this.isComplete = false,
    this.totalArtists = 0,
    this.loadedArtists = 0,
  });

  ArtistImagePreloadState copyWith({
    bool? isLoading,
    bool? isComplete,
    int? totalArtists,
    int? loadedArtists,
  }) {
    return ArtistImagePreloadState(
      isLoading: isLoading ?? this.isLoading,
      isComplete: isComplete ?? this.isComplete,
      totalArtists: totalArtists ?? this.totalArtists,
      loadedArtists: loadedArtists ?? this.loadedArtists,
    );
  }
}

final artistPreloadStateProvider = StateProvider<ArtistImagePreloadState>(
  (ref) => const ArtistImagePreloadState(),
);

/// Precargar imágenes de artistas para una lista de eventos
/// Solo busca en Spotify los artistas que NO tienen imagen manual
Future<void> preloadArtistImages(
  Ref ref,
  List<Event> events, {
  int maxEvents = 10, // Limitar a los primeros N eventos
}) async {
  if (events.isEmpty) return;

  final cache = ref.read(artistImageCacheProvider);
  final spotify = ref.read(spotifyServiceProvider);

  // 1. Extraer artistas únicos que necesitan Spotify
  final artistsNeedingSpotify = <String>{};
  final eventsToProcess = events.take(maxEvents);

  for (final event in eventsToProcess) {
    for (final artist in event.lineup) {
      // Solo buscar en Spotify si NO tiene imagen manual
      final hasManualImage = artist.imageUrl != null && artist.imageUrl!.isNotEmpty;
      final notInCache = !cache.containsKey(artist.name);
      
      if (!hasManualImage && notInCache) {
        artistsNeedingSpotify.add(artist.name);
      }
    }
  }

  if (artistsNeedingSpotify.isEmpty) {
    debugPrint('✅ [Preload] Todos los artistas ya tienen imagen o están en cache');
    ref.read(artistPreloadStateProvider.notifier).state = ArtistImagePreloadState(
      isComplete: true,
      totalArtists: 0,
      loadedArtists: 0,
    );
    return;
  }

  debugPrint('🎵 [Preload] Precargando ${artistsNeedingSpotify.length} artistas de Spotify...');

  // Actualizar estado
  ref.read(artistPreloadStateProvider.notifier).state = ArtistImagePreloadState(
    isLoading: true,
    totalArtists: artistsNeedingSpotify.length,
    loadedArtists: 0,
  );

  // 2. Buscar imágenes en Spotify (batch)
  try {
    final results = await spotify.getArtistImages(
      artistsNeedingSpotify.toList(),
    ).timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        debugPrint('⚠️ [Preload] Timeout buscando imágenes de artistas');
        return <String, String?>{};
      },
    );

    // 3. Guardar en cache
    ref.read(artistImageCacheProvider.notifier).update((state) => {
      ...state,
      ...results,
    });

    debugPrint('✅ [Preload] ${results.length} imágenes de artistas cargadas');

    // 4. Precargar las imágenes en el cache de red (CachedNetworkImage)
    int preloadedCount = 0;
    for (final entry in results.entries) {
      if (entry.value != null) {
        try {
          // Solo precalentar el cache, sin esperar
          CachedNetworkImageProvider(entry.value!).resolve(ImageConfiguration.empty);
          preloadedCount++;
        } catch (e) {
          // Ignorar errores individuales
        }
      }
    }

    debugPrint('✅ [Preload] $preloadedCount imágenes precacheadas en red');

    ref.read(artistPreloadStateProvider.notifier).state = ArtistImagePreloadState(
      isLoading: false,
      isComplete: true,
      totalArtists: artistsNeedingSpotify.length,
      loadedArtists: results.length,
    );

  } catch (e) {
    debugPrint('❌ [Preload] Error precargando artistas: $e');
    ref.read(artistPreloadStateProvider.notifier).state = ArtistImagePreloadState(
      isLoading: false,
      isComplete: true,
      totalArtists: artistsNeedingSpotify.length,
      loadedArtists: 0,
    );
  }
}
