import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';

import 'auth_provider.dart';

// Repository providers
final producerRepositoryProvider = Provider<ProducerRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ProducerRepository(client);
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return UserRepository(client);
});

// Onboarding controller
final onboardingControllerProvider = Provider<OnboardingController>((ref) {
  return OnboardingController(ref);
});

class OnboardingController {
  final Ref _ref;

  OnboardingController(this._ref);

  ProducerRepository get _producerRepo => _ref.read(producerRepositoryProvider);
  UserRepository get _userRepo => _ref.read(userRepositoryProvider);

  /// Crear productora y vincular al usuario actual
  Future<void> createProducerAndLinkUser({
    required String name,
    String? email,
    Uint8List? logoBytes,
  }) async {
    try {
      // TODO: Upload logo to Supabase Storage cuando lo implementemos
      String? logoUrl;
      
      final client = _ref.read(supabaseClientProvider);
      final session = client.auth.currentSession;
      
      if (session == null) {
        throw 'No hay sesión activa';
      }
      
      // 1. Crear productora
      final producer = await _producerRepo.createProducer(
        name: name,
        userId: session.user.id,
        email: email,
        logoUrl: logoUrl,
      ).timeout(Duration(seconds: 10));

      // 2. Obtener usuario actual
      final currentUser = await _userRepo.getCurrentUser()
          .timeout(Duration(seconds: 10));

      if (currentUser == null) {
        throw 'Usuario no encontrado';
      }

      // 3. Actualizar usuario con producer_id
      await _userRepo.updateUser(
        currentUser.copyWith(producerId: producer.id),
      ).timeout(Duration(seconds: 10));

    } on TimeoutException {
      throw 'Timeout: verifica tu conexión';
    } catch (e) {
      throw 'Error al crear productora: $e';
    }
  }
}
