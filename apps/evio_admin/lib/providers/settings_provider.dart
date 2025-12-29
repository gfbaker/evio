import 'package:evio_admin/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';

// ============ REPOSITORY PROVIDERS ============

final producerRepositoryProvider = Provider<ProducerRepository>((ref) {
  return ProducerRepository();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

// ============ PRODUCER PROVIDER ============

/// Productora del usuario actual
final currentProducerProvider = FutureProvider.autoDispose<Producer?>((
  ref,
) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user?.producerId == null) return null;

  final repo = ref.watch(producerRepositoryProvider);
  return repo.getProducerById(user!.producerId!);
});

// ============ USERS PROVIDER ============

/// Usuarios de la productora (solo para admin)
final producerUsersProvider = FutureProvider.autoDispose<List<User>>((
  ref,
) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user?.producerId == null) return [];

  final repo = ref.watch(userRepositoryProvider);
  return repo.getUsersByProducer(user!.producerId!);
});

// ============ INVITATIONS PROVIDER ============

/// Invitaciones de la productora (solo para admin)
final producerInvitationsProvider =
    FutureProvider.autoDispose<List<UserInvitation>>((ref) async {
      final user = await ref.watch(currentUserProvider.future);
      if (user?.producerId == null) return [];

      final repo = ref.watch(userRepositoryProvider);
      return repo.getInvitationsByProducer(user!.producerId!);
    });
