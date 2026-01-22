import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';
import 'package:evio_fan/providers/checkout_provider.dart';
import 'package:evio_fan/providers/order_provider.dart';

/// Mock del OrderRepository para tests
/// Usa noSuchMethod para métodos no implementados
class MockOrderRepository implements OrderRepository {
  bool shouldSucceed = true;
  bool shouldTimeout = false;
  int callCount = 0;
  int failUntilAttempt = 0;
  String? lastEventId;
  String? lastUserId;
  Map<String, int>? lastTierQuantities;
  
  OrderException? throwException;
  
  @override
  Future<String> createOrderSafe({
    required String userId,
    required String eventId,
    required Map<String, int> tierQuantities,
  }) async {
    callCount++;
    lastEventId = eventId;
    lastUserId = userId;
    lastTierQuantities = tierQuantities;
    
    await Future.delayed(Duration(milliseconds: 50));
    
    if (shouldTimeout) {
      throw TimeoutException('Mock timeout');
    }
    
    if (throwException != null) {
      throw throwException!;
    }
    
    if (failUntilAttempt > 0 && callCount < failUntilAttempt) {
      throw Exception('Mock failure attempt $callCount');
    }
    
    if (!shouldSucceed) {
      throw Exception('Mock failure');
    }
    
    return 'mock-order-${DateTime.now().millisecondsSinceEpoch}';
  }
  
  @override
  Future<Order?> getOrderById(String id) async {
    await Future.delayed(Duration(milliseconds: 50));
    
    return Order(
      id: id,
      userId: lastUserId ?? 'mock-user',
      eventId: lastEventId ?? 'mock-event',
      status: OrderStatus.paid,
      totalAmount: 500000,
      currency: 'ARS',
      createdAt: DateTime.now(),
    );
  }
  
  @override
  Future<List<Order>> getEventOrders(String eventId) async => [];
  
  // Métodos no usados en estos tests - implementación mínima
  @override
  Future<List<Order>> getMyOrders() async => [];
  
  @override
  Future<String> createOrderSafeLegacy({
    required String userId,
    required String eventId,
    required Map<String, int> ticketQuantities,
  }) async => 'legacy-order';
  
  @override
  Future<Order> createOrder({
    required String eventId,
    required List<OrderItem> items,
    String? couponId,
    int? discountAmount,
  }) async => Order(
    id: 'mock',
    userId: 'mock',
    eventId: eventId,
    totalAmount: 0,
  );
  
  @override
  Future<Order> confirmPayment({
    required String orderId,
    required String paymentProvider,
    required String paymentId,
  }) async => Order(
    id: orderId,
    userId: 'mock',
    eventId: 'mock',
    totalAmount: 0,
    status: OrderStatus.paid,
  );
  
  @override
  Future<Order> markOrderAsFailed(String orderId, String reason) async => Order(
    id: orderId,
    userId: 'mock',
    eventId: 'mock',
    totalAmount: 0,
    status: OrderStatus.failed,
  );
  
  @override
  Future<Map<String, dynamic>> getEventOrderStats(String eventId) async => {};
  
  @override
  Future<void> saveCheckoutSession({
    required String eventId,
    required List<Map<String, dynamic>> items,
  }) async {}
  
  @override
  Future<Map<String, dynamic>?> getLastCheckoutSession(String eventId) async => null;
  
  @override
  Future<void> completeCheckoutSession(String sessionId) async {}
  
  @override
  Future<EventSalesStats> getEventSalesStats(String eventId) async {
    return EventSalesStats.empty(eventId);
  }
  
  void reset() {
    shouldSucceed = true;
    shouldTimeout = false;
    callCount = 0;
    failUntilAttempt = 0;
    throwException = null;
    lastEventId = null;
    lastUserId = null;
    lastTierQuantities = null;
  }
}

void main() {
  late MockOrderRepository mockRepo;
  late ProviderContainer container;
  
  setUp(() {
    mockRepo = MockOrderRepository();
    container = ProviderContainer(
      overrides: [
        orderRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });
  
  tearDown(() {
    container.dispose();
    mockRepo.reset();
  });

  group('CheckoutNotifier', () {
    group('processPayment', () {
      test('crea orden exitosamente', () async {
        final notifier = container.read(checkoutProvider.notifier);
        
        await notifier.processPayment(
          eventId: 'event-123',
          userId: 'user-456',
          tierQuantities: {'tier-1': 2, 'tier-2': 1},
        );
        
        final state = container.read(checkoutProvider);
        
        expect(state.isProcessing, false);
        expect(state.completedOrder, isNotNull);
        expect(state.error, isNull);
        expect(mockRepo.callCount, 1);
        expect(mockRepo.lastEventId, 'event-123');
        expect(mockRepo.lastUserId, 'user-456');
        expect(mockRepo.lastTierQuantities, {'tier-1': 2, 'tier-2': 1});
      });
      
      test('muestra error para OrderException (sin retry)', () async {
        mockRepo.throwException = OrderException(
          'Entradas agotadas',
          code: 'SOLD_OUT',
        );
        
        final notifier = container.read(checkoutProvider.notifier);
        
        await notifier.processPayment(
          eventId: 'event-123',
          userId: 'user-456',
          tierQuantities: {'tier-1': 1},
        );
        
        final state = container.read(checkoutProvider);
        
        expect(state.isProcessing, false);
        expect(state.completedOrder, isNull);
        expect(state.error, 'Entradas agotadas');
        expect(mockRepo.callCount, 1); // NO reintenta errores de negocio
      });
      
      test('reintenta con exponential backoff hasta éxito', () async {
        // Fallar primeros 2 intentos, éxito en el 3ro
        mockRepo.failUntilAttempt = 3;
        
        final notifier = container.read(checkoutProvider.notifier);
        
        await notifier.processPayment(
          eventId: 'event-123',
          userId: 'user-456',
          tierQuantities: {'tier-1': 1},
        );
        
        final state = container.read(checkoutProvider);
        
        expect(state.isProcessing, false);
        expect(state.completedOrder, isNotNull);
        expect(state.error, isNull);
        expect(mockRepo.callCount, 3); // 2 fallos + 1 éxito
      });
      
      test('falla después de max retries', () async {
        mockRepo.shouldSucceed = false;
        
        final notifier = container.read(checkoutProvider.notifier);
        
        await notifier.processPayment(
          eventId: 'event-123',
          userId: 'user-456',
          tierQuantities: {'tier-1': 1},
        );
        
        final state = container.read(checkoutProvider);
        
        expect(state.isProcessing, false);
        expect(state.completedOrder, isNull);
        expect(state.error, isNotNull);
        expect(mockRepo.callCount, 3); // Max retries
      });
      
      test('reset limpia el estado', () async {
        final notifier = container.read(checkoutProvider.notifier);
        
        await notifier.processPayment(
          eventId: 'event-123',
          userId: 'user-456',
          tierQuantities: {'tier-1': 1},
        );
        
        expect(container.read(checkoutProvider).completedOrder, isNotNull);
        
        notifier.reset();
        
        final state = container.read(checkoutProvider);
        expect(state.isProcessing, false);
        expect(state.completedOrder, isNull);
        expect(state.error, isNull);
      });
    });
  });

  group('CheckoutState', () {
    test('copyWith actualiza campos correctamente', () {
      final initial = CheckoutState();
      
      expect(initial.isProcessing, false);
      expect(initial.completedOrder, isNull);
      expect(initial.error, isNull);
      
      final processing = initial.copyWith(isProcessing: true);
      expect(processing.isProcessing, true);
      expect(processing.completedOrder, isNull);
      
      final withError = initial.copyWith(error: 'Test error');
      expect(withError.error, 'Test error');
      expect(withError.isProcessing, false);
    });
  });
}
