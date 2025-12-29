// packages/evio_core/lib/models/lineup_artist.dart

class LineupArtist {
  final String name;
  final bool isHeadliner;
  final String? imageUrl; // ✅ AGREGADO para fotos de Spotify

  const LineupArtist({required this.name, this.isHeadliner = false, this.imageUrl});

  factory LineupArtist.fromJson(Map<String, dynamic> json) {
    return LineupArtist(
      name: json['name'] as String,
      isHeadliner: json['is_headliner'] as bool? ?? false,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'is_headliner': isHeadliner, 'image_url': imageUrl};
  }

  LineupArtist copyWith({String? name, bool? isHeadliner, String? imageUrl}) {
    return LineupArtist(
      name: name ?? this.name,
      isHeadliner: isHeadliner ?? this.isHeadliner,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  String toString() => 'LineupArtist(name: $name, isHeadliner: $isHeadliner, imageUrl: $imageUrl)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LineupArtist &&
        other.name == name &&
        other.isHeadliner == isHeadliner &&
        other.imageUrl == imageUrl;
  }

  @override
  int get hashCode => Object.hash(name, isHeadliner, imageUrl);
}
