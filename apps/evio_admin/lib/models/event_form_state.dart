import 'package:flutter/foundation.dart';
import 'package:evio_core/evio_core.dart';
import '../widgets/event_form/form_poster_card.dart';

@immutable
class EventFormState {
  final String title;
  final String mainArtist;
  final String? genre;
  final String? description;
  final DateTime startDatetime;
  final DateTime? endDatetime;
  final String venueName;
  final String address;
  final String city;
  final double? lat;
  final double? lng;
  final String? organizerName;
  final int? totalCapacity;
  final List<LineupArtist> lineup;
  final List<TicketCategory> ticketCategories;
  final List<String> features;
  final Uint8List? imageBytes;        // Imagen croppeada
  final String? imageUrl;             // URL imagen croppeada
  final Uint8List? fullImageBytes;    // Imagen completa (opcional)
  final String? fullImageUrl;         // URL imagen completa
  final String? videoUrl;             // URL del video
  final ImageType imageType;          // Tipo de imagen seleccionado
  final EventStatus status;
  final bool isPublished;
  final bool showAllTicketTypes;      // ✅ Mostrar todas las tandas o solo activas
  final bool isSaving;
  final String? errorMessage;

  const EventFormState({
    required this.title,
    required this.mainArtist,
    this.genre,
    this.description,
    required this.startDatetime,
    this.endDatetime,
    required this.venueName,
    required this.address,
    required this.city,
    this.lat,
    this.lng,
    this.organizerName,
    this.totalCapacity,
    required this.lineup,
    required this.ticketCategories,
    required this.features,
    this.imageBytes,
    this.imageUrl,
    this.fullImageBytes,
    this.fullImageUrl,
    this.videoUrl,
    required this.imageType,
    required this.status,
    required this.isPublished,
    this.showAllTicketTypes = false,
    required this.isSaving,
    this.errorMessage,
  });

  factory EventFormState.empty() {
    return EventFormState(
      title: '',
      mainArtist: '',
      genre: null,
      description: null,
      startDatetime: DateTime.now().add(Duration(days: 7)),
      endDatetime: null,
      venueName: '',
      address: '',
      city: '',
      lat: null,
      lng: null,
      organizerName: null,
      totalCapacity: null,
      lineup: [],
      ticketCategories: [],
      features:[],
      imageBytes: null,
      imageUrl: null,
      fullImageBytes: null,
      fullImageUrl: null,
      videoUrl: null,
      imageType: ImageType.croppedHero,
      status: EventStatus.draft,
      isPublished: false,
      showAllTicketTypes: false,
      isSaving: false,
      errorMessage: null,
    );
  }

  factory EventFormState.fromEvent(Event event) {
    return EventFormState(
      title: event.title,
      mainArtist: event.mainArtist,
      genre: event.genre,
      description: event.description,
      startDatetime: event.startDatetime,
      endDatetime: event.endDatetime,
      venueName: event.venueName,
      address: event.address,
      city: event.city,
      lat: event.lat,
      lng: event.lng,
      organizerName: event.organizerName,
      totalCapacity: event.totalCapacity,
      lineup: event.lineup,
      ticketCategories: [], // TODO: Load from DB
      features: event.features ?? [],
      imageBytes: null,
      imageUrl: event.imageUrl,
      fullImageBytes: null,
      fullImageUrl: event.fullImageUrl,
      videoUrl: event.videoUrl,
      imageType: event.fullImageUrl != null ? ImageType.fullFlyer : ImageType.croppedHero,
      status: event.status,
      isPublished: event.isPublished,
      showAllTicketTypes: event.showAllTicketTypes,
      isSaving: false,
      errorMessage: null,
    );
  }

  bool get isValid {
    // Si es BORRADOR → No validar nada (siempre válido)
    if (status == EventStatus.draft) {
      return true;
    }

    // Si es PRÓXIMO → Validar campos obligatorios
    if (status == EventStatus.upcoming) {
      final hasTicketsConfigured = ticketCategories.isNotEmpty &&
          ticketCategories.any((cat) => cat.tiers.isNotEmpty);
      
      return title.isNotEmpty &&
          mainArtist.isNotEmpty &&
          venueName.isNotEmpty &&
          city.isNotEmpty &&
          lineup.isNotEmpty &&
          hasTicketsConfigured &&
          (imageBytes != null || (imageUrl != null && imageUrl!.isNotEmpty));
    }

    // CANCELADO → Solo título requerido
    if (status == EventStatus.cancelled) {
      return title.isNotEmpty;
    }

    return false;
  }

  List<String> get missingFields {
    if (status == EventStatus.draft) {
      return [];
    }

    final missing = <String>[];

    if (title.isEmpty) missing.add('Nombre del evento');
    if (mainArtist.isEmpty) missing.add('Artista principal');
    if (venueName.isEmpty) missing.add('Ubicación');
    if (city.isEmpty) missing.add('Ciudad');
    if (lineup.isEmpty) missing.add('Line-up');
    
    // Validar que haya categorías CON tiers
    final hasTicketsConfigured = ticketCategories.isNotEmpty &&
        ticketCategories.any((cat) => cat.tiers.isNotEmpty);
    if (!hasTicketsConfigured) {
      missing.add('Categorías de tickets con al menos un tier configurado');
    }
    
    if (imageBytes == null && (imageUrl == null || imageUrl!.isEmpty)) {
      missing.add('Imagen del evento');
    }

    return missing;
  }

  EventFormState copyWith({
    String? title,
    String? mainArtist,
    String? genre,
    String? description,
    DateTime? startDatetime,
    DateTime? endDatetime,
    String? venueName,
    String? address,
    String? city,
    double? lat,
    double? lng,
    String? organizerName,
    String? contactPhone,
    int? totalCapacity,
    List<LineupArtist>? lineup,
    List<TicketCategory>? ticketCategories,
    List<String>? features,
    Uint8List? imageBytes,
    String? imageUrl,
    Uint8List? fullImageBytes,
    String? fullImageUrl,
    String? videoUrl,
    ImageType? imageType,
    EventStatus? status,
    bool? isPublished,
    bool? showAllTicketTypes,
    bool? isSaving,
    String? errorMessage,
  }) {
    return EventFormState(
      title: title ?? this.title,
      mainArtist: mainArtist ?? this.mainArtist,
      genre: genre ?? this.genre,
      description: description ?? this.description,
      startDatetime: startDatetime ?? this.startDatetime,
      endDatetime: endDatetime ?? this.endDatetime,
      venueName: venueName ?? this.venueName,
      address: address ?? this.address,
      city: city ?? this.city,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      organizerName: organizerName ?? this.organizerName,
      totalCapacity: totalCapacity ?? this.totalCapacity,
      lineup: lineup ?? this.lineup,
      ticketCategories: ticketCategories ?? this.ticketCategories,
      features: features ?? this.features,
      imageBytes: imageBytes ?? this.imageBytes,
      imageUrl: imageUrl ?? this.imageUrl,
      fullImageBytes: fullImageBytes ?? this.fullImageBytes,
      fullImageUrl: fullImageUrl ?? this.fullImageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      imageType: imageType ?? this.imageType,
      status: status ?? this.status,
      isPublished: isPublished ?? this.isPublished,
      showAllTicketTypes: showAllTicketTypes ?? this.showAllTicketTypes,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
