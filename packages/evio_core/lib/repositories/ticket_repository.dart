import 'package:evio_core/services/supabase_service.dart';
import 'package:evio_core/models/ticket.dart';

class TicketRepository {
  final _client = SupabaseService.client;

  // ============================================
  // TICKET TYPES/TIERS - DEPRECATED
  // ============================================
  // Los métodos de gestión de ticket types están deprecated.
  // Usar EventRepository.getEventTicketCategories() para el nuevo sistema.

  // ============================================
  // TICKETS INDIVIDUALES
  // ============================================

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
            tier:ticket_tiers(*)
          ''')
              .eq('owner_id', dbUserId)
              .order('created_at', ascending: false)
        : await _client
              .from('tickets')
              .select('''
            *,
            event:events(*),
            tier:ticket_tiers(*)
          ''')
              .eq('owner_id', dbUserId)
              .eq('status', 'valid')
              .order('created_at', ascending: false);

    // 🟠 DEBUG: Mostrar datos raw
    print('🟠 DEBUG: Tickets response:');
    for (var ticket in (response as List)) {
      print('Ticket ID: ${ticket['id']}');
      print('Event: ${ticket['event']}');
      print('Tier: ${ticket['tier']}');
      print('---');
    }

    // Parsear con manejo de errores
    final List<Ticket> tickets = [];
    for (var ticketJson in (response as List)) {
      try {
        tickets.add(Ticket.fromJson(ticketJson));
      } catch (e, stackTrace) {
        print('❌ Error parseando ticket ${ticketJson['id']}: $e');
        print('❌ Stack: $stackTrace');
        print('❌ JSON completo: $ticketJson');
        rethrow;
      }
    }
    return tickets;
  }

  /// Obtener ticket por ID
  Future<Ticket?> getTicketById(String id) async {
    final response = await _client
        .from('tickets')
        .select('''
          *,
          event:events(*),
          tier:ticket_tiers(*)
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
          tier:ticket_tiers(*),
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

  // ============================================
  // TRANSFERENCIAS V2 (con ticket_transfers)
  // ============================================

  /// Transferir ticket directamente (sin pending)
  Future<Ticket> transferTicket({
    required String ticketId,
    required String toUserId,
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

    // Obtener email del usuario destino
    final toUserResponse = await _client
        .from('users')
        .select('email')
        .eq('id', toUserId)
        .single();

    final toUserEmail = toUserResponse['email'] as String;

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

    // Crear registro en ticket_transfers
    await _client.from('ticket_transfers').insert({
      'ticket_id': ticketId,
      'from_user_id': dbFromUserId,
      'to_user_id': toUserId,
      'to_email': toUserEmail, // ✅ Campo obligatorio
      'status': 'completed',
      'completed_at': DateTime.now().toIso8601String(),
    });

    // Transferir ownership del ticket
    await _client.from('tickets').update({
      'owner_id': toUserId,
      'transfer_count': ticket.transferCount + 1,
    }).eq('id', ticketId);

    // Retornar ticket actualizado
    final updatedTicket = await getTicketById(ticketId);
    return updatedTicket!;
  }

  /// Recuperar ticket transferido (cancelar transferencia)
  Future<Ticket> recoverTransferredTicket(String ticketId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    final userResponse = await _client
        .from('users')
        .select('id')
        .eq('auth_provider_id', userId)
        .single();

    final dbUserId = userResponse['id'] as String;

    // Buscar última transferencia del ticket
    final transferResponse = await _client
        .from('ticket_transfers')
        .select('*')
        .eq('ticket_id', ticketId)
        .eq('from_user_id', dbUserId)
        .eq('status', 'completed')
        .order('completed_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (transferResponse == null) {
      throw Exception('No se encontró transferencia para recuperar');
    }

    // Verificar que el ticket no haya sido usado
    final ticket = await getTicketById(ticketId);
    if (ticket == null) {
      throw Exception('Ticket no encontrado');
    }

    if (ticket.status.name != 'valid') {
      throw Exception('Solo se pueden recuperar tickets válidos');
    }

    // Cancelar transferencia
    await _client.from('ticket_transfers').update({
      'status': 'cancelled',
      'cancelled_at': DateTime.now().toIso8601String(),
    }).eq('id', transferResponse['id']);

    // Devolver ownership al usuario original
    await _client.from('tickets').update({
      'owner_id': dbUserId,
    }).eq('id', ticketId);

    // Retornar ticket actualizado
    final updatedTicket = await getTicketById(ticketId);
    return updatedTicket!;
  }

  /// Cancelar transferencia pendiente
  Future<void> cancelTransfer(String transferId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    final userResponse = await _client
        .from('users')
        .select('id')
        .eq('auth_provider_id', userId)
        .single();

    final dbUserId = userResponse['id'] as String;

    // Obtener la transferencia
    final transfer = await _client
        .from('ticket_transfers')
        .select('*')
        .eq('id', transferId)
        .eq('from_user_id', dbUserId)
        .single();

    if (transfer['status'] != 'pending') {
      throw Exception('Solo se pueden cancelar transferencias pendientes');
    }

    // Cancelar transferencia
    await _client.from('ticket_transfers').update({
      'status': 'cancelled',
      'cancelled_at': DateTime.now().toIso8601String(),
    }).eq('id', transferId);
  }

  /// Obtener transferencias pendientes del usuario
  Future<List<Map<String, dynamic>>> getPendingTransfers() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    final userResponse = await _client
        .from('users')
        .select('id')
        .eq('auth_provider_id', userId)
        .single();

    final dbUserId = userResponse['id'] as String;

    final response = await _client
        .from('ticket_transfers')
        .select('''
          *,
          ticket:tickets(
            *,
            event:events(*),
            tier:ticket_tiers(*)
          )
        ''')
        .eq('from_user_id', dbUserId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (response as List).cast<Map<String, dynamic>>();
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
          tier:ticket_tiers(*),
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
