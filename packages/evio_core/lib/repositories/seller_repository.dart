import 'package:evio_core/services/supabase_service.dart';
import 'package:evio_core/models/authorized_seller.dart';
import 'package:evio_core/models/seller_stats.dart';
import 'package:evio_core/models/user.dart';

class SellerRepository {
  final _client = SupabaseService.client;
  static const _timeout = Duration(seconds: 15);

  /// Obtener vendedores autorizados de una productora
  Future<List<AuthorizedSeller>> getSellersByProducer(String producerId) async {
    if (producerId.isEmpty) {
      throw ArgumentError('producerId cannot be empty');
    }

    try {
      final response = await _client
          .from('authorized_sellers')
          .select()
          .eq('producer_id', producerId)
          .order('created_at', ascending: false)
          .timeout(_timeout);

      if (response is! List) return [];

      return response
          .map((json) {
            try {
              return AuthorizedSeller.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              // Log error pero continuar con otros registros
              return null;
            }
          })
          .whereType<AuthorizedSeller>()
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Agregar vendedor autorizado
  Future<AuthorizedSeller> addSeller({
    required String producerId,
    required String userId,
    double commissionPercentage = 0.0,
  }) async {
    if (producerId.isEmpty) {
      throw ArgumentError('producerId cannot be empty');
    }
    if (userId.isEmpty) {
      throw ArgumentError('userId cannot be empty');
    }
    if (commissionPercentage < 0 || commissionPercentage > 100) {
      throw ArgumentError('commissionPercentage must be between 0 and 100');
    }

    try {
      final response = await _client
          .from('authorized_sellers')
          .insert({
            'producer_id': producerId,
            'user_id': userId,
            'commission_percentage': commissionPercentage,
            'is_active': true,
          })
          .select()
          .single()
          .timeout(_timeout);

      return AuthorizedSeller.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Actualizar estado (activo/inactivo)
  Future<void> updateSellerStatus(String sellerId, bool isActive) async {
    if (sellerId.isEmpty) {
      throw ArgumentError('sellerId cannot be empty');
    }

    try {
      await _client
          .from('authorized_sellers')
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sellerId)
          .timeout(_timeout);
    } catch (e) {
      rethrow;
    }
  }

  /// Actualizar comisión
  Future<void> updateSellerCommission(
    String sellerId,
    double commissionPercentage,
  ) async {
    if (sellerId.isEmpty) {
      throw ArgumentError('sellerId cannot be empty');
    }
    if (commissionPercentage < 0 || commissionPercentage > 100) {
      throw ArgumentError('commissionPercentage must be between 0 and 100');
    }

    try {
      await _client
          .from('authorized_sellers')
          .update({
            'commission_percentage': commissionPercentage,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sellerId)
          .timeout(_timeout);
    } catch (e) {
      rethrow;
    }
  }

  /// Eliminar vendedor
  Future<void> deleteSeller(String sellerId) async {
    if (sellerId.isEmpty) {
      throw ArgumentError('sellerId cannot be empty');
    }

    try {
      await _client
          .from('authorized_sellers')
          .delete()
          .eq('id', sellerId)
          .timeout(_timeout);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener datos del usuario vendedor
  Future<User?> getSellerUser(String userId) async {
    if (userId.isEmpty) return null;

    try {
      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle()
          .timeout(_timeout);

      if (response == null) return null;

      return User.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      // No rethrow aquí porque retornamos null en caso de error
      return null;
    }
  }

  /// Obtener stats de vendedores para un evento
  Future<List<SellerStats>> getSellerStatsByEvent(String eventId) async {
    if (eventId.isEmpty) {
      throw ArgumentError('eventId cannot be empty');
    }

    try {
      final response = await _client
          .rpc('get_seller_stats_by_event', params: {'p_event_id': eventId})
          .timeout(_timeout);

      if (response is! List) return [];

      return response
          .map((json) {
            try {
              return SellerStats.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              return null;
            }
          })
          .whereType<SellerStats>()
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener stats de ventas directas para un evento
  Future<DirectSalesStats> getDirectSalesStats(String eventId) async {
    if (eventId.isEmpty) {
      throw ArgumentError('eventId cannot be empty');
    }

    try {
      final response = await _client
          .rpc('get_direct_sales_stats', params: {'p_event_id': eventId})
          .timeout(_timeout);

      if (response is List && response.isNotEmpty) {
        return DirectSalesStats.fromJson(
          response.first as Map<String, dynamic>,
        );
      }

      return const DirectSalesStats(
        totalOrders: 0,
        totalTickets: 0,
        totalRevenue: 0,
      );
    } catch (e) {
      // Retornar stats vacíos en caso de error
      return const DirectSalesStats(
        totalOrders: 0,
        totalTickets: 0,
        totalRevenue: 0,
      );
    }
  }

  /// Obtener top vendedores de una productora
  Future<List<SellerStats>> getTopSellersByProducer(
    String producerId, {
    int limit = 10,
  }) async {
    if (producerId.isEmpty) {
      throw ArgumentError('producerId cannot be empty');
    }
    if (limit < 1 || limit > 100) {
      throw ArgumentError('limit must be between 1 and 100');
    }

    try {
      final response = await _client
          .rpc(
            'get_top_sellers_by_producer',
            params: {
              'p_producer_id': producerId,
              'p_limit': limit,
            },
          )
          .timeout(_timeout);

      if (response is! List) return [];

      return response
          .map((json) {
            try {
              return SellerStats.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              return null;
            }
          })
          .whereType<SellerStats>()
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}
