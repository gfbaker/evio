import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';

// Provider del servicio de YouTube
final youtubeServiceProvider = Provider<YouTubeService>((ref) {
  return YouTubeService();
});

// Provider para obtener video ID de un artista
final artistVideoProvider = FutureProvider.family<String?, String>((
  ref,
  artistName,
) async {
  final youtube = ref.watch(youtubeServiceProvider);
  return youtube.getArtistTopVideo(artistName);
});
