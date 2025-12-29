import 'dart:convert';
import 'package:http/http.dart' as http;

class SpotifyService {
  static const String _clientId = 'f87d0df3e9c7452d9e5499c16bc8fa6b';
  static const String _clientSecret = '192c70a83f9e4d22bcece69a0d0af021';
  
  String? _accessToken;
  DateTime? _tokenExpiry;

  /// Obtener token de acceso (Client Credentials Flow)
  Future<String> _getAccessToken() async {
    // Si ya tenemos un token válido, retornarlo
    if (_accessToken != null && 
        _tokenExpiry != null && 
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken!;
    }

    // Solicitar nuevo token
    final credentials = base64Encode(utf8.encode('$_clientId:$_clientSecret'));
    
    final response = await http.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {'grant_type': 'client_credentials'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _accessToken = data['access_token'];
      
      // El token expira en 3600 segundos (1 hora)
      final expiresIn = data['expires_in'] as int;
      _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60));
      
      return _accessToken!;
    } else {
      throw Exception('Failed to get Spotify access token: ${response.body}');
    }
  }

  /// Buscar artista y obtener imagen
  Future<String?> getArtistImageUrl(String artistName) async {
    try {
      final token = await _getAccessToken();
      
      // Buscar artista
      final searchResponse = await http.get(
        Uri.parse(
          'https://api.spotify.com/v1/search?q=${Uri.encodeComponent(artistName)}&type=artist&limit=1',
        ),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (searchResponse.statusCode != 200) {
        print('Spotify search failed: ${searchResponse.body}');
        return null;
      }

      final searchData = json.decode(searchResponse.body);
      final artists = searchData['artists']['items'] as List;

      if (artists.isEmpty) {
        print('No artist found for: $artistName');
        return null;
      }

      // Obtener la imagen del primer resultado
      final artist = artists[0];
      final images = artist['images'] as List?;

      if (images == null || images.isEmpty) {
        print('No images found for: $artistName');
        return null;
      }

      // Retornar la imagen de mejor calidad (primera en la lista)
      return images[0]['url'] as String?;
    } catch (e) {
      print('Error fetching Spotify artist image for $artistName: $e');
      return null;
    }
  }

  /// Buscar múltiples artistas en batch (más eficiente)
  Future<Map<String, String?>> getArtistImages(List<String> artistNames) async {
    final Map<String, String?> results = {};
    
    for (final name in artistNames) {
      results[name] = await getArtistImageUrl(name);
      // Pequeño delay para no saturar la API
      await Future.delayed(Duration(milliseconds: 100));
    }
    
    return results;
  }
}
