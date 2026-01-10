import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:evio_core/evio_core.dart';

// Supabase client provider
final supabaseClientProvider = Provider<supabase.SupabaseClient>((ref) {
  return supabase.Supabase.instance.client;
});

// Current user session
final authStateProvider = StreamProvider<supabase.AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
});

// Current user (evio_core User model)
final currentUserProvider = FutureProvider<User?>((ref) async {
  final authState = await ref.watch(authStateProvider.future);

  if (authState.session == null) {
    return null;
  }

  final client = ref.read(supabaseClientProvider);
  try {
    final data = await client
        .from('users')
        .select()
        .eq('auth_provider_id', authState.session!.user.id)
        .single()
        .timeout(Duration(seconds: 10));

    return User.fromJson(data);
  } catch (e) {
    return null;
  }
});

// Auth controller
final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref);
});

class AuthController {
  final Ref _ref;

  AuthController(this._ref);

  supabase.SupabaseClient get _client => _ref.read(supabaseClientProvider);

  Future<void> signIn(String email, String password) async {
    try {
      await _client.auth
          .signInWithPassword(email: email, password: password)
          .timeout(Duration(seconds: 15));
    } on supabase.AuthException catch (e) {
      throw _mapAuthException(e);
    } on TimeoutException {
      throw 'Timeout: verifica tu conexión';
    } catch (e) {
      throw 'Error desconocido: $e';
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    String? surname,
    UserRole role = UserRole.admin, // ✅ Default admin para evio_admin app
  }) async {
    try {
      await _client.auth
          .signUp(
            email: email,
            password: password,
            data: {'name': name, 'surname': surname, 'role': role.name},
          )
          .timeout(Duration(seconds: 15));
    } on supabase.AuthException catch (e) {
      throw _mapAuthException(e);
    } on TimeoutException {
      throw 'Timeout: verifica tu conexión';
    } catch (e) {
      throw 'Error desconocido: $e';
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut().timeout(Duration(seconds: 10));
    } catch (e) {
      throw 'Error al cerrar sesión: $e';
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _client.auth
          .resetPasswordForEmail(email)
          .timeout(Duration(seconds: 15));
    } on supabase.AuthException catch (e) {
      throw _mapAuthException(e);
    } on TimeoutException {
      throw 'Timeout: verifica tu conexión';
    } catch (e) {
      throw 'Error desconocido: $e';
    }
  }

  String _mapAuthException(supabase.AuthException e) {
    switch (e.message) {
      case 'Invalid login credentials':
        return 'Email o contraseña incorrectos';
      case 'Email not confirmed':
        return 'Email no verificado. Revisa tu correo.';
      case 'User already registered':
        return 'Email ya registrado';
      default:
        return e.message;
    }
  }
}
