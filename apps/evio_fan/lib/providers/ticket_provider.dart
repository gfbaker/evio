import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';

// ============================================
// REPOSITORY PROVIDER
// ============================================

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  return TicketRepository();
});

// ============================================
// MIS TICKETS (WALLET)
// ============================================

/// Tickets activos (válidos, no usados, futuros)
final myActiveTicketsProvider = FutureProvider.autoDispose<List<Ticket>>((
  ref,
) async {
  final repository = ref.watch(ticketRepositoryProvider);
  return repository.getMyTickets(includeUsed: false, includePast: false);
});

/// Historial completo de tickets
final myTicketHistoryProvider = FutureProvider.autoDispose<List<Ticket>>((
  ref,
) async {
  final repository = ref.watch(ticketRepositoryProvider);
  return repository.getMyTickets(includeUsed: true, includePast: true);
});

/// Ticket individual por ID
final ticketByIdProvider = FutureProvider.family.autoDispose<Ticket?, String>((
  ref,
  ticketId,
) async {
  final repository = ref.watch(ticketRepositoryProvider);
  return repository.getTicketById(ticketId);
});

// ============================================
// TIPOS DE TICKETS (PARA COMPRA)
// ============================================

/// Tipos de tickets de un evento
final ticketTypesProvider = FutureProvider.family
    .autoDispose<List<TicketType>, String>((ref, eventId) async {
      final repository = ref.watch(ticketRepositoryProvider);
      return repository.getTicketTypes(eventId);
    });

/// Tipos de tickets disponibles (con stock y en venta)
final availableTicketTypesProvider = FutureProvider.family
    .autoDispose<List<TicketType>, String>((ref, eventId) async {
      final repository = ref.watch(ticketRepositoryProvider);
      return repository.getAvailableTicketTypes(eventId);
    });

// ✅ Precio mínimo de un evento (para mostrar en cards)
final eventMinPriceProvider = FutureProvider.family
    .autoDispose<int?, String>((ref, eventId) async {
      final repository = ref.watch(ticketRepositoryProvider);
      final ticketTypes = await repository.getTicketTypes(eventId);
      
      // Solo considerar tandas activas para el precio mínimo
      final activeTickets = ticketTypes.where((t) => t.isActive).toList();
      if (activeTickets.isEmpty) return null;
      
      final prices = activeTickets.map((t) => t.price).toList();
      return prices.reduce((a, b) => a < b ? a : b);
    });

// ✅ Tipos de tickets filtrados según configuración del evento
final filteredTicketTypesProvider = FutureProvider.family
    .autoDispose<List<TicketType>, String>((ref, eventId) async {
      final repository = ref.watch(ticketRepositoryProvider);
      final eventRepo = EventRepository();
      
      // Cargar evento y tandas en paralelo
      final results = await Future.wait([
        eventRepo.getEventById(eventId),
        repository.getTicketTypes(eventId),
      ]);
      
      final event = results[0] as Event?;
      final allTickets = results[1] as List<TicketType>;
      
      if (event == null) return [];
      
      // Si showAllTicketTypes = true → Mostrar todas
      // Si showAllTicketTypes = false → Solo las activas
      if (event.showAllTicketTypes) {
        return allTickets;
      } else {
        return allTickets.where((t) => t.isActive).toList();
      }
    });
