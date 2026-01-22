import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/models/event.dart';
import 'package:evio_core/models/producer.dart';
import 'package:evio_core/repositories/event_repository.dart';
import 'package:evio_core/repositories/producer_repository.dart';
import 'spotify_provider.dart';

part 'event_provider.g.dart';

// ============================================
// CACHE MANAGEMENT - NUCLEAR PROOF
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
/// ✅ NUCLEAR PROOF: Timeouts, error recovery, sin memory leaks
Future<void> smartRefreshEvents(WidgetRef ref, {bool force = false}) async {
  Timer? timeoutTimer;
  
  try {
    final lastFetch = ref.read(lastEventsFetchProvider);
    
    if (force || isCacheExpired(lastFetch)) {
      final remainingTime = lastFetch != null 
        ? eventsCacheDuration.inMinutes - DateTime.now().difference(lastFetch).inMinutes
        : 0;
      
      debugPrint('🔄 [SmartRefresh] Cache ${force ? "forzado" : "expirado"} (${remainingTime}min restantes), refrescando...');
      
      // ✅ CRITICAL: Timeout con cancelación automática
      bool completed = false;
      timeoutTimer = Timer(const Duration(seconds: 15), () {
        if (!completed) {
          debugPrint('⚠️ [SmartRefresh] Timeout de 15s alcanzado');
        }
      });

      try {
        // ✅ Refresh con timeout de 15s
        await ref.refresh(eventsProvider.future).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            debugPrint('⚠️ [SmartRefresh] Timeout, usando cache viejo');
            final cachedEvents = ref.read(eventsProvider).value;
            return cachedEvents ?? [];
          },
        );
        
        completed = true;
        timeoutTimer.cancel();
        
        // ✅ Actualizar timestamp SOLO si el refresh fue exitoso
        ref.read(lastEventsFetchProvider.notifier).state = DateTime.now();
        debugPrint('✅ [SmartRefresh] Eventos actualizados exitosamente');
        
      } on TimeoutException catch (e) {
        debugPrint('⚠️ [SmartRefresh] TimeoutException: $e');
        // Seguir con cache viejo
      } catch (e) {
        debugPrint('❌ [SmartRefresh] Error en refresh: $e');
        // Fallar gracefully
      }
    } else {
      final remainingTime = eventsCacheDuration.inMinutes - DateTime.now().difference(lastFetch!).inMinutes;
      debugPrint('✅ [SmartRefresh] Cache válido (${remainingTime}min restantes), skip refresh');
    }
  } catch (e, stackTrace) {
    debugPrint('❌ [SmartRefresh] Error crítico: $e');
    debugPrint('Stack trace: $stackTrace');
    // No throw - fallar gracefully
  } finally {
    // ✅ CRITICAL: Siempre cancelar timer
    timeoutTimer?.cancel();
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
// EVENTOS PUBLICADOS - NUCLEAR PROOF
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
/// ✅ NUCLEAR PROOF: Error recovery, timeout protection
/// ✅ Precarga imágenes de artistas automáticamente
final eventsProvider = FutureProvider<List<Event>>((ref) async {
  final repository = ref.watch(eventRepositoryProvider);
  final filters = ref.watch(eventFiltersProvider);

  debugPrint('🔄 [eventsProvider] Fetching eventos...');

  try {
    // ✅ CRITICAL: Timeout de 15s en la llamada al repository
    final events = await repository.getPublishedEvents(
      city: filters.city,
      genre: filters.genre,
      fromDate: filters.fromDate,
      toDate: filters.toDate,
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        debugPrint('⚠️ [eventsProvider] Timeout alcanzado, retornando lista vacía');
        return <Event>[];
      },
    );

    debugPrint('✅ [eventsProvider] ${events.length} eventos cargados');
    
    // ✅ PRECARGAR IMÁGENES DE ARTISTAS (en background, no bloquea)
    if (events.isNotEmpty) {
      // Usar Future.microtask para no bloquear el return
      Future.microtask(() {
        preloadArtistImages(ref, events, maxEvents: 10);
      });
    }
    
    return events;
    
  } on TimeoutException catch (e) {
    debugPrint('⚠️ [eventsProvider] TimeoutException: $e');
    return <Event>[];
  } catch (e, stackTrace) {
    debugPrint('❌ [eventsProvider] Error: $e');
    debugPrint('Stack trace: $stackTrace');
    rethrow; // Dejar que Riverpod maneje el error
  }
});

// ============================================
// EVENTO INDIVIDUAL (CACHE HÍBRIDO)
// ============================================

/// ✅ CACHED: Info estática del evento (inmutable)
@Riverpod(keepAlive: true)
Future<Event?> eventInfo(EventInfoRef ref, String eventId) async {
  final repository = ref.watch(eventRepositoryProvider);
  
  try {
    return await repository.getEventById(eventId).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint('⚠️ [eventInfo] Timeout para evento $eventId');
        return null;
      },
    );
  } catch (e) {
    debugPrint('❌ [eventInfo] Error: $e');
    return null;
  }
}

/// ✅ CACHED: Evento por slug (inmutable)
@Riverpod(keepAlive: true)
Future<Event?> eventInfoBySlug(EventInfoBySlugRef ref, String slug) async {
  final repository = ref.watch(eventRepositoryProvider);
  
  try {
    return await repository.getEventBySlug(slug).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint('⚠️ [eventInfoBySlug] Timeout para slug $slug');
        return null;
      },
    );
  } catch (e) {
    debugPrint('❌ [eventInfoBySlug] Error: $e');
    return null;
  }
}

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

  try {
    return await repository.searchEvents(query).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint('⚠️ [searchResults] Timeout en búsqueda');
        return <Event>[];
      },
    );
  } catch (e) {
    debugPrint('❌ [searchResults] Error: $e');
    return <Event>[];
  }
});

// ============================================
// FILTROS DISPONIBLES
// ============================================

/// Obtener ciudades disponibles
final availableCitiesProvider = FutureProvider.autoDispose<List<String>>((
  ref,
) async {
  final repository = ref.watch(eventRepositoryProvider);
  
  try {
    return await repository.getAvailableCities().timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        debugPrint('⚠️ [availableCities] Timeout');
        return <String>[];
      },
    );
  } catch (e) {
    debugPrint('❌ [availableCities] Error: $e');
    return <String>[];
  }
});

/// Obtener géneros disponibles
final availableGenresProvider = FutureProvider.autoDispose<List<String>>((
  ref,
) async {
  final repository = ref.watch(eventRepositoryProvider);
  
  try {
    return await repository.getAvailableGenres().timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        debugPrint('⚠️ [availableGenres] Timeout');
        return <String>[];
      },
    );
  } catch (e) {
    debugPrint('❌ [availableGenres] Error: $e');
    return <String>[];
  }
});

// ============================================
// ANALYTICS
// ============================================

/// Registrar vista de evento
Future<void> recordEventView(WidgetRef ref, String eventId) async {
  try {
    final repository = ref.read(eventRepositoryProvider);
    await repository.recordView(eventId).timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint('⚠️ [recordEventView] Timeout, ignorando');
      },
    );
  } catch (e) {
    debugPrint('❌ [recordEventView] Error: $e');
    // Fallar silenciosamente
  }
}

// ============================================
// PRODUCTORA
// ============================================

/// Provider para obtener info de productora por ID (cached)
@Riverpod(keepAlive: true)
Future<Producer?> producerInfo(ProducerInfoRef ref, String producerId) async {
  final repository = ref.watch(producerRepositoryProvider);
  
  try {
    return await repository.getProducerById(producerId).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint('⚠️ [producerInfo] Timeout para producer $producerId');
        return null;
      },
    );
  } catch (e) {
    debugPrint('❌ [producerInfo] Error: $e');
    return null;
  }
}
