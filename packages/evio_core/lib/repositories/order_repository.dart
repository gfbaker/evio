import 'package:evio_core/services/supabase_service.dart';
import 'package:evio_core/models/order.dart';
import 'package:evio_core/models/order_item.dart';
import 'package:evio_core/exceptions/order_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderRepository {
  final _client = SupabaseService.client;

  // ============================================
  // ÓRDENES
  // ============================================

  /// Obtener mis órdenes
  Future<List<Order>> getMyOrders() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    // Obtener el user_id de la tabla users
    final userResponse = await _client
        .from('users')
        .select('id')
        .eq('auth_provider_id', userId)
        .single();

    final dbUserId = userResponse['id'] as String;

    final response = await _client
        .from('orders')
        .select('''
          *,
          event:events(*),
          items:order_items(*,
            ticket_type:ticket_types(*)
          )
        ''')
        .eq('user_id', dbUserId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => Order.fromJson(e)).toList();
  }

  /// Obtener orden por ID
  Future<Order?> getOrderById(String id) async {
    final response = await _client
        .from('orders')
        .select('''
          *,
          event:events(*),
          items:order_items(*,
            ticket_type:ticket_types(*)
          ),
          coupon:coupons(*)
        ''')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Order.fromJson(response);
  }

  // ============================================
  // CREAR ORDEN SEGURA (CON VALIDACIÓN ATÓMICA)
  // ============================================

  /// Crear orden con validación atómica (anti-overselling)
  Future<String> createOrderSafe({
    required String userId,
    required String eventId,
    required Map<String, int> ticketQuantities, // {ticketTypeId: quantity}
  }) async {
    try {
      // Convertir a formato JSONB para la función SQL
      final ticketQuantitiesJson = ticketQuantities.entries
          .map((e) => {'ticket_type_id': e.key, 'quantity': e.value})
          .toList();

      // ✅ Llamar función SQL SEGURA
      final response = await _client.rpc(
        'create_order_safe',
        params: {
          'p_user_id': userId,
          'p_event_id': eventId,
          'p_ticket_quantities': ticketQuantitiesJson,
        },
      );

      if (response == null) {
        throw OrderException.serverError('No se recibió respuesta del servidor');
      }

      final orderId = response['order_id'] as String;
      return orderId;
    } on PostgrestException catch (e) {
      // ❌ Errores de validación del SQL
      if (e.message.contains('agotado')) {
        throw OrderException(
          'Tickets agotados. Por favor actualiza la página.',
          code: 'SOLD_OUT',
        );
      }
      if (e.message.contains('Máximo')) {
        throw OrderException(e.message, code: 'MAX_EXCEEDED');
      }
      throw OrderException.serverError(e.message);
    } catch (e) {
      throw OrderException.serverError('Error inesperado: $e');
    }
  }

  // ============================================
  // CREAR ORDEN (CHECKOUT)
  // ============================================

  /// Crear orden pendiente
  Future<Order> createOrder({
    required String eventId,
    required List<OrderItem> items,
    String? couponId,
    int? discountAmount,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    final userResponse = await _client
        .from('users')
        .select('id')
        .eq('auth_provider_id', userId)
        .single();

    final dbUserId = userResponse['id'] as String;

    // Calcular total
    int totalAmount = 0;
    for (final item in items) {
      totalAmount += (item.unitPrice * item.quantity);
    }

    // Aplicar descuento
    final finalAmount = totalAmount - (discountAmount ?? 0);

    // Crear orden
    final orderResponse = await _client
        .from('orders')
        .insert({
          'user_id': dbUserId,
          'event_id': eventId,
          'status': 'pending',
          'total_amount': finalAmount,
          'currency': 'ARS',
          'coupon_id': couponId,
          'discount_amount': discountAmount ?? 0,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    final orderId = orderResponse['id'] as String;

    // Crear items
    for (final item in items) {
      await _client.from('order_items').insert({
        'order_id': orderId,
        'ticket_type_id': item.ticketTypeId,
        'quantity': item.quantity,
        'unit_price': item.unitPrice,
      });
    }

    final order = await getOrderById(orderId);
    return order!;
  }

  // ============================================
  // CONFIRMAR PAGO
  // ============================================

  /// Confirmar pago y generar tickets
  Future<Order> confirmPayment({
    required String orderId,
    required String paymentProvider,
    required String paymentId,
  }) async {
    // 1. Actualizar orden
    await _client
        .from('orders')
        .update({
          'status': 'paid',
          'payment_provider': paymentProvider,
          'payment_id': paymentId,
          'paid_at': DateTime.now().toIso8601String(),
        })
        .eq('id', orderId);

    // 2. Obtener orden con items
    final order = await getOrderById(orderId);
    if (order == null) throw Exception('Orden no encontrada');

    // 3. Generar tickets
    for (final item in order.items) {
      for (int i = 0; i < item.quantity; i++) {
        await _client.from('tickets').insert({
          'event_id': order.eventId,
          'ticket_type_id': item.ticketTypeId,
          'order_id': orderId,
          'owner_id': order.userId,
          'original_owner_id': order.userId,
          'status': 'valid',
          'is_invitation': false,
          'transfer_allowed': true, // TODO: leer de ticket_type config
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // 4. Actualizar sold_quantity del ticket_type
      await _client.rpc(
        'increment_ticket_type_sold',
        params: {
          'ticket_type_id': item.ticketTypeId,
          'quantity': item.quantity,
        },
      );
    }

    final updatedOrder = await getOrderById(orderId);
    return updatedOrder!;
  }

  /// Marcar orden como fallida
  Future<Order> markOrderAsFailed(String orderId, String reason) async {
    await _client
        .from('orders')
        .update({
          'status': 'failed',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', orderId);

    final order = await getOrderById(orderId);
    return order!;
  }

  // ============================================
  // ADMIN - ÓRDENES DEL EVENTO
  // ============================================

  /// Obtener todas las órdenes de un evento (producer)
  Future<List<Order>> getEventOrders(String eventId) async {
    final response = await _client
        .from('orders')
        .select('''
          *,
          user:users(*),
          items:order_items(*,
            ticket_type:ticket_types(*)
          )
        ''')
        .eq('event_id', eventId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => Order.fromJson(e)).toList();
  }

  /// Stats de órdenes del evento
  Future<Map<String, dynamic>> getEventOrderStats(String eventId) async {
    final response = await _client
        .from('orders')
        .select('status, total_amount')
        .eq('event_id', eventId);

    final orders = response as List;

    final paid = orders.where((o) => o['status'] == 'paid');
    final pending = orders.where((o) => o['status'] == 'pending');
    final failed = orders.where((o) => o['status'] == 'failed');

    int totalRevenue = 0;
    for (final order in paid) {
      totalRevenue += order['total_amount'] as int;
    }

    return {
      'total_orders': orders.length,
      'paid': paid.length,
      'pending': pending.length,
      'failed': failed.length,
      'total_revenue': totalRevenue,
    };
  }

  // ============================================
  // CHECKOUT SESSIONS (Carritos abandonados)
  // ============================================

  /// Guardar sesión de checkout
  Future<void> saveCheckoutSession({
    required String eventId,
    required List<Map<String, dynamic>> items,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final userResponse = await _client
        .from('users')
        .select('id')
        .eq('auth_provider_id', userId)
        .maybeSingle();

    if (userResponse == null) return;
    final dbUserId = userResponse['id'] as String;

    await _client.from('checkout_sessions').insert({
      'user_id': dbUserId,
      'event_id': eventId,
      'items': items,
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Obtener última sesión de checkout
  Future<Map<String, dynamic>?> getLastCheckoutSession(String eventId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final userResponse = await _client
        .from('users')
        .select('id')
        .eq('auth_provider_id', userId)
        .maybeSingle();

    if (userResponse == null) return null;
    final dbUserId = userResponse['id'] as String;

    final response = await _client
        .from('checkout_sessions')
        .select()
        .eq('user_id', dbUserId)
        .eq('event_id', eventId)
        .eq('status', 'active')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return response;
  }

  /// Marcar sesión como completada
  Future<void> completeCheckoutSession(String sessionId) async {
    await _client
        .from('checkout_sessions')
        .update({'status': 'completed'})
        .eq('id', sessionId);
  }
}
