import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';

// Provider del servicio de Spotify
final spotifyServiceProvider = Provider<SpotifyService>((ref) {
  return SpotifyService();
});

// Provider para obtener imagen de un artista específico
final artistImageProvider = FutureProvider.family<String?, String>((
  ref,
  artistName,
) async {
  final spotify = ref.watch(spotifyServiceProvider);
  return spotify.getArtistImageUrl(artistName);
});

// Provider para obtener imágenes de múltiples artistas
final artistImagesProvider = FutureProvider.family<Map<String, String?>, List<String>>((
  ref,
  artistNames,
) async {
  final spotify = ref.watch(spotifyServiceProvider);
  return spotify.getArtistImages(artistNames);
});
