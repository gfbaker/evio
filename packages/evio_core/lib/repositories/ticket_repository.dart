import 'package:evio_core/services/supabase_service.dart';
import 'package:evio_core/models/ticket.dart';
import 'package:evio_core/models/ticket_type.dart';

class TicketRepository {
  final _client = SupabaseService.client;

  // ============================================
  // TICKET TYPES (LOTES)
  // ============================================

  /// Obtener tipos de ticket de un evento
  Future<List<TicketType>> getTicketTypes(String eventId) async {
    final response = await _client
        .from('ticket_types')
        .select()
        .eq('event_id', eventId)
        .order('sort_order', ascending: true);

    return (response as List).map((e) => TicketType.fromJson(e)).toList();
  }

  /// Obtener tipos de ticket disponibles (con stock y en venta)
  Future<List<TicketType>> getAvailableTicketTypes(String eventId) async {
    final now = DateTime.now().toIso8601String();

    final response = await _client
        .from('ticket_types')
        .select()
        .eq('event_id', eventId)
        .eq('is_invitation_only', false)
        .lt('sold_quantity', 'total_quantity')
        .or('sale_start_at.is.null,sale_start_at.lte.$now')
        .or('sale_end_at.is.null,sale_end_at.gte.$now')
        .order('sort_order', ascending: true);

    return (response as List).map((e) => TicketType.fromJson(e)).toList();
  }

  /// Crear tipo de ticket (producer)
  Future<TicketType> createTicketType(TicketType ticketType) async {
    final response = await _client
        .from('ticket_types')
        .insert(ticketType.toJson())
        .select()
        .single();

    return TicketType.fromJson(response);
  }

  /// Actualizar tipo de ticket
  Future<TicketType> updateTicketType(TicketType ticketType) async {
    final response = await _client
        .from('ticket_types')
        .update(ticketType.toJson())
        .eq('id', ticketType.id)
        .select()
        .single();

    return TicketType.fromJson(response);
  }

  /// Eliminar tipo de ticket
  Future<void> deleteTicketType(String id) async {
    await _client.from('ticket_types').delete().eq('id', id);
  }

  // ============================================
  // TICKETS INDIVIDUALES
  // ============================================

  /// Obtener mis tickets
  /// Obtener mis tickets
  Future<List<Ticket>> getMyTickets({
    bool includeUsed = false,
    bool includePast = false,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    final userResponse = await _client
        .from('users')
        .select('id')
        .eq('auth_provider_id', userId)
        .single();

    final dbUserId = userResponse['id'] as String;

    // Construir query condicionalmente
    final response = includeUsed
        ? await _client
              .from('tickets')
              .select('''
            *,
            event:events(*),
            ticket_type:ticket_types(*)
          ''')
              .eq('owner_id', dbUserId)
              .order('created_at', ascending: false)
        : await _client
              .from('tickets')
              .select('''
            *,
            event:events(*),
            ticket_type:ticket_types(*)
          ''')
              .eq('owner_id', dbUserId)
              .eq('status', 'valid')
              .order('created_at', ascending: false);

    return (response as List).map((e) => Ticket.fromJson(e)).toList();
  }

  /// Obtener ticket por ID
  Future<Ticket?> getTicketById(String id) async {
    final response = await _client
        .from('tickets')
        .select('''
          *,
          event:events(*),
          ticket_type:ticket_types(*)
        ''')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Ticket.fromJson(response);
  }

  /// Obtener ticket por QR secret (para validación)
  Future<Ticket?> getTicketByQR(String qrSecret) async {
    final response = await _client
        .from('tickets')
        .select('''
          *,
          event:events(*),
          ticket_type:ticket_types(*),
          owner:users(*)
        ''')
        .eq('qr_secret', qrSecret)
        .maybeSingle();

    if (response == null) return null;
    return Ticket.fromJson(response);
  }

  // ============================================
  // VALIDACIÓN EN PUERTA
  // ============================================

  /// Validar ticket (portero)
  Future<Ticket> validateTicket({
    required String ticketId,
    required String qrSecret,
    required String dni,
  }) async {
    final validatorId = _client.auth.currentUser?.id;
    if (validatorId == null) throw Exception('Usuario no autenticado');

    // Obtener ticket
    final ticket = await getTicketByQR(qrSecret);
    if (ticket == null) {
      throw Exception('Ticket no encontrado');
    }

    if (ticket.id != ticketId) {
      throw Exception('QR no corresponde al ticket');
    }

    if (ticket.status.name != 'valid') {
      throw Exception('Ticket ya fue usado o está cancelado');
    }

    // Obtener el validator user_id
    final validatorResponse = await _client
        .from('users')
        .select('id')
        .eq('auth_provider_id', validatorId)
        .single();

    final dbValidatorId = validatorResponse['id'] as String;

    // Usar transaction para atomicidad
    try {
      // 1. Marcar ticket como usado
      await _client
          .from('tickets')
          .update({
            'status': 'used',
            'used_at': DateTime.now().toIso8601String(),
            'used_by_dni': dni,
          })
          .eq('id', ticketId)
          .eq('status', 'valid'); // Solo si sigue válido (evita race condition)

      // 2. Registrar entrada
      await _client.from('entries').insert({
        'ticket_id': ticketId,
        'validated_by': dbValidatorId,
        'dni_validated': dni,
        'entry_at': DateTime.now().toIso8601String(),
      });

      // Retornar ticket actualizado
      final updatedTicket = await getTicketById(ticketId);
      return updatedTicket!;
    } catch (e) {
      throw Exception('Error al validar ticket: $e');
    }
  }

  // ============================================
  // TRANSFERENCIAS
  // ============================================

  /// Transferir ticket
  Future<Ticket> transferTicket({
    required String ticketId,
    required String toEmail,
    String? message,
  }) async {
    final fromUserId = _client.auth.currentUser?.id;
    if (fromUserId == null) throw Exception('Usuario no autenticado');

    // Obtener el from_user_id de la tabla users
    final fromUserResponse = await _client
        .from('users')
        .select('id')
        .eq('auth_provider_id', fromUserId)
        .single();

    final dbFromUserId = fromUserResponse['id'] as String;

    // Verificar que el ticket existe y le pertenece
    final ticket = await getTicketById(ticketId);
    if (ticket == null) {
      throw Exception('Ticket no encontrado');
    }

    if (ticket.ownerId != dbFromUserId) {
      throw Exception('No eres el dueño del ticket');
    }

    if (!ticket.transferAllowed) {
      throw Exception('Este ticket no permite transferencias');
    }

    if (ticket.status.name != 'valid') {
      throw Exception('Solo se pueden transferir tickets válidos');
    }

    // Buscar usuario destino
    final toUserResponse = await _client
        .from('users')
        .select('id')
        .eq('email', toEmail)
        .maybeSingle();

    final toUserId = toUserResponse?['id'] as String?;

    // Crear invitación
    await _client.from('invitations').insert({
      'ticket_id': ticketId,
      'from_user_id': dbFromUserId,
      'to_user_id': toUserId,
      'to_email': toEmail,
      'transfer_allowed': ticket.transferAllowed,
      'message': message,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });

    // TODO: Enviar email/notificación

    return ticket;
  }

  /// Aceptar invitación
  Future<Ticket> acceptInvitation(String invitationId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    final userResponse = await _client
        .from('users')
        .select('id')
        .eq('auth_provider_id', userId)
        .single();

    final dbUserId = userResponse['id'] as String;

    // Obtener invitación
    final invitationResponse = await _client
        .from('invitations')
        .select('*, ticket:tickets(*)')
        .eq('id', invitationId)
        .eq('to_user_id', dbUserId)
        .eq('status', 'pending')
        .single();

    final ticketId = invitationResponse['ticket_id'] as String;

    try {
      // 1. Actualizar ticket (transferir ownership)
      await _client
          .from('tickets')
          .update({
            'owner_id': dbUserId,
            'transfer_count':
                (invitationResponse['ticket']['transfer_count'] as int) + 1,
          })
          .eq('id', ticketId);

      // 2. Marcar invitación como aceptada
      await _client
          .from('invitations')
          .update({
            'status': 'accepted',
            'accepted_at': DateTime.now().toIso8601String(),
          })
          .eq('id', invitationId);

      final ticket = await getTicketById(ticketId);
      return ticket!;
    } catch (e) {
      throw Exception('Error al aceptar invitación: $e');
    }
  }

  /// Rechazar invitación
  Future<void> rejectInvitation(String invitationId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    final userResponse = await _client
        .from('users')
        .select('id')
        .eq('auth_provider_id', userId)
        .single();

    final dbUserId = userResponse['id'] as String;

    await _client
        .from('invitations')
        .update({'status': 'rejected'})
        .eq('id', invitationId)
        .eq('to_user_id', dbUserId)
        .eq('status', 'pending');
  }

  /// Obtener mis invitaciones pendientes
  Future<List<Map<String, dynamic>>> getPendingInvitations() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    final userResponse = await _client
        .from('users')
        .select('id')
        .eq('auth_provider_id', userId)
        .single();

    final dbUserId = userResponse['id'] as String;

    final response = await _client
        .from('invitations')
        .select('''
          *,
          ticket:tickets(*),
          event:tickets(event:events(*)),
          from_user:users!from_user_id(*)
        ''')
        .eq('to_user_id', dbUserId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (response as List).cast<Map<String, dynamic>>();
  }

  // ============================================
  // ADMIN - LISTA DE ASISTENTES
  // ============================================

  /// Obtener todos los tickets de un evento (producer)
  Future<List<Ticket>> getEventTickets(String eventId) async {
    final response = await _client
        .from('tickets')
        .select('''
          *,
          ticket_type:ticket_types(*),
          owner:users(*),
          entry:entries(*)
        ''')
        .eq('event_id', eventId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => Ticket.fromJson(e)).toList();
  }

  /// Stats de tickets del evento
  Future<Map<String, int>> getEventTicketStats(String eventId) async {
    final response = await _client
        .from('tickets')
        .select('status')
        .eq('event_id', eventId);

    final tickets = response as List;

    return {
      'total': tickets.length,
      'valid': tickets.where((t) => t['status'] == 'valid').length,
      'used': tickets.where((t) => t['status'] == 'used').length,
      'cancelled': tickets.where((t) => t['status'] == 'cancelled').length,
    };
  }
}
