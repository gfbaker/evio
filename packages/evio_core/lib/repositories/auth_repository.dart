import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../services/supabase_service.dart';
import '../models/user.dart';
import '../constants/enums.dart';

class AuthRepository {
  final _client = SupabaseService.client;

  // Stream de cambios de auth
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Usuario actual de Supabase (auth)
  String? get currentUserId => _client.auth.currentUser?.id;

  // ¿Está autenticado?
  bool get isAuthenticated => currentUserId != null;

  // Registro con email/password
  Future<User> signUp({
    required String email,
    required String password,
    required String name,
    required String surname,
    UserRole role = UserRole.fan,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name, 'surname': surname, 'role': role.name},
    );

    if (response.user == null) {
      throw Exception('Error al crear usuario');
    }

    // ✅ El trigger handle_new_user() crea automáticamente el registro en public.users
    // No hacemos insert manual para evitar duplicados
    
    // Esperar a que el trigger complete
    await Future.delayed(Duration(milliseconds: 500));
    
    // Obtener el perfil creado por el trigger
    return _getUserProfile(response.user!.id);
  }

  // Login con email/password
  Future<User> signIn({required String email, required String password}) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Credenciales inválidas');
    }

    return _getUserProfile(response.user!.id);
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Recuperar contraseña
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  // Obtener perfil del usuario
  Future<User> _getUserProfile(String userId) async {
    final response = await _client
        .from('users')
        .select()
        .eq('auth_provider_id', userId)
        .single();

    return User.fromJson(response);
  }

  // Obtener perfil actual
  Future<User?> getCurrentProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;

    try {
      return await _getUserProfile(userId);
    } catch (e) {
      return null;
    }
  }

  // Actualizar perfil
  Future<User> updateProfile({
    String? name,
    String? surname,
    String? dni,
    String? phone,
    String? avatarUrl,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('No autenticado');

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (name != null) updates['name'] = name;
    if (surname != null) updates['surname'] = surname;
    if (dni != null) updates['dni'] = dni;
    if (phone != null) updates['phone'] = phone;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    await _client.from('users').update(updates).eq('auth_provider_id', userId);

    return _getUserProfile(userId);
  }
}
