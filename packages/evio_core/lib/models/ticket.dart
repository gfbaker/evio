import '../constants/enums.dart';
import 'event.dart';
import 'ticket_type.dart';

class Ticket {
  final String id;
  final String eventId;
  final String ticketTypeId;
  final String? orderId;
  final String ownerId;
  final String? originalOwnerId;
  final String qrSecret;
  final TicketStatus status;
  final bool isInvitation;
  final bool transferAllowed;
  final int transferCount;
  final DateTime? usedAt;
  final String? usedByDni;
  final DateTime? createdAt;

  // Relaciones (cargadas con JOIN desde Supabase)
  final Event? event;
  final TicketType? ticketType;

  const Ticket({
    required this.id,
    required this.eventId,
    required this.ticketTypeId,
    this.orderId,
    required this.ownerId,
    this.originalOwnerId,
    required this.qrSecret,
    this.status = TicketStatus.valid,
    this.isInvitation = false,
    this.transferAllowed = false,
    this.transferCount = 0,
    this.usedAt,
    this.usedByDni,
    this.createdAt,
    this.event,
    this.ticketType,
  });

  bool get isUsable => status == TicketStatus.valid;

  bool get isUsed => status == TicketStatus.used;

  bool get canTransfer => transferAllowed && isUsable && transferCount < 3;

  /// Datos para generar el QR
  String get qrData => '$id|$qrSecret';

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      ticketTypeId: json['ticket_type_id'] as String,
      orderId: json['order_id'] as String?,
      ownerId: json['owner_id'] as String,
      originalOwnerId: json['original_owner_id'] as String?,
      qrSecret: json['qr_secret'] as String,
      status: TicketStatus.fromString(json['status'] as String? ?? 'valid'),
      isInvitation: json['is_invitation'] as bool? ?? false,
      transferAllowed: json['transfer_allowed'] as bool? ?? false,
      transferCount: json['transfer_count'] as int? ?? 0,
      usedAt: json['used_at'] != null
          ? DateTime.parse(json['used_at'] as String)
          : null,
      usedByDni: json['used_by_dni'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      event: json['event'] != null
          ? Event.fromJson(json['event'] as Map<String, dynamic>)
          : null,
      ticketType: json['ticket_type'] != null
          ? TicketType.fromJson(json['ticket_type'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'ticket_type_id': ticketTypeId,
      'order_id': orderId,
      'owner_id': ownerId,
      'original_owner_id': originalOwnerId,
      'qr_secret': qrSecret,
      'status': status.name,
      'is_invitation': isInvitation,
      'transfer_allowed': transferAllowed,
      'transfer_count': transferCount,
      'used_at': usedAt?.toIso8601String(),
      'used_by_dni': usedByDni,
    };
  }
}
