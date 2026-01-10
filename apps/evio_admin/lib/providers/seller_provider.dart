import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';
import 'auth_provider.dart';

// ============ REPOSITORY PROVIDER ============

final sellerRepositoryProvider = Provider<SellerRepository>((ref) {
  return SellerRepository();
});

// ============ SELLERS PROVIDER ============

/// Vendedores de la productora actual
final producerSellersProvider = FutureProvider.autoDispose<List<AuthorizedSeller>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user?.producerId == null) return [];

  final repo = ref.watch(sellerRepositoryProvider);
  return repo.getSellersByProducer(user!.producerId!);
});

/// Provider para obtener datos de un usuario vendedor por ID
/// Este provider usa .family para cachear correctamente
final sellerUserProvider = FutureProvider.autoDispose.family<User?, String>((ref, userId) async {
  final repo = ref.watch(sellerRepositoryProvider);
  return repo.getSellerUser(userId);
});

// ============ SELLER ACTIONS ============

final sellerActionsProvider = Provider<SellerActions>((ref) {
  return SellerActions(ref);
});

class SellerActions {
  final Ref ref;

  SellerActions(this.ref);

  /// Agregar vendedor
  Future<void> addSeller(String userId) async {
    final user = await ref.read(currentUserProvider.future);
    if (user?.producerId == null) throw Exception('No producer found');

    final repo = ref.read(sellerRepositoryProvider);
    await repo.addSeller(
      producerId: user!.producerId!,
      userId: userId,
    );

    ref.invalidate(producerSellersProvider);
  }

  /// Activar/Desactivar vendedor
  Future<void> toggleSellerStatus(String sellerId, bool currentStatus) async {
    final repo = ref.read(sellerRepositoryProvider);
    await repo.updateSellerStatus(sellerId, !currentStatus);
    ref.invalidate(producerSellersProvider);
  }

  /// Eliminar vendedor
  Future<void> deleteSeller(String sellerId) async {
    final repo = ref.read(sellerRepositoryProvider);
    await repo.deleteSeller(sellerId);
    ref.invalidate(producerSellersProvider);
  }
}
