import 'package:evio_core/services/supabase_service.dart';
import 'package:evio_core/models/coupon.dart';

class CouponRepository {
  final _client = SupabaseService.client;

  // ============================================
  // VALIDACIÓN Y USO DE CUPONES
  // ============================================

  /// Validar cupón
  Future<Coupon?> validateCoupon({
    required String code,
    String? eventId,
    required int orderAmount,
  }) async {
    // Construir query base
    var query = _client
        .from('coupons')
        .select()
        .eq('code', code.toUpperCase())
        .eq('is_active', true);

    // Filtrar por evento si aplica
    if (eventId != null) {
      query = query.or('event_id.is.null,event_id.eq.$eventId');
    } else {
      query = query.filter('event_id', 'is', null);
    }

    final response = await query.maybeSingle();

    if (response == null) {
      throw Exception('Cupón no válido');
    }

    final coupon = Coupon.fromJson(response);

    // Validaciones
    if (coupon.expiresAt != null &&
        coupon.expiresAt!.isBefore(DateTime.now())) {
      throw Exception('Cupón expirado');
    }

    if (coupon.maxUses != null && coupon.usedCount >= coupon.maxUses!) {
      throw Exception('Cupón agotado');
    }

    if (coupon.minAmount != null && orderAmount < coupon.minAmount!) {
      throw Exception(
        'Monto mínimo no alcanzado: \$${coupon.minAmount! / 100}',
      );
    }

    return coupon;
  }

  /// Calcular descuento de un cupón
  int calculateDiscount(Coupon coupon, int orderAmount) {
    if (coupon.discountType == 'percent') {
      return (orderAmount * coupon.discountValue / 100).round();
    } else {
      // fixed
      return coupon.discountValue;
    }
  }

  /// Incrementar uso del cupón (llamar después de confirmar orden)
  Future<void> incrementCouponUsage(String couponId) async {
    await _client.rpc(
      'increment_coupon_usage',
      params: {'coupon_id': couponId},
    );
  }

  // ============================================
  // ADMIN - CRUD DE CUPONES
  // ============================================

  /// Obtener cupones de un evento (producer)
  Future<List<Coupon>> getEventCoupons(String eventId) async {
    final response = await _client
        .from('coupons')
        .select()
        .eq('event_id', eventId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => Coupon.fromJson(e)).toList();
  }

  /// Obtener cupones globales (superadmin)
  Future<List<Coupon>> getGlobalCoupons() async {
    final response = await _client
        .from('coupons')
        .select()
        .filter('event_id', 'is', null)
        .order('created_at', ascending: false);

    return (response as List).map((e) => Coupon.fromJson(e)).toList();
  }

  /// Crear cupón
  Future<Coupon> createCoupon(Coupon coupon) async {
    final response = await _client
        .from('coupons')
        .insert(coupon.toJson())
        .select()
        .single();

    return Coupon.fromJson(response);
  }

  /// Actualizar cupón
  Future<Coupon> updateCoupon(Coupon coupon) async {
    final response = await _client
        .from('coupons')
        .update(coupon.toJson())
        .eq('id', coupon.id)
        .select()
        .single();

    return Coupon.fromJson(response);
  }

  /// Eliminar cupón
  Future<void> deleteCoupon(String id) async {
    await _client.from('coupons').delete().eq('id', id);
  }

  /// Activar/desactivar cupón
  Future<Coupon> setCouponActive(String id, bool isActive) async {
    final response = await _client
        .from('coupons')
        .update({'is_active': isActive})
        .eq('id', id)
        .select()
        .single();

    return Coupon.fromJson(response);
  }

  /// Verificar si un código ya existe
  Future<bool> codeExists(String code, {String? excludeId}) async {
    var query = _client
        .from('coupons')
        .select('id')
        .eq('code', code.toUpperCase());

    if (excludeId != null) {
      query = query.neq('id', excludeId);
    }

    final response = await query.maybeSingle();
    return response != null;
  }

  // ============================================
  // STATS
  // ============================================

  /// Stats de un cupón
  Future<Map<String, dynamic>> getCouponStats(String couponId) async {
    // Obtener órdenes que usaron este cupón
    final ordersResponse = await _client
        .from('orders')
        .select('status, total_amount, discount_amount')
        .eq('coupon_id', couponId);

    final orders = ordersResponse as List;
    final paidOrders = orders.where((o) => o['status'] == 'paid');

    int totalDiscount = 0;
    int totalRevenue = 0;

    for (final order in paidOrders) {
      totalDiscount += order['discount_amount'] as int;
      totalRevenue += order['total_amount'] as int;
    }

    return {
      'total_uses': paidOrders.length,
      'total_discount': totalDiscount,
      'total_revenue': totalRevenue,
    };
  }
}
