import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';

// ============================================
// REPOSITORY PROVIDER
// ============================================

final followRepositoryProvider = Provider<FollowRepository>((ref) {
  return FollowRepository();
});

// ============================================
// FOLLOW PROVIDERS
// ============================================

/// Provider que obtiene la lista de usuarios que sigo
final myFollowingProvider = FutureProvider<List<User>>((ref) async {
  final repo = ref.watch(followRepositoryProvider);
  return repo.getMyFollowing();
});

/// Provider que obtiene la lista de mis seguidores
final myFollowersProvider = FutureProvider<List<User>>((ref) async {
  final repo = ref.watch(followRepositoryProvider);
  return repo.getMyFollowers();
});

/// Provider que obtiene los IDs de usuarios que sigo (para checks rápidos)
final myFollowingIdsProvider = FutureProvider<Set<String>>((ref) async {
  final repo = ref.watch(followRepositoryProvider);
  return repo.getMyFollowingIds();
});

/// Provider que obtiene las estadísticas de un usuario
final userStatsProvider = FutureProvider.family<Map<String, int>, String>(
  (ref, userId) async {
    final repo = ref.watch(followRepositoryProvider);
    return repo.getUserStats(userId);
  },
);

// ============================================
// FOLLOW ACTIONS
// ============================================

final followActionsProvider = Provider<FollowActions>((ref) {
  return FollowActions(ref);
});

class FollowActions {
  final Ref ref;

  FollowActions(this.ref);

  /// Seguir/Dejar de seguir (toggle)
  Future<void> toggleFollow(String userId) async {
    final repo = ref.read(followRepositoryProvider);
    final followingIds = await ref.read(myFollowingIdsProvider.future);

    if (followingIds.contains(userId)) {
      // Ya lo sigo, dejar de seguir
      await repo.unfollowUser(userId);
    } else {
      // No lo sigo, seguir
      await repo.followUser(userId);
    }

    // Invalidar providers para refrescar
    ref.invalidate(myFollowingProvider);
    ref.invalidate(myFollowersProvider);
    ref.invalidate(myFollowingIdsProvider);
    ref.invalidate(userStatsProvider(userId));
  }

  /// Seguir usuario
  Future<void> followUser(String userId) async {
    final repo = ref.read(followRepositoryProvider);
    await repo.followUser(userId);
    
    ref.invalidate(myFollowingProvider);
    ref.invalidate(myFollowingIdsProvider);
    ref.invalidate(userStatsProvider(userId));
  }

  /// Dejar de seguir usuario
  Future<void> unfollowUser(String userId) async {
    final repo = ref.read(followRepositoryProvider);
    await repo.unfollowUser(userId);
    
    ref.invalidate(myFollowingProvider);
    ref.invalidate(myFollowingIdsProvider);
    ref.invalidate(userStatsProvider(userId));
  }

  /// Verificar si sigo a un usuario
  Future<bool> isFollowing(String userId) async {
    final repo = ref.read(followRepositoryProvider);
    return repo.isFollowing(userId);
  }
}
