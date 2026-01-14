import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user.dart';
import '../models/user_invitation.dart';

class UserRepository {
  final SupabaseClient _client;

  UserRepository([SupabaseClient? client])
    : _client = client ?? Supabase.instance.client;

  /// Obtener ID del usuario actual (db user id, no auth id)
  String? getCurrentUserId() {
    // Esto debe ejecutarse síncrono para evitar race conditions
    // Retorna null si no hay usuario autenticado
    // En un escenario real, esto debería estar cacheado en el provider
    return null; // TODO: Implementar cache local
  }

  /// Obtener usuario actual por auth ID
  Future<User?> getCurrentUser() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return null;

    final response = await _client
        .from('users')
        .select()
        .eq('auth_provider_id', authUser.id)
        .maybeSingle();

    if (response == null) return null;
    return User.fromJson(response);
  }

  /// Obtener ID del usuario actual de manera asíncrona
  Future<String?> getCurrentUserIdAsync() async {
    final user = await getCurrentUser();
    return user?.id;
  }

  /// Obtener usuario por ID
  Future<User?> getUserById(String id) async {
    final response = await _client
        .from('users')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return User.fromJson(response);
  }

  /// Buscar usuarios por nombre o email
  Future<List<User>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];

    // ✅ Buscar por first_name, last_name o email
    // NOTA: full_name NO existe en la DB, son first_name + last_name
    final response = await _client
        .from('users')
        .select()
        .or('first_name.ilike.%$query%,last_name.ilike.%$query%,email.ilike.%$query%')
        .limit(20);

    return (response as List).map((json) => User.fromJson(json)).toList();
  }

  /// Obtener usuarios de una productora
  Future<List<User>> getUsersByProducer(String producerId) async {
    final response = await _client
        .from('users')
        .select()
        .eq('producer_id', producerId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => User.fromJson(json)).toList();
  }

  /// Actualizar perfil de usuario
  Future<User> updateUser(User user) async {
    final response = await _client
        .from('users')
        .update(user.toJson())
        .eq('id', user.id)
        .select()
        .single();

    return User.fromJson(response);
  }

  /// Subir avatar del usuario a Supabase Storage
  /// Retorna la URL pública del avatar
  Future<String> uploadAvatar({
    required String userId,
    required String filePath,
    required List<int> fileBytes,
  }) async {
    // Extraer extensión del archivo
    final extension = filePath.split('.').last.toLowerCase();
    final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.$extension';
    
    // Subir a bucket 'avatars' (path es solo el filename, el bucket ya se llama 'avatars')
    final uploadPath = fileName;
    await _client.storage.from('avatars').uploadBinary(
      uploadPath,
      Uint8List.fromList(fileBytes), // Convertir a Uint8List
      fileOptions: const FileOptions(
        cacheControl: '3600',
        upsert: true,
      ),
    );

    // Obtener URL pública
    final publicUrl = _client.storage.from('avatars').getPublicUrl(uploadPath);
    
    return publicUrl;
  }

  /// Actualizar solo el avatar del usuario
  Future<User> updateAvatar(String userId, String avatarUrl) async {
    final response = await _client
        .from('users')
        .update({'avatar_url': avatarUrl})
        .eq('id', userId)
        .select()
        .single();

    return User.fromJson(response);
  }

  /// Eliminar usuario (solo admin puede eliminar colaboradores)
  Future<void> deleteUser(String userId) async {
    await _client.from('users').delete().eq('id', userId);
  }

  // ==================== INVITACIONES ====================

  /// Obtener invitaciones de una productora
  Future<List<UserInvitation>> getInvitationsByProducer(
    String producerId,
  ) async {
    final response = await _client
        .from('user_invitations')
        .select()
        .eq('producer_id', producerId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => UserInvitation.fromJson(json))
        .toList();
  }

  /// Crear invitación
  Future<UserInvitation> createInvitation(UserInvitation invitation) async {
    final json = invitation.toJson();
    if (json['id'] == null || json['id'] == '') {
      json.remove('id');
    }
    final response = await _client
        .from('user_invitations')
        .insert(invitation.toJson())
        .select()
        .single();

    return UserInvitation.fromJson(response);
  }

  /// Eliminar invitación
  Future<void> deleteInvitation(String invitationId) async {
    await _client.from('user_invitations').delete().eq('id', invitationId);
  }

  /// Actualizar invitación (ej: reenviar, cambiar status)
  Future<UserInvitation> updateInvitation(UserInvitation invitation) async {
    final response = await _client
        .from('user_invitations')
        .update(invitation.toJson())
        .eq('id', invitation.id)
        .select()
        .single();

    return UserInvitation.fromJson(response);
  }
}
