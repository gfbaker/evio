import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class YouTubeService {
  // Usar la misma API key de Google Maps
  static const String _apiKey = 'AIzaSyDUpkWkGURSCNH5WH9ht0RefV-dMjZKGPQ';

  /// Buscar el video set más popular de un artista
  Future<String?> getArtistTopVideo(String artistName) async {
    try {
      final query = Uri.encodeComponent('$artistName DJ set live');
      
      final response = await http.get(
        Uri.parse(
          'https://www.googleapis.com/youtube/v3/search?'
          'part=snippet&'
          'q=$query&'
          'type=video&'
          'order=viewCount&'
          'maxResults=1&'
          'videoDuration=long&'
          'key=$_apiKey',
        ),
      );

      if (response.statusCode != 200) {
        debugPrint('YouTube search failed: ${response.body}');
        return null;
      }

      final data = json.decode(response.body);
      final items = data['items'] as List?;

      if (items == null || items.isEmpty) {
        debugPrint('No videos found for: $artistName');
        return null;
      }

      // Retornar el video ID
      final videoId = items[0]['id']['videoId'] as String?;
      return videoId;
    } catch (e) {
      debugPrint('Error fetching YouTube video for $artistName: $e');
      return null;
    }
  }

  /// Obtener detalles de un video específico
  Future<Map<String, dynamic>?> getVideoDetails(String videoId) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://www.googleapis.com/youtube/v3/videos?'
          'part=snippet,statistics&'
          'id=$videoId&'
          'key=$_apiKey',
        ),
      );

      if (response.statusCode != 200) {
        return null;
      }

      final data = json.decode(response.body);
      final items = data['items'] as List?;

      if (items == null || items.isEmpty) {
        return null;
      }

      return items[0] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error fetching video details: $e');
      return null;
    }
  }
}
