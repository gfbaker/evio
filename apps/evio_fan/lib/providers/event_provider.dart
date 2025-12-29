import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/models/event.dart';
import 'package:evio_core/repositories/event_repository.dart';
import 'package:evio_core/repositories/producer_repository.dart';

part 'event_provider.g.dart';

// ============================================
// REPOSITORY PROVIDER
// ============================================

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository();
});

final producerRepositoryProvider = Provider<ProducerRepository>((ref) {
  return ProducerRepository();
});

// ============================================
// EVENTOS PUBLICADOS
// ============================================

/// Clase para filtros de eventos
class EventFilters {
  final String? city;
  final String? genre;
  final DateTime? fromDate;
  final DateTime? toDate;

  const EventFilters({this.city, this.genre, this.fromDate, this.toDate});

  EventFilters copyWith({
    String? city,
    String? genre,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return EventFilters(
      city: city ?? this.city,
      genre: genre ?? this.genre,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
    );
  }

  static const empty = EventFilters();
}

/// Notifier para manejar filtros
class EventFiltersNotifier extends Notifier<EventFilters> {
  @override
  EventFilters build() => EventFilters.empty;

  void setCity(String? city) {
    state = state.copyWith(city: city);
  }

  void setGenre(String? genre) {
    state = state.copyWith(genre: genre);
  }

  void setDateRange(DateTime? from, DateTime? to) {
    state = state.copyWith(fromDate: from, toDate: to);
  }

  void reset() {
    state = EventFilters.empty;
  }
}

/// Provider de filtros actuales
final eventFiltersProvider =
    NotifierProvider<EventFiltersNotifier, EventFilters>(
      EventFiltersNotifier.new,
    );

/// Provider de eventos con filtros
final eventsProvider = FutureProvider.autoDispose<List<Event>>((ref) async {
  final repository = ref.watch(eventRepositoryProvider);
  final filters = ref.watch(eventFiltersProvider);

  return repository.getPublishedEvents(
    city: filters.city,
    genre: filters.genre,
    fromDate: filters.fromDate,
    toDate: filters.toDate,
  );
});

// ============================================
// EVENTO INDIVIDUAL (CACHE HÍBRIDO)
// ============================================

/// ✅ CACHED: Info estática del evento (inmutable)
@Riverpod(keepAlive: true)
Future<Event?> eventInfo(EventInfoRef ref, String eventId) async {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.getEventById(eventId);
}

/// ❌ LEGACY: Usar eventInfo en lugar de este
@Deprecated('Use eventInfo for cached static data')
final eventByIdProvider = FutureProvider.family.autoDispose<Event?, String>((
  ref,
  eventId,
) async {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.getEventById(eventId);
});

/// ✅ CACHED: Evento por slug (inmutable)
@Riverpod(keepAlive: true)
Future<Event?> eventInfoBySlug(EventInfoBySlugRef ref, String slug) async {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.getEventBySlug(slug);
}

/// ❌ LEGACY: Usar eventInfoBySlug en lugar de este
@Deprecated('Use eventInfoBySlug for cached static data')
final eventBySlugProvider = FutureProvider.family.autoDispose<Event?, String>((
  ref,
  slug,
) async {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.getEventBySlug(slug);
});

// ============================================
// BÚSQUEDA
// ============================================

/// Notifier para query de búsqueda
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

/// Provider de query de búsqueda
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

/// Provider de resultados de búsqueda
final searchResultsProvider = FutureProvider.autoDispose<List<Event>>((
  ref,
) async {
  final repository = ref.watch(eventRepositoryProvider);
  final query = ref.watch(searchQueryProvider);

  if (query.isEmpty) return [];

  return repository.searchEvents(query);
});

// ============================================
// FILTROS DISPONIBLES
// ============================================

/// Obtener ciudades disponibles
final availableCitiesProvider = FutureProvider.autoDispose<List<String>>((
  ref,
) async {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.getAvailableCities();
});

/// Obtener géneros disponibles
final availableGenresProvider = FutureProvider.autoDispose<List<String>>((
  ref,
) async {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.getAvailableGenres();
});

// ============================================
// LIKES
// ============================================

/// Provider para manejar likes (TODO: implementar repository method)
final eventLikeProvider = FutureProvider.family.autoDispose<bool, String>((
  ref,
  eventId,
) async {
  // TODO: Implementar hasLiked en EventRepository
  return false;
});

// ============================================
// ANALYTICS
// ============================================

/// Registrar vista de evento
Future<void> recordEventView(WidgetRef ref, String eventId) async {
  final repository = ref.read(eventRepositoryProvider);
  await repository.recordView(eventId);
}
