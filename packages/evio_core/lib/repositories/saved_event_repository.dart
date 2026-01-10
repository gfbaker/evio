import 'package:evio_core/services/supabase_service.dart';
import 'package:evio_core/models/saved_event.dart';
import 'package:evio_core/models/event.dart';

class SavedEventRepository {
  final _client = SupabaseService.client;

  /// Guardar evento
  Future<SavedEvent> saveEvent(String eventId) async {
    final authUserId = _client.auth.currentUser?.id;
    if (authUserId == null) throw Exception('Usuario no autenticado');

    // Obtener user_id de la tabla users
    final userResponse = await _client
        .from('users')
        .select('id')
        .eq('auth_provider_id', authUserId)
        .single();

    final userId = userResponse['id'] as String;

    // Guardar evento
    final response = await _client
        .from('saved_events')
        .insert({
          'user_id': userId,
          'event_id': eventId,
        })
        .select()
        .single();

    return SavedEvent.fromJson(response);
  }

  /// Dejar de guardar evento
  Future<void> unsaveEvent(String eventId) async {
    final authUserId = _client.auth.currentUser?.id;
    if (authUserId == null) throw Exception('Usuario no autenticado');

    // Obtener user_id
    final userResponse = await _client
        .from('users')
        .select('id')
        .eq('auth_provider_id', authUserId)
        .single();

    final userId = userResponse['id'] as String;

    // Eliminar
    await _client
        .from('saved_events')
        .delete()
        .eq('user_id', userId)
        .eq('event_id', eventId);
  }

  /// Verificar si un evento está guardado
  Future<bool> isEventSaved(String eventId) async {
    final authUserId = _client.auth.currentUser?.id;
    if (authUserId == null) return false;

    try {
      final userResponse = await _client
          .from('users')
          .select('id')
          .eq('auth_provider_id', authUserId)
          .single();

      final userId = userResponse['id'] as String;

      final response = await _client
          .from('saved_events')
          .select('id')
          .eq('user_id', userId)
          .eq('event_id', eventId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Obtener mis eventos guardados (con datos del evento)
  Future<List<Event>> getMySavedEvents() async {
    final authUserId = _client.auth.currentUser?.id;
    if (authUserId == null) throw Exception('Usuario no autenticado');

    final userResponse = await _client
        .from('users')
        .select('id')
        .eq('auth_provider_id', authUserId)
        .single();

    final userId = userResponse['id'] as String;

    final response = await _client
        .from('saved_events')
        .select('''
          event_id,
          events!inner(*)
        ''')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => Event.fromJson(item['events'] as Map<String, dynamic>))
        .toList();
  }

  /// Obtener IDs de eventos guardados (más rápido para checks)
  Future<Set<String>> getMySavedEventIds() async {
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
          .from('saved_events')
          .select('event_id')
          .eq('user_id', userId);

      return (response as List)
          .map((item) => item['event_id'] as String)
          .toSet();
    } catch (e) {
      return {};
    }
  }
}
