import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';
import 'auth_provider.dart';

// ============================================
// REPOSITORY PROVIDER
// ============================================

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  return TicketRepository();
});

// ============================================
// MIS TICKETS (WALLET)
// ============================================

/// Tickets activos (válidos, no usados, futuros) - CACHED
final myActiveTicketsProvider = FutureProvider<List<Ticket>>((ref) async {
  // ✅ Esperar auth
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  
  debugPrint('🔄 [myActiveTicketsProvider] Fetching tickets...');
  final repository = ref.watch(ticketRepositoryProvider);
  
  // ✅ Timeout de 15s para evitar cuelgues
  final tickets = await repository
      .getMyTickets(includeUsed: false, includePast: false)
      .timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Timeout al cargar tickets'),
      );
  
  debugPrint('✅ [myActiveTicketsProvider] ${tickets.length} tickets cargados');
  return tickets;
});

/// Historial completo de tickets
final myTicketHistoryProvider = FutureProvider.autoDispose<List<Ticket>>((
  ref,
) async {
  final repository = ref.watch(ticketRepositoryProvider);
  return repository
      .getMyTickets(includeUsed: true, includePast: true)
      .timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Timeout al cargar historial'),
      );
});

/// Ticket individual por ID
final ticketByIdProvider = FutureProvider.family.autoDispose<Ticket?, String>((
  ref,
  ticketId,
) async {
  final repository = ref.watch(ticketRepositoryProvider);
  return repository
      .getTicketById(ticketId)
      .timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout al cargar ticket'),
      );
});

// ============================================
// SISTEMA DE TICKETS: CATEGORÍAS + TIERS
// ============================================

/// Categorías con tiers de un evento (CACHED - keepAlive)
final eventTicketCategoriesProvider = FutureProvider.family
    <List<TicketCategory>, String>((ref, eventId) async {
      debugPrint('🔄 [eventTicketCategoriesProvider] Fetching tickets de $eventId...');
      final eventRepo = EventRepository();
      final categories = await eventRepo.getEventTicketCategories(eventId);
      debugPrint('✅ [eventTicketCategoriesProvider] ${categories.length} categorías cargadas');
      return categories;
    });

/// Precio mínimo de un evento (para mostrar en cards)
final eventMinPriceProvider = FutureProvider.family
    .autoDispose<int?, String>((ref, eventId) async {
      final eventRepo = EventRepository();
      final categories = await eventRepo.getEventTicketCategories(eventId);
      
      // Aplanar todos los tiers
      final allTiers = categories.expand((c) => c.tiers).toList();
      
      // Solo considerar tiers activos
      final activeTiers = allTiers.where((t) => t.isActive).toList();
      if (activeTiers.isEmpty) return null;
      
      final prices = activeTiers.map((t) => t.price).toList();
      return prices.reduce((a, b) => a < b ? a : b);
    });

/// Categorías filtradas para mostrar al usuario (CACHED - keepAlive)
/// - Solo tiers activos o sold out (oculta inactivos "esperando")
/// - Ordena: disponibles arriba, sold out abajo
final filteredTicketCategoriesProvider = FutureProvider.family
    <List<TicketCategory>, String>((ref, eventId) async {
      final eventRepo = EventRepository();
      
      // Cargar evento y categorías en paralelo
      final results = await Future.wait([
        eventRepo.getEventById(eventId),
        eventRepo.getEventTicketCategories(eventId),
      ]);
      
      final event = results[0] as Event?;
      final allCategories = results[1] as List<TicketCategory>;
      
      if (event == null) return [];
      
      // Filtrar y ordenar tiers dentro de cada categoría
      final filteredCategories = allCategories.map((category) {
        // ✅ Solo mostrar tiers activos o sold out
        // ❌ Ocultar tiers inactivos que no están agotados
        final visibleTiers = category.tiers.where((tier) {
          return tier.isActive || tier.isSoldOut;
        }).toList();
        
        // ✅ Ordenar: disponibles primero, sold out al final
        visibleTiers.sort((a, b) {
          // Prioridad 1: Disponibles (isActive && !isSoldOut)
          final aAvailable = a.isActive && !a.isSoldOut;
          final bAvailable = b.isActive && !b.isSoldOut;
          
          if (aAvailable && !bAvailable) return -1; // a va primero
          if (!aAvailable && bAvailable) return 1;  // b va primero
          
          // Prioridad 2: Si ambos tienen el mismo estado, mantener orderIndex
          return a.orderIndex.compareTo(b.orderIndex);
        });
        
        return category.copyWith(tiers: visibleTiers);
      }).where((cat) => cat.tiers.isNotEmpty) // Solo categorías con tiers visibles
        .toList();
      
      return filteredCategories;
    });
