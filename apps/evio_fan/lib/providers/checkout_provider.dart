import 'dart:async';

import 'package:evio_fan/providers/order_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';

final checkoutProvider = StateNotifierProvider<CheckoutNotifier, CheckoutState>(
  (ref) {
    return CheckoutNotifier(
      orderRepository: ref.watch(orderRepositoryProvider),
      eventRepository: ref.watch(eventRepositoryProvider),
    );
  },
);

/// Provider del repositorio de eventos (para validación)
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository();
});

class CheckoutState {
  final bool isProcessing;
  final Order? completedOrder;
  final String? error;

  CheckoutState({this.isProcessing = false, this.completedOrder, this.error});

  CheckoutState copyWith({
    bool? isProcessing,
    Order? completedOrder,
    String? error,
  }) {
    return CheckoutState(
      isProcessing: isProcessing ?? this.isProcessing,
      completedOrder: completedOrder ?? this.completedOrder,
      error: error ?? this.error,
    );
  }
}

class CheckoutNotifier extends StateNotifier<CheckoutState> {
  final OrderRepository _orderRepository;
  final EventRepository _eventRepository;

  CheckoutNotifier({
    required OrderRepository orderRepository,
    required EventRepository eventRepository,
  }) : _orderRepository = orderRepository,
       _eventRepository = eventRepository,
       super(CheckoutState());

  /// Timeout para operaciones de red
  static const _networkTimeout = Duration(seconds: 15);
  
  /// Máximo de reintentos para errores de red
  static const _maxRetries = 3;

  Future<void> processPayment({
    required String eventId,
    required String userId,
    required Map<String, int> tierQuantities,
  }) async {
    state = state.copyWith(isProcessing: true, error: null);

    // ✅ VALIDACIÓN DE SEGURIDAD: Verificar que el evento está publicado
    try {
      debugPrint('🔍 Verificando estado del evento...');
      final event = await _eventRepository
          .getEventById(eventId)
          .timeout(_networkTimeout);
      
      if (event == null) {
        state = state.copyWith(
          isProcessing: false,
          error: 'El evento no existe o fue eliminado.',
        );
        return;
      }
      
      if (!event.isPublished) {
        state = state.copyWith(
          isProcessing: false,
          error: 'Este evento ya no está disponible para la venta de entradas.',
        );
        return;
      }
      
      // También verificar que no haya terminado
      if (event.endDatetime != null && event.endDatetime!.isBefore(DateTime.now())) {
        state = state.copyWith(
          isProcessing: false,
          error: 'Este evento ya ha finalizado.',
        );
        return;
      }
      
      debugPrint('✅ Evento verificado: publicado y activo');
      
    } catch (e) {
      debugPrint('⚠️ Error verificando evento: $e');
      // Si no podemos verificar, continuamos pero la función SQL validará
    }

    String? orderId;
    var attempt = 0;

    // 1. Crear orden con retry + exponential backoff
    while (attempt < _maxRetries) {
      try {
        debugPrint('💳 Intento ${attempt + 1}/$_maxRetries - Creando orden...');
        
        orderId = await _orderRepository
            .createOrderSafe(
              userId: userId,
              eventId: eventId,
              tierQuantities: tierQuantities,
            )
            .timeout(_networkTimeout);

        debugPrint('✅ ORDEN CREADA: $orderId');
        break; // Éxito, salir del loop
        
      } on TimeoutException {
        attempt++;
        debugPrint('⏱️ Timeout en intento $attempt');
        
        if (attempt >= _maxRetries) {
          state = state.copyWith(
            isProcessing: false,
            error: 'La conexión tardó demasiado. Verificá tu internet e intentá de nuevo.',
          );
          return;
        }
        
        // Exponential backoff: 2s, 4s, 8s
        await Future.delayed(Duration(seconds: 2 << (attempt - 1)));
        
      } on OrderException catch (e) {
        // Errores de negocio: NO reintentar
        debugPrint('❌ OrderException: ${e.code} - ${e.message}');
        state = state.copyWith(isProcessing: false, error: e.message);
        return;
        
      } catch (e) {
        attempt++;
        debugPrint('❌ Error en intento $attempt: $e');
        
        if (attempt >= _maxRetries) {
          state = state.copyWith(
            isProcessing: false,
            error: 'Error de conexión. Intentá de nuevo.',
          );
          return;
        }
        
        await Future.delayed(Duration(seconds: 2 << (attempt - 1)));
      }
    }

    if (orderId == null) {
      state = state.copyWith(
        isProcessing: false,
        error: 'No se pudo crear la orden. Intentá de nuevo.',
      );
      return;
    }

    // 2. Simular delay de pago (TODO: Mercado Pago)
    await Future.delayed(const Duration(seconds: 2));

    // 3. Obtener orden completa
    try {
      debugPrint('🔍 Obteniendo orden...');
      final order = await _orderRepository
          .getOrderById(orderId)
          .timeout(_networkTimeout);
      debugPrint('✅ Orden obtenida: ${order?.id}');

      state = state.copyWith(isProcessing: false, completedOrder: order);
    } catch (e) {
      // La orden se creó pero no pudimos obtenerla - no es crítico
      debugPrint('⚠️ No se pudo obtener orden, pero fue creada: $orderId');
      state = state.copyWith(
        isProcessing: false,
        // Crear orden mínima para mostrar éxito
        completedOrder: Order(
          id: orderId,
          userId: userId,
          eventId: eventId,
          status: OrderStatus.paid,
          totalAmount: 0,
          currency: 'ARS',
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  void reset() {
    state = CheckoutState();
  }
}
