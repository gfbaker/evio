import 'package:evio_core/services/supabase_service.dart';
import 'package:evio_core/models/follow.dart';
import 'package:evio_core/models/user.dart';

class FollowRepository {
  final _client = SupabaseService.client;

  /// Seguir a un usuario
  Future<Follow> followUser(String followingId) async {
    final authUserId = _client.auth.currentUser?.id;
    if (authUserId == null) throw Exception('Usuario no autenticado');

    // Obtener follower_id de la tabla users
    final userResponse = await _client
        .from('users')
        .select('id')
        .eq('auth_provider_id', authUserId)
        .single();

    final followerId = userResponse['id'] as String;

    // No auto-seguirse
    if (followerId == followingId) {
      throw Exception('No puedes seguirte a ti mismo');
    }

    // Seguir
    final response = await _client
        .from('follows')
        .insert({
          'follower_id': followerId,
          'following_id': followingId,
        })
        .select()
        .single();

    return Follow.fromJson(response);
  }

  /// Dejar de seguir a un usuario
  Future<void> unfollowUser(String followingId) async {
    final authUserId = _client.auth.currentUser?.id;
    if (authUserId == null) throw Exception('Usuario no autenticado');

    // Obtener follower_id
    final userResponse = await _client
        .from('users')
        .select('id')
        .eq('auth_provider_id', authUserId)
        .single();

    final followerId = userResponse['id'] as String;

    // Dejar de seguir
    await _client
        .from('follows')
        .delete()
        .eq('follower_id', followerId)
        .eq('following_id', followingId);
  }

  /// Verificar si sigo a un usuario
  Future<bool> isFollowing(String followingId) async {
    final authUserId = _client.auth.currentUser?.id;
    if (authUserId == null) return false;

    try {
      final userResponse = await _client
          .from('users')
          .select('id')
          .eq('auth_provider_id', authUserId)
          .single();

      final followerId = userResponse['id'] as String;

      final response = await _client
          .from('follows')
          .select('id')
          .eq('follower_id', followerId)
          .eq('following_id', followingId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Obtener mis seguidos (usuarios que yo sigo)
  Future<List<User>> getMyFollowing() async {
    final authUserId = _client.auth.currentUser?.id;
    if (authUserId == null) throw Exception('Usuario no autenticado');

    final userResponse = await _client
        .from('users')
        .select('id')
        .eq('auth_provider_id', authUserId)
        .single();

    final userId = userResponse['id'] as String;

    final response = await _client
        .from('follows')
        .select('''
          following_id,
          users!follows_following_id_fkey(*)
        ''')
        .eq('follower_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => User.fromJson(item['users'] as Map<String, dynamic>))
        .toList();
  }

  /// Obtener mis seguidores (usuarios que me siguen)
  Future<List<User>> getMyFollowers() async {
    final authUserId = _client.auth.currentUser?.id;
    if (authUserId == null) throw Exception('Usuario no autenticado');

    final userResponse = await _client
        .from('users')
        .select('id')
        .eq('auth_provider_id', authUserId)
        .single();

    final userId = userResponse['id'] as String;

    final response = await _client
        .from('follows')
        .select('''
          follower_id,
          users!follows_follower_id_fkey(*)
        ''')
        .eq('following_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => User.fromJson(item['users'] as Map<String, dynamic>))
        .toList();
  }

  /// Obtener IDs de usuarios que sigo (para checks rápidos)
  Future<Set<String>> getMyFollowingIds() async {
    final authUserId = _client.auth.currentUser?.id;
    if (authUserId == null) return {};

    try {
      final userResponse = await _client
          .from('users')
          .select('id')
          .eq('auth_provider_id', authUserId)
          .single();

      final userId = userResponse['id'] as String;

      final response = await _client
          .from('follows')
          .select('following_id')
          .eq('follower_id', userId);

      return (response as List)
          .map((item) => item['following_id'] as String)
          .toSet();
    } catch (e) {
      return {};
    }
  }

  /// Obtener contadores de un usuario
  Future<Map<String, int>> getUserStats(String userId) async {
    try {
      final followersCount = await _client
          .rpc('get_followers_count', params: {'p_user_id': userId});

      final followingCount = await _client
          .rpc('get_following_count', params: {'p_user_id': userId});

      return {
        'followers': followersCount as int,
        'following': followingCount as int,
      };
    } catch (e) {
      return {
        'followers': 0,
        'following': 0,
      };
    }
  }
}
