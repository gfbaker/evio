import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';
import 'auth_provider.dart';
import 'ticket_provider.dart';

// ============================================
// REPOSITORY PROVIDER
// ============================================

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});

// ============================================
// MIS ÓRDENES
// ============================================

/// Órdenes del usuario actual
final myOrdersProvider = FutureProvider.autoDispose<List<Order>>((ref) async {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getMyOrders();
});

/// Orden individual por ID
final orderByIdProvider = FutureProvider.family.autoDispose<Order?, String>((
  ref,
  orderId,
) async {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getOrderById(orderId);
});

// ============================================
// CARRITO DE COMPRA
// ============================================

/// Estado del carrito
class CartState {
  final String? eventId;
  final Map<String, int> items; // tierId -> quantity
  final String? couponCode;
  final int? discountAmount;

  const CartState({
    this.eventId,
    this.items = const {},
    this.couponCode,
    this.discountAmount,
  });

  CartState copyWith({
    String? eventId,
    Map<String, int>? items,
    String? couponCode,
    int? discountAmount,
  }) {
    return CartState(
      eventId: eventId ?? this.eventId,
      items: items ?? this.items,
      couponCode: couponCode ?? this.couponCode,
      discountAmount: discountAmount ?? this.discountAmount,
    );
  }

  int get totalItems => items.values.fold(0, (sum, qty) => sum + qty);
  bool get isEmpty => items.isEmpty;
}

/// Notifier del carrito
class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  void setEvent(String eventId) {
    if (state.eventId != eventId) {
      // Limpiar carrito si cambia de evento
      state = CartState(eventId: eventId);
    }
  }

  void addItem(String tierId, {int quantity = 1}) {
    final currentQty = state.items[tierId] ?? 0;
    final newItems = Map<String, int>.from(state.items);
    newItems[tierId] = currentQty + quantity;
    state = state.copyWith(items: newItems);
  }

  void removeItem(String tierId, {int quantity = 1}) {
    final currentQty = state.items[tierId] ?? 0;
    final newQty = currentQty - quantity;
    final newItems = Map<String, int>.from(state.items);

    if (newQty <= 0) {
      newItems.remove(tierId);
    } else {
      newItems[tierId] = newQty;
    }

    state = state.copyWith(items: newItems);
  }

  void setQuantity(String tierId, int quantity) {
    final newItems = Map<String, int>.from(state.items);

    if (quantity <= 0) {
      newItems.remove(tierId);
    } else {
      newItems[tierId] = quantity;
    }

    state = state.copyWith(items: newItems);
  }

  void applyCoupon(String code, int discountAmount) {
    state = state.copyWith(couponCode: code, discountAmount: discountAmount);
  }

  void removeCoupon() {
    state = state.copyWith(couponCode: null, discountAmount: null);
  }

  void clear() {
    state = const CartState();
  }
}

/// Provider del carrito
final cartProvider = NotifierProvider<CartNotifier, CartState>(
  CartNotifier.new,
);

// ============================================
// CHECKOUT CONTROLLER (CON VALIDACIÓN)
// ============================================

class CheckoutController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() async {}

  /// Crear orden con validación atómica (nuevo sistema con tiers)
  Future<String?> createOrderSafe({
    required String eventId,
    required Map<String, int> tierQuantities,
  }) async {
    state = const AsyncValue.loading();

    try {
      // 1. Verificar autenticación
      final currentUser = await ref.read(currentUserProvider.future);
      
      if (currentUser == null) {
        throw OrderException.unauthorized();
      }

      // 2. Llamar función segura V2 (con tiers)
      final repository = ref.read(orderRepositoryProvider);
      final orderId = await repository.createOrderSafe(
        userId: currentUser.id,
        eventId: eventId,
        tierQuantities: tierQuantities,
      );

      state = const AsyncValue.data(null);

      // 3. Invalidar caches
      ref.invalidate(eventTicketCategoriesProvider(eventId));
      ref.invalidate(myOrdersProvider);

      return orderId;
    } on OrderException catch (e) {
      // Error de validación (sold out, max exceeded, etc)
      state = AsyncValue.error(e, StackTrace.current);
      return null;
    } catch (e, st) {
      // Error inesperado
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final checkoutControllerProvider =
    AutoDisposeAsyncNotifierProvider<CheckoutController, void>(
  CheckoutController.new,
);

// ============================================
// CHECKOUT
// ============================================

/// Crear orden pendiente
Future<Order> createOrder(
  WidgetRef ref, {
  required String eventId,
  required List<OrderItem> items,
  String? couponId,
  int? discountAmount,
}) async {
  final repository = ref.read(orderRepositoryProvider);

  final order = await repository.createOrder(
    eventId: eventId,
    items: items,
    couponId: couponId,
    discountAmount: discountAmount,
  );

  // Limpiar carrito
  ref.read(cartProvider.notifier).clear();

  // Invalidar cache
  ref.invalidate(myOrdersProvider);

  return order;
}

/// Confirmar pago (webhook de Mercado Pago)
Future<Order> confirmPayment(
  WidgetRef ref, {
  required String orderId,
  required String paymentProvider,
  required String paymentId,
}) async {
  final repository = ref.read(orderRepositoryProvider);

  final order = await repository.confirmPayment(
    orderId: orderId,
    paymentProvider: paymentProvider,
    paymentId: paymentId,
  );

  // Invalidar caches
  ref.invalidate(myOrdersProvider);
  ref.invalidate(orderByIdProvider(orderId));

  return order;
}

/// Marcar orden como fallida
Future<Order> markOrderFailed(
  WidgetRef ref,
  String orderId,
  String reason,
) async {
  final repository = ref.read(orderRepositoryProvider);

  final order = await repository.markOrderAsFailed(orderId, reason);

  // Invalidar cache
  ref.invalidate(myOrdersProvider);
  ref.invalidate(orderByIdProvider(orderId));

  return order;
}

// ============================================
// CHECKOUT SESSIONS (RECUPERAR CARRITO)
// ============================================

/// Guardar sesión de checkout
Future<void> saveCheckoutSession(WidgetRef ref, String eventId) async {
  final repository = ref.read(orderRepositoryProvider);
  final cart = ref.read(cartProvider);

  if (cart.isEmpty) return;

  final items = cart.items.entries
      .map((e) => {'tier_id': e.key, 'quantity': e.value})
      .toList();

  await repository.saveCheckoutSession(eventId: eventId, items: items);
}

/// Recuperar última sesión de checkout
Future<void> restoreCheckoutSession(WidgetRef ref, String eventId) async {
  final repository = ref.read(orderRepositoryProvider);
  final session = await repository.getLastCheckoutSession(eventId);

  if (session == null) return;

  final cartNotifier = ref.read(cartProvider.notifier);
  cartNotifier.setEvent(eventId);

  final items = session['items'] as List;
  for (final item in items) {
    // Soportar tanto tier_id (nuevo) como ticket_type_id (legacy)
    final tierId = item['tier_id'] as String? ?? item['ticket_type_id'] as String;
    final quantity = item['quantity'] as int;
    cartNotifier.setQuantity(tierId, quantity);
  }
}
