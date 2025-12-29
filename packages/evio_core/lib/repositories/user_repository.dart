import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user.dart';
import '../models/user_invitation.dart';

class UserRepository {
  final SupabaseClient _client;

  UserRepository([SupabaseClient? client])
    : _client = client ?? Supabase.instance.client;

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
