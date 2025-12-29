import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';
import 'event_provider.dart';
import 'location_provider.dart';

// Estado de búsqueda y filtros
class SearchState {
  final String query;
  final String? producerId;
  final String? venueName;
  final DateTime? date;
  final bool nearbyMode; // ✅ Nuevo: modo eventos cercanos

  const SearchState({
    this.query = '',
    this.producerId,
    this.venueName,
    this.date,
    this.nearbyMode = false,
  });

  SearchState copyWith({
    String? query,
    String? producerId,
    String? venueName,
    DateTime? date,
    bool? nearbyMode,
    bool clearProducer = false,
    bool clearVenue = false,
    bool clearDate = false,
  }) {
    return SearchState(
      query: query ?? this.query,
      producerId: clearProducer ? null : (producerId ?? this.producerId),
      venueName: clearVenue ? null : (venueName ?? this.venueName),
      date: clearDate ? null : (date ?? this.date),
      nearbyMode: nearbyMode ?? this.nearbyMode,
    );
  }

  bool get hasFilters =>
      producerId != null || venueName != null || date != null || nearbyMode;
}

// Notifier para manejar el estado de búsqueda
class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier() : super(const SearchState());

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void setProducer(String? producerId) {
    state = state.copyWith(
      producerId: producerId,
      clearProducer: producerId == null,
    );
  }

  void setVenue(String? venueName) {
    state = state.copyWith(venueName: venueName, clearVenue: venueName == null);
  }

  void setDate(DateTime? date) {
    state = state.copyWith(date: date, clearDate: date == null);
  }

  void setNearbyMode(bool enabled) {
    state = state.copyWith(nearbyMode: enabled);
  }

  void clearFilters() {
    state = const SearchState();
  }
}

// Provider del notifier
final searchNotifierProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
      return SearchNotifier();
    });

// Provider de eventos filtrados
final filteredEventsProvider = FutureProvider<List<Event>>((ref) async {
  final searchState = ref.watch(searchNotifierProvider);
  final allEvents = await ref.watch(eventsProvider.future);

  var filtered = allEvents;

  // Filtrar por query de texto
  if (searchState.query.isNotEmpty) {
    final query = searchState.query.toLowerCase();
    filtered = filtered.where((event) {
      return event.title.toLowerCase().contains(query) ||
          event.city.toLowerCase().contains(query) ||
          event.venueName.toLowerCase().contains(query);
    }).toList();
  }

  // Filtrar por productor
  if (searchState.producerId != null) {
    filtered = filtered
        .where((e) => e.producerId == searchState.producerId)
        .toList();
  }

  // Filtrar por venue
  if (searchState.venueName != null) {
    filtered = filtered
        .where(
          (e) =>
              e.venueName.toLowerCase() == searchState.venueName!.toLowerCase(),
        )
        .toList();
  }

  // Filtrar por fecha
  if (searchState.date != null) {
    final targetDate = DateTime(
      searchState.date!.year,
      searchState.date!.month,
      searchState.date!.day,
    );
    filtered = filtered.where((e) {
      final eventDate = DateTime(e.startDatetime.year, e.startDatetime.month, e.startDatetime.day);
      return eventDate == targetDate;
    }).toList();
  }

  // ✅ Modo eventos cercanos
  if (searchState.nearbyMode) {
    final locationService = ref.read(locationServiceProvider);
    final userLocation = await ref.read(currentLocationProvider.future);
    
    if (userLocation != null) {
      // Filtrar eventos que tengan coordenadas
      filtered = filtered.where((e) => e.lat != null && e.lng != null).toList();
      
      // Calcular distancia y ordenar
      final eventsWithDistance = filtered.map((event) {
        final distance = locationService.calculateDistance(
          startLat: userLocation.latitude,
          startLng: userLocation.longitude,
          endLat: event.lat!,
          endLng: event.lng!,
        );
        return MapEntry(event, distance);
      }).toList();
      
      // Ordenar por distancia (más cerca primero)
      eventsWithDistance.sort((a, b) => a.value.compareTo(b.value));
      
      return eventsWithDistance.map((e) => e.key).toList();
    }
  }

  // Ordenar por fecha (si no está en modo nearby)
  filtered.sort((a, b) => a.startDatetime.compareTo(b.startDatetime));

  return filtered;
});

// Provider para obtener lista única de productores
final producersListProvider = FutureProvider<List<Producer>>((ref) async {
  final repo = ref.watch(producerRepositoryProvider);
  return repo.getAllProducers();
});

// Provider para obtener lista única de venues
final venuesListProvider = FutureProvider<List<String>>((ref) async {
  final allEvents = await ref.watch(eventsProvider.future);
  final venues = allEvents.map((e) => e.venueName).toSet().toList();
  venues.sort();
  return venues;
});
