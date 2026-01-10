import 'package:evio_core/models/event_status.dart';
import 'package:evio_core/models/lineup_artist.dart';

class Event {
  final String id;
  final String producerId;
  final String title;
  final String slug;
  final String mainArtist;
  final List<LineupArtist> lineup;
  final DateTime startDatetime;
  final DateTime? endDatetime;
  final String venueName;
  final String address;
  final String city;
  final double? lat;
  final double? lng;
  final String? genre;
  final String? description;
  final String? organizerName;
  final List<String>? features;
  final String? imageUrl;          // Imagen croppeada (cuadrada, para cards)
  final String? thumbnailUrl;      // Thumbnail 300x300 para listas (NUEVO)
  final String? fullImageUrl;      // Imagen completa (ratio original, para hero)
  final String? videoUrl;          // URL de video (YouTube, Vimeo, etc)
  final EventStatus status;
  final bool isPublished;
  final int? totalCapacity;
  final bool showAllTicketTypes;  // ✅ Mostrar todas las tandas o solo las activas
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Event({
    required this.id,
    required this.producerId,
    required this.title,
    required this.slug,
    required this.mainArtist,
    required this.lineup,
    required this.startDatetime,
    this.endDatetime,
    required this.venueName,
    required this.address,
    required this.city,
    this.lat,
    this.lng,
    this.genre,
    this.description,
    this.organizerName,
    this.features,
    this.imageUrl,
    this.thumbnailUrl,
    this.fullImageUrl,
    this.videoUrl,
    required this.status,
    required this.isPublished,
    this.totalCapacity,
    this.showAllTicketTypes = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      producerId: json['producer_id'],
      title: json['title'],
      slug: json['slug'],
      mainArtist: json['main_artist'],
      lineup:
          (json['lineup'] as List?)
              ?.map((e) => LineupArtist.fromJson(e))
              .toList() ??
          [],
      startDatetime: DateTime.parse(json['start_datetime']),
      endDatetime: json['end_datetime'] != null
          ? DateTime.parse(json['end_datetime'])
          : null,
      venueName: json['venue_name'],
      address: json['address'],
      city: json['city'],
      lat: json['lat'] != null ? (json['lat'] as num).toDouble() : null,
      lng: json['lng'] != null ? (json['lng'] as num).toDouble() : null,
      genre: json['genre'],
      description: json['description'],
      organizerName: json['organizer_name'],
      features: (json['features'] as List?)?.map((e) => e.toString()).toList(),
      imageUrl: json['image_url'],
      thumbnailUrl: json['thumbnail_url'],
      fullImageUrl: json['full_image_url'],
      videoUrl: json['video_url'],
      status: EventStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => EventStatus.draft,
      ),
      isPublished: json['is_published'] ?? false,
      totalCapacity: json['total_capacity'],
      showAllTicketTypes: json['show_all_ticket_types'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'producer_id': producerId,
      'title': title,
      'slug': slug,
      'main_artist': mainArtist,
      'lineup': lineup.map((e) => e.toJson()).toList(),
      'start_datetime': startDatetime.toIso8601String(),
      'end_datetime': endDatetime?.toIso8601String(),
      'venue_name': venueName,
      'address': address,
      'city': city,
      'lat': lat,
      'lng': lng,
      'genre': genre,
      'description': description,
      'organizer_name': organizerName,
      'features': features,
      'image_url': imageUrl,
      'thumbnail_url': thumbnailUrl,
      'full_image_url': fullImageUrl,
      'video_url': videoUrl,
      'status': status.name,
      'is_published': isPublished,
      'total_capacity': totalCapacity,
      'show_all_ticket_types': showAllTicketTypes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ============ GETTERS COMPUTADOS ============

  /// Retorna true si el evento ya pasó
  bool get isPast {
    final now = DateTime.now();
    return endDatetime?.isBefore(now) ?? startDatetime.isBefore(now);
  }

  /// Retorna true si el evento está ocurriendo ahora
  bool get isOngoing {
    final now = DateTime.now();
    final start = startDatetime;
    final end = endDatetime ?? startDatetime.add(Duration(hours: 6));
    return now.isAfter(start) && now.isBefore(end);
  }

  /// Cantidad de tickets vendidos (placeholder - requiere join con tickets)
  int get soldCount {
    // TODO: Implementar cuando se agregue relación con tickets
    return 0;
  }

  /// Precio mínimo de las tandas (placeholder - requiere join con ticket_types)
  int? get minPrice {
    // TODO: Implementar cuando se agregue relación con ticket_types
    return null;
  }

  /// Precio máximo de las tandas (placeholder - requiere join con ticket_types)
  int? get maxPrice {
    // TODO: Implementar cuando se agregue relación con ticket_types
    return null;
  }
}
