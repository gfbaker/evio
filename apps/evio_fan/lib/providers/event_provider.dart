import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/models/event.dart';
import 'package:evio_core/repositories/event_repository.dart';
import 'package:evio_core/repositories/producer_repository.dart';

part 'event_provider.g.dart';

// ============================================
// CACHE MANAGEMENT
// ============================================

/// Timestamp del último fetch de eventos (para TTL)
final lastEventsFetchProvider = StateProvider<DateTime?>((ref) => null);

/// Duración del cache (5 minutos)
const eventsCacheDuration = Duration(minutes: 5);

/// Helper: Verificar si el cache expiró
bool isCacheExpired(DateTime? lastFetch) {
  if (lastFetch == null) return true;
  final elapsed = DateTime.now().difference(lastFetch);
  return elapsed > eventsCacheDuration;
}

/// Helper: Refrescar eventos SOLO si es necesario
Future<void> smartRefreshEvents(WidgetRef ref, {bool force = false}) async {
  try {
    final lastFetch = ref.read(lastEventsFetchProvider);
    
    if (force || isCacheExpired(lastFetch)) {
      final remainingTime = lastFetch != null 
        ? eventsCacheDuration.inMinutes - DateTime.now().difference(lastFetch).inMinutes
        : 0;
      
      debugPrint('🔄 [SmartRefresh] Cache ${force ? "forzado" : "expirado"} (${remainingTime}min restantes), refrescando...');
      
      // ✅ Refresh con timeout de 10s
      await ref.refresh(eventsProvider.future).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⚠️ [SmartRefresh] Timeout, usando cache viejo');
          return ref.read(eventsProvider).value ?? [];
        },
      );
      
      // ✅ Actualizar timestamp SOLO si el refresh fue exitoso
      ref.read(lastEventsFetchProvider.notifier).state = DateTime.now();
      debugPrint('✅ [SmartRefresh] Eventos actualizados');
    } else {
      final remainingTime = eventsCacheDuration.inMinutes - DateTime.now().difference(lastFetch!).inMinutes;
      debugPrint('✅ [SmartRefresh] Cache válido (${remainingTime}min restantes), skip refresh');
    }
  } catch (e) {
    debugPrint('❌ [SmartRefresh] Error: $e');
    // No throw - fallar gracefully
  }
}

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

/// Provider de eventos con filtros (CACHED - keepAlive)
final eventsProvider = FutureProvider<List<Event>>((ref) async {
  final repository = ref.watch(eventRepositoryProvider);
  final filters = ref.watch(eventFiltersProvider);

  debugPrint('🔄 [eventsProvider] Fetching eventos...');

  final events = await repository.getPublishedEvents(
    city: filters.city,
    genre: filters.genre,
    fromDate: filters.fromDate,
    toDate: filters.toDate,
  );

  debugPrint('✅ [eventsProvider] ${events.length} eventos cargados');
  return events;
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
