import '../constants/enums.dart';
import 'event.dart';

/// Invitación de ticket enviada por un admin a un email
/// Puede estar en estado 'pending' (esperando usuario) o 'assigned' (tickets creados)
class TicketInvitation {
  final String id;
  final String eventId;
  final String senderId;
  final String recipientEmail;
  final String? recipientId;
  final int quantity;
  final bool isTransferable;
  final String? message;
  final TicketInvitationStatus status;
  final DateTime createdAt;
  final DateTime? assignedAt;
  final DateTime? cancelledAt;

  // Relaciones (cargadas con JOIN desde Supabase)
  final Event? event;

  const TicketInvitation({
    required this.id,
    required this.eventId,
    required this.senderId,
    required this.recipientEmail,
    this.recipientId,
    required this.quantity,
    required this.isTransferable,
    this.message,
    required this.status,
    required this.createdAt,
    this.assignedAt,
    this.cancelledAt,
    this.event,
  });

  bool get isPending => status == TicketInvitationStatus.pending;
  bool get isAssigned => status == TicketInvitationStatus.assigned;
  bool get isCancelled => status == TicketInvitationStatus.cancelled;

  factory TicketInvitation.fromJson(Map<String, dynamic> json) {
    return TicketInvitation(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      senderId: json['sender_id'] as String,
      recipientEmail: json['recipient_email'] as String,
      recipientId: json['recipient_id'] as String?,
      quantity: json['quantity'] as int,
      isTransferable: json['is_transferable'] as bool,
      message: json['message'] as String?,
      status: TicketInvitationStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      assignedAt: json['assigned_at'] != null
          ? DateTime.parse(json['assigned_at'] as String)
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      event: json['event'] != null
          ? Event.fromJson(json['event'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'sender_id': senderId,
      'recipient_email': recipientEmail,
      'recipient_id': recipientId,
      'quantity': quantity,
      'is_transferable': isTransferable,
      'message': message,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'assigned_at': assignedAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
    };
  }

  TicketInvitation copyWith({
    String? id,
    String? eventId,
    String? senderId,
    String? recipientEmail,
    String? recipientId,
    int? quantity,
    bool? isTransferable,
    String? message,
    TicketInvitationStatus? status,
    DateTime? createdAt,
    DateTime? assignedAt,
    DateTime? cancelledAt,
    Event? event,
  }) {
    return TicketInvitation(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      senderId: senderId ?? this.senderId,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      recipientId: recipientId ?? this.recipientId,
      quantity: quantity ?? this.quantity,
      isTransferable: isTransferable ?? this.isTransferable,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      assignedAt: assignedAt ?? this.assignedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      event: event ?? this.event,
    );
  }
}
