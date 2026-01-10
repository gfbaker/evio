import 'package:evio_core/services/supabase_service.dart';
import 'package:evio_core/models/ticket_invitation.dart';

class TicketInvitationRepository {
  final _client = SupabaseService.client;

  /// Obtener invitaciones de un evento (para admin)
  Future<List<TicketInvitation>> getInvitations(String eventId) async {
    try {
      final response = await _client
          .from('ticket_invitations')
          .select('''
            *,
            event:events(*)
          ''')
          .eq('event_id', eventId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => TicketInvitation.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener invitaciones: $e');
    }
  }

  /// Enviar invitación (admin)
  /// Llama a la función RPC de Supabase que maneja la creación
  Future<TicketInvitation> sendInvitation({
    required String eventId,
    required String recipientEmail,
    required int quantity,
    required bool isTransferable,
    String? message,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      // Obtener el sender_id de la tabla users
      final userResponse = await _client
          .from('users')
          .select('id')
          .eq('auth_provider_id', userId)
          .single();

      final senderId = userResponse['id'] as String;

      // Llamar a la función RPC que maneja toda la lógica
      final response = await _client.rpc(
        'send_ticket_invitation',
        params: {
          'p_event_id': eventId,
          'p_sender_id': senderId,
          'p_recipient_email': recipientEmail,
          'p_quantity': quantity,
          'p_is_transferable': isTransferable,
          'p_message': message,
        },
      );

      final invitationId = response as String;

      // Obtener la invitación creada
      final invitationResponse = await _client
          .from('ticket_invitations')
          .select('''
            *,
            event:events(*)
          ''')
          .eq('id', invitationId)
          .single();

      return TicketInvitation.fromJson(invitationResponse);
    } catch (e) {
      throw Exception('Error al enviar invitación: $e');
    }
  }

  /// Cancelar invitación (admin)
  Future<void> cancelInvitation(String invitationId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      // Verificar que la invitación le pertenece al usuario actual
      final userResponse = await _client
          .from('users')
          .select('id')
          .eq('auth_provider_id', userId)
          .single();

      final senderId = userResponse['id'] as String;

      // Obtener la invitación
      final invitation = await _client
          .from('ticket_invitations')
          .select('*')
          .eq('id', invitationId)
          .eq('sender_id', senderId)
          .single();

      if (invitation['status'] != 'pending') {
        throw Exception('Solo se pueden cancelar invitaciones pendientes');
      }

      // Actualizar estado
      await _client
          .from('ticket_invitations')
          .update({
            'status': 'cancelled',
            'cancelled_at': DateTime.now().toIso8601String(),
          })
          .eq('id', invitationId);

      // Si ya se asignaron tickets, eliminarlos
      if (invitation['status'] == 'assigned') {
        await _client
            .from('tickets')
            .delete()
            .eq('event_id', invitation['event_id'])
            .eq('owner_id', invitation['recipient_id'])
            .eq('is_invitation', true)
            .eq('status', 'valid');
      }
    } catch (e) {
      throw Exception('Error al cancelar invitación: $e');
    }
  }

  /// Obtener estadísticas de invitaciones de un evento
  Future<Map<String, int>> getInvitationStats(String eventId) async {
    try {
      final response = await _client
          .from('ticket_invitations')
          .select('status, quantity')
          .eq('event_id', eventId);

      final invitations = response as List;

      int totalSent = 0;
      int totalAssigned = 0;
      int totalPending = 0;
      int totalCancelled = 0;

      for (var inv in invitations) {
        final quantity = inv['quantity'] as int;
        final status = inv['status'] as String;

        totalSent += quantity;

        if (status == 'assigned') {
          totalAssigned += quantity;
        } else if (status == 'pending') {
          totalPending += quantity;
        } else if (status == 'cancelled') {
          totalCancelled += quantity;
        }
      }

      return {
        'total_sent': totalSent,
        'assigned': totalAssigned,
        'pending': totalPending,
        'cancelled': totalCancelled,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }
}
