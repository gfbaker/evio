import '../constants/enums.dart';
import 'ticket.dart';

/// Transferencia de ticket entre usuarios
/// Permite que un usuario reenvíe su ticket a otro email
class TicketTransfer {
  final String id;
  final String ticketId;
  final String fromUserId;
  final String toEmail;
  final String? toUserId;
  final String? message;
  final TicketTransferStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  // Relaciones (cargadas con JOIN desde Supabase)
  final Ticket? ticket;

  const TicketTransfer({
    required this.id,
    required this.ticketId,
    required this.fromUserId,
    required this.toEmail,
    this.toUserId,
    this.message,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.cancelledAt,
    this.ticket,
  });

  bool get isPending => status == TicketTransferStatus.pending;
  bool get isCompleted => status == TicketTransferStatus.completed;
  bool get isCancelled => status == TicketTransferStatus.cancelled;

  factory TicketTransfer.fromJson(Map<String, dynamic> json) {
    return TicketTransfer(
      id: json['id'] as String,
      ticketId: json['ticket_id'] as String,
      fromUserId: json['from_user_id'] as String,
      toEmail: json['to_email'] as String,
      toUserId: json['to_user_id'] as String?,
      message: json['message'] as String?,
      status: TicketTransferStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      ticket: json['ticket'] != null
          ? Ticket.fromJson(json['ticket'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_id': ticketId,
      'from_user_id': fromUserId,
      'to_email': toEmail,
      'to_user_id': toUserId,
      'message': message,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
    };
  }

  TicketTransfer copyWith({
    String? id,
    String? ticketId,
    String? fromUserId,
    String? toEmail,
    String? toUserId,
    String? message,
    TicketTransferStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    Ticket? ticket,
  }) {
    return TicketTransfer(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      fromUserId: fromUserId ?? this.fromUserId,
      toEmail: toEmail ?? this.toEmail,
      toUserId: toUserId ?? this.toUserId,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      ticket: ticket ?? this.ticket,
    );
  }
}
