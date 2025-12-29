import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:evio_core/evio_core.dart';

// Provider que expone el cliente de Supabase
final supabaseClientProvider = Provider<supabase.SupabaseClient>((ref) {
  return supabase.Supabase.instance.client;
});

// Provider que escucha cambios en el auth state
final authStateProvider = StreamProvider<supabase.AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
});

// ✅ FIX: Provider que devuelve el User ACTUAL (sincrónico)
final currentAuthUserProvider = Provider<supabase.User?>((ref) {
  // 1. Primero intentamos leer del stream (si ya emitió)
  final authStateAsync = ref.watch(authStateProvider);

  final userFromStream = authStateAsync.maybeWhen(
    data: (state) => state.session?.user,
    orElse: () => null,
  );

  // 2. Si el stream todavía no tiene data, leemos la sesión actual
  if (userFromStream != null) {
    return userFromStream;
  }

  // Fallback: sesión actual de Supabase (sincrónico)
  final client = ref.watch(supabaseClientProvider);
  return client.auth.currentSession?.user;
});

// Provider que devuelve si el usuario está logueado
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentAuthUserProvider);
  return user != null;
});

// Provider que devuelve el userId (o null)
final currentUserIdProvider = Provider<String?>((ref) {
  final user = ref.watch(currentAuthUserProvider);
  return user?.id;
});

// Provider que devuelve el User de evio_core (con datos completos de la DB)
final currentUserProvider = FutureProvider<User?>((ref) async {
  final authUser = ref.watch(currentAuthUserProvider);
  if (authUser == null) return null;

  // Obtener el User completo de la tabla users
  final userRepo = UserRepository();
  return userRepo.getCurrentUser();
});
