import 'package:evio_core/models/event_stats.dart';
import 'package:evio_core/models/ticket_category.dart';
import 'package:evio_core/models/ticket_tier.dart';
import 'package:evio_core/services/supabase_service.dart';
import 'package:evio_core/models/event.dart';
import 'package:flutter/foundation.dart';

class EventRepository {
  final _client = SupabaseService.client;

  // Obtener eventos publicados (para fans)
  Future<List<Event>> getPublishedEvents({
    String? city,
    String? genre,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 20,
    int offset = 0,
  }) async {
    final query = _client.from('events').select();

    // Construimos los filtros como Map
    final filters = <String, Object>{
      'is_published': true,
      'is_archived': false,
    };
    if (city != null) filters['city'] = city;
    if (genre != null) filters['genre'] = genre;

    var builder = query.match(filters);

    // ✅ FILTRO CRÍTICO: Solo eventos futuros (start_datetime >= hoy o fromDate)
    final now = DateTime.now();
    final effectiveFromDate = fromDate != null && fromDate.isAfter(now)
        ? fromDate
        : now;
    builder = builder.gte('start_datetime', effectiveFromDate.toIso8601String());
    if (toDate != null) {
      builder = builder.lte('start_datetime', toDate.toIso8601String());
    }

    final response = await builder
        .order('start_datetime', ascending: true)
        .range(offset, offset + limit - 1);

    return (response as List).map((e) => Event.fromJson(e)).toList();
  }

  // Obtener evento por ID
  Future<Event?> getEventById(String id) async {
    final response = await _client
        .from('events')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Event.fromJson(response);
  }

  // Obtener evento por slug
  Future<Event?> getEventBySlug(String slug) async {
    final response = await _client
        .from('events')
        .select()
        .eq('slug', slug)
        .maybeSingle();

    if (response == null) return null;
    return Event.fromJson(response);
  }

  // Buscar eventos
  Future<List<Event>> searchEvents(String query) async {
    // ✅ Solo eventos futuros
    final now = DateTime.now();
    
    final response = await _client
        .from('events')
        .select()
        .eq('is_published', true)
        .eq('is_archived', false)
        .gte('start_datetime', now.toIso8601String())
        .or(
          'title.ilike.%$query%,main_artist.ilike.%$query%,venue_name.ilike.%$query%',
        )
        .order('start_datetime', ascending: true)
        .limit(20);

    return (response as List).map((e) => Event.fromJson(e)).toList();
  }

  // Obtener eventos del productor (para admin)
  Future<List<Event>> getProducerEvents(String producerId) async {
    final response = await _client
        .from('events')
        .select()
        .eq('producer_id', producerId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => Event.fromJson(e)).toList();
  }

  // Obtener todos los eventos (para admin dashboard)
  Future<List<Event>> getAllEvents({
    String? city,
    String? genre,
    bool? isPublished,
  }) async {
    try {
      debugPrint('🔍 Fetching events from Supabase...');
      var query = _client.from('events').select();

      if (city != null) query = query.eq('city', city);
      if (genre != null) query = query.eq('genre', genre);
      if (isPublished != null) query = query.eq('is_published', isPublished);

      final response = await query.order('start_datetime', ascending: true);
      debugPrint('✅ Got ${(response as List).length} events');

      return (response as List).map((e) => Event.fromJson(e)).toList();
    } catch (e, st) {
      debugPrint('❌ Error fetching events: $e');
      debugPrint('Stack: $st');
      rethrow;
    }
  }

  // Crear evento (producer)
  Future<Event> createEvent(Event event) async {
    final response = await _client
        .from('events')
        .insert(event.toJson())
        .select()
        .single();

    return Event.fromJson(response);
  }

  // Actualizar evento
  Future<Event> updateEvent(Event event) async {
    debugPrint('🔧 Updating event: ${event.id}');

    final updateData = event.toJson();
    updateData.remove('created_at');
    updateData['updated_at'] = DateTime.now().toIso8601String();

    debugPrint('📦 Update data: ${updateData['title']}');

    final response = await _client
        .from('events')
        .update(updateData)
        .eq('id', event.id)
        .select()
        .maybeSingle();

    debugPrint('📥 Response: $response');

    if (response == null) {
      throw Exception('Evento no encontrado: ${event.id}');
    }

    return Event.fromJson(response);
  }

  // Eliminar evento
  Future<void> deleteEvent(String id) async {
    debugPrint('\n🗑️ [EventRepository] ========== INICIO DELETE ==========');
    debugPrint('🗑️ [EventRepository] Event ID: $id');
    
    try {
      // 1. Obtener el evento para acceder a las imágenes
      debugPrint('🗑️ [EventRepository] Paso 1: Obteniendo evento...');
      final event = await getEventById(id);
      debugPrint('🗑️ [EventRepository] Evento obtenido: ${event?.title ?? "null"}');
      
      // 2. Eliminar imágenes de Storage (si existen)
      if (event != null) {
        debugPrint('🗑️ [EventRepository] Paso 2: Eliminando imágenes...');
        
        if (event.imageUrl != null && event.imageUrl!.isNotEmpty) {
          try {
            debugPrint('🗑️ [EventRepository] Eliminando imagen cropeada: ${event.imageUrl}');
            final uri = Uri.parse(event.imageUrl!);
            final pathAfterBucket = uri.path.split('/public/events/').last;
            await _client.storage.from('events').remove([pathAfterBucket]);
            debugPrint('✅ [EventRepository] Imagen cropeada eliminada');
          } catch (e) {
            debugPrint('⚠️ [EventRepository] Error eliminando imagen cropeada: $e');
          }
        } else {
          debugPrint('🗑️ [EventRepository] Sin imagen cropeada para eliminar');
        }
        
        if (event.fullImageUrl != null && event.fullImageUrl!.isNotEmpty) {
          try {
            debugPrint('🗑️ [EventRepository] Eliminando imagen completa: ${event.fullImageUrl}');
            final uri = Uri.parse(event.fullImageUrl!);
            final pathAfterBucket = uri.path.split('/public/events/').last;
            await _client.storage.from('events').remove([pathAfterBucket]);
            debugPrint('✅ [EventRepository] Imagen completa eliminada');
          } catch (e) {
            debugPrint('⚠️ [EventRepository] Error eliminando imagen completa: $e');
          }
        } else {
          debugPrint('🗑️ [EventRepository] Sin imagen completa para eliminar');
        }
      } else {
        debugPrint('⚠️ [EventRepository] Evento no encontrado, continuando con delete...');
      }
      
      // 3. Eliminar evento (las categorías/tiers se eliminan por CASCADE en BD)
      debugPrint('🗑️ [EventRepository] Paso 3: Eliminando registro de BD...');
      final response = await _client.from('events').delete().eq('id', id);
      debugPrint('🗑️ [EventRepository] Response de delete: $response');
      debugPrint('✅ [EventRepository] ========== DELETE EXITOSO ==========\n');
    } catch (e, st) {
      debugPrint('❌ [EventRepository] ========== ERROR EN DELETE ==========');
      debugPrint('❌ [EventRepository] Error: $e');
      debugPrint('❌ [EventRepository] Stack: $st');
      debugPrint('❌ [EventRepository] ==========================================\n');
      rethrow;
    }
  }

  // Publicar/despublicar evento
  Future<Event> setPublished(String id, bool published) async {
    final response = await _client
        .from('events')
        .update({
          'is_published': published,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .select()
        .single();

    return Event.fromJson(response);
  }

  // Archivar evento
  Future<Event> setArchived(String id, bool archived) async {
    final response = await _client
        .from('events')
        .update({
          'is_archived': archived,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .select()
        .single();

    return Event.fromJson(response);
  }

  // Registrar vista (analytics)
  Future<void> recordView(
    String eventId, {
    String? userId,
    String? sessionId,
  }) async {
    await _client.from('views').insert({
      'event_id': eventId,
      'user_id': userId,
      'session_id': sessionId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Obtener ciudades disponibles
  Future<List<String>> getAvailableCities() async {
    final response = await _client
        .from('events')
        .select('city')
        .eq('is_published', true)
        .eq('is_archived', false);

    final cities = (response as List)
        .map((e) => e['city'] as String)
        .toSet()
        .toList();
    cities.sort();
    return cities;
  }

  // Obtener géneros disponibles
  Future<List<String>> getAvailableGenres() async {
    final response = await _client
        .from('events')
        .select('genre')
        .eq('is_published', true)
        .eq('is_archived', false)
        .not('genre', 'is', null);

    final genres = (response as List)
        .where((e) => e['genre'] != null)
        .map((e) => e['genre'] as String)
        .toSet()
        .toList();
    genres.sort();
    return genres;
  }
  // ============ TICKET TYPES ============

  // ============ MÉTODOS LEGACY ELIMINADOS ============
  // Los métodos de TicketType fueron reemplazados por:
  // - saveTicketCategories()
  // - getEventTicketCategories()
  // ============ STATS Y MÉTRICAS ============

  /// Obtener estadísticas de un evento
  /// ⚠️ TEMPORALMENTE DESHABILITADO - Retorna stats vacíos
  Future<EventStats> getEventStats(String eventId) async {
    // TODO: Migrar a nuevo sistema ticket_categories + ticket_tiers
    return EventStats.empty(eventId);
  }

  /// Obtener estadísticas de múltiples eventos (para dashboard)
  /// ⚠️ TEMPORALMENTE DESHABILITADO - Retorna stats vacíos
  Future<Map<String, EventStats>> getMultipleEventStats(
    List<String> eventIds,
  ) async {
    // TODO: Migrar a nuevo sistema
    final stats = <String, EventStats>{};
    for (final id in eventIds) {
      stats[id] = EventStats.empty(id);
    }
    return stats;
  }

  // ============ TICKET CATEGORIES & TIERS (NUEVO SISTEMA) ============

  /// ✅ Helper: Parsear DateTime de forma segura
  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      debugPrint('⚠️ Error parsing datetime: $value - $e');
      return null;
    }
  }

  /// Guardar todas las categorías y tiers de un evento
  /// ✅ Operación segura con backup automático
  Future<void> saveTicketCategories(
    String eventId,
    List<TicketCategory> categories,
  ) async {
    List<TicketCategory>? backup;

    try {
      final now = DateTime.now().toIso8601String();

      // 0. ✅ BACKUP: Guardar categorías existentes antes de borrar
      try {
        backup = await getEventTicketCategories(eventId);
        if (kDebugMode) {
          debugPrint('💾 Backup: ${backup.length} categorías');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ No hay backup disponible (primera vez?)');
        }
        backup = null;
      }

      // 1. Eliminar categorías (los tiers se borran automáticamente por CASCADE)
      await _client
          .from('ticket_categories')
          .delete()
          .eq('event_id', eventId);

      // 2. Insertar nuevas categorías
      if (categories.isEmpty) {
        if (kDebugMode) {
          debugPrint('✅ Todas las categorías eliminadas (vacío intencional)');
        }
        return;
      }

      final categoriesData = categories.map((cat) => {
        'id': cat.id,
        'event_id': eventId,
        'name': cat.name,
        'description': cat.description,
        'max_per_purchase': cat.maxPerPurchase,
        'order_index': cat.orderIndex,
        'created_at': now,
        'updated_at': now,
      }).toList();

      await _client.from('ticket_categories').insert(categoriesData);

      // 3. Insertar tiers de cada categoría
      final allTiers = <Map<String, dynamic>>[];
      for (final category in categories) {
        for (final tier in category.tiers) {
          allTiers.add({
            'id': tier.id,
            'category_id': category.id,
            'name': tier.name,
            'description': tier.description,
            'price': tier.price,
            'quantity': tier.quantity,
            'sold_count': tier.soldCount,
            'order_index': tier.orderIndex,
            'is_active': tier.isActive,
            'sale_starts_at': tier.saleStartsAt?.toIso8601String(),
            'sale_ends_at': tier.saleEndsAt?.toIso8601String(),
            'created_at': now,
            'updated_at': now,
          });
        }
      }

      if (allTiers.isNotEmpty) {
        await _client.from('ticket_tiers').insert(allTiers);
      }

      if (kDebugMode) {
        debugPrint('✅ Guardadas ${categories.length} categorías con ${allTiers.length} tiers');
      }
    } catch (e) {
      debugPrint('❌ Error guardando categorías: $e');
      
      // ✅ RESTORE: Intentar restaurar backup si existe
      if (backup != null && backup.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('🔄 Intentando restaurar backup...');
        }
        try {
          await saveTicketCategories(eventId, backup);
          if (kDebugMode) {
            debugPrint('✅ Backup restaurado exitosamente');
          }
        } catch (restoreError) {
          debugPrint('❌ Error restaurando backup: $restoreError');
        }
      }
      
      rethrow;
    }
  }

  /// Obtener todas las categorías y tiers de un evento
  Future<List<TicketCategory>> getEventTicketCategories(String eventId) async {
    try {
      debugPrint('🔍 [getEventTicketCategories] Buscando categorías para evento: $eventId');
      
      // 1. Obtener categorías
      final categoriesResponse = await _client
          .from('ticket_categories')
          .select()
          .eq('event_id', eventId)
          .order('order_index', ascending: true);

      debugPrint('🔍 [getEventTicketCategories] Categorías encontradas: ${(categoriesResponse as List).length}');

      if (categoriesResponse.isEmpty) {
        debugPrint('⚠️ No hay categorías para este evento');
        return [];
      }

      // 2. Obtener category_ids para buscar tiers
      final categoryIds = (categoriesResponse as List)
          .map((cat) => cat['id'] as String)
          .toList();

      // 3. Obtener todos los tiers de estas categorías
      final tiersResponse = await _client
          .from('ticket_tiers')
          .select()
          .inFilter('category_id', categoryIds)
          .order('order_index', ascending: true);

      debugPrint('🔍 [getEventTicketCategories] Tiers encontrados: ${(tiersResponse as List).length}');

      // 4. Mapear tiers a sus categorías
      final tiersByCategory = <String, List<Map<String, dynamic>>>{};
      for (final tier in tiersResponse as List) {
        final categoryId = tier['category_id'] as String;
        tiersByCategory.putIfAbsent(categoryId, () => []).add(tier);
      }

      // 5. Construir las categorías con sus tiers
      final categories = <TicketCategory>[];
      for (final catData in categoriesResponse as List) {
        final categoryId = catData['id'] as String;
        final tiersData = tiersByCategory[categoryId] ?? [];

        final tiers = tiersData.map((tierData) {
          return TicketTier(
            id: tierData['id'],
            ticketCategoryId: categoryId,
            name: tierData['name'],
            description: tierData['description'],
            price: tierData['price'],
            quantity: tierData['quantity'],
            soldCount: tierData['sold_count'] ?? 0,
            orderIndex: tierData['order_index'],
            isActive: tierData['is_active'] ?? true,
            saleStartsAt: _parseDateTime(tierData['sale_starts_at']),
            saleEndsAt: _parseDateTime(tierData['sale_ends_at']),
            createdAt: _parseDateTime(tierData['created_at']) ?? DateTime.now(),
            updatedAt: _parseDateTime(tierData['updated_at']) ?? DateTime.now(),
          );
        }).toList();

        categories.add(TicketCategory(
          id: categoryId,
          eventId: eventId,
          name: catData['name'],
          description: catData['description'],
          maxPerPurchase: catData['max_per_purchase'],
          orderIndex: catData['order_index'],
          createdAt: _parseDateTime(catData['created_at']) ?? DateTime.now(),
          updatedAt: _parseDateTime(catData['updated_at']) ?? DateTime.now(),
          tiers: tiers,
        ));
      }

      debugPrint('🔍 [getEventTicketCategories] Construidas ${categories.length} categorías');
      
      if (kDebugMode) {
        debugPrint('✅ Cargadas ${categories.length} categorías');
      }
      return categories;
    } catch (e) {
      debugPrint('❌ Error cargando categorías: $e');
      rethrow;
    }
  }
}
