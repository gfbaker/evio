import 'package:evio_fan/providers/order_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';

final checkoutProvider = StateNotifierProvider<CheckoutNotifier, CheckoutState>(
  (ref) {
    return CheckoutNotifier(
      orderRepository: ref.watch(orderRepositoryProvider),
    );
  },
);

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

  CheckoutNotifier({required OrderRepository orderRepository})
    : _orderRepository = orderRepository,
      super(CheckoutState());

  Future<void> processPayment({
    required String eventId,
    required String userId,
    required Map<String, int> tierQuantities,
  }) async {
    state = state.copyWith(isProcessing: true, error: null);

    try {
      // 1. Crear orden SEGURA con validación atómica (nuevo sistema tiers)
      // ✅ createOrderSafe_v2 YA crea: orden + order_items + actualiza sold_count
      final orderId = await _orderRepository.createOrderSafe(
        userId: userId,
        eventId: eventId,
        tierQuantities: tierQuantities,
      );

      debugPrint('✅ ORDEN CREADA: $orderId');

      // 2. Simular delay de pago (2 segundos)
      await Future.delayed(const Duration(seconds: 2));

      // 3. Obtener orden completa
      debugPrint('🔍 Obteniendo orden...');
      final order = await _orderRepository.getOrderById(orderId);
      debugPrint('✅ Orden obtenida: ${order?.id}');

      // 4. Actualizar estado
      state = state.copyWith(isProcessing: false, completedOrder: order);
    } on OrderException catch (e) {
      state = state.copyWith(isProcessing: false, error: e.message);
    } catch (e) {
      debugPrint('❌ ERROR EN PROCESS PAYMENT: $e');
      state = state.copyWith(isProcessing: false, error: e.toString());
    }
  }

  void reset() {
    state = CheckoutState();
  }
}
