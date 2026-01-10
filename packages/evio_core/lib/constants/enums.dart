// Enums compartidos para Evio Club
// Mapean directamente con los tipos de la base de datos

enum UserRole {
  fan,
  admin,
  collaborator;

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.collaborator:
        return 'Colaborador';
      case UserRole.fan:
        return 'Fan';
    }
  }

  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'collaborator':
        return UserRole.collaborator;
      case 'fan':
      default:
        return UserRole.fan;
    }
  }
}

enum TicketStatus {
  valid,
  used,
  cancelled,
  expired;

  static TicketStatus fromString(String value) {
    return TicketStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TicketStatus.valid,
    );
  }

  bool get isUsable => this == TicketStatus.valid;
}

enum OrderStatus {
  pending,
  paid,
  failed,
  refunded,
  cancelled; // ← Agregar esta línea

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OrderStatus.pending,
    );
  }

  bool get isSuccess => this == OrderStatus.paid;
}

enum UserInvitationStatus {
  pending('pending'),
  accepted('accepted'),
  expired('expired');

  final String value;
  const UserInvitationStatus(this.value);

  static UserInvitationStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return UserInvitationStatus.pending;
      case 'accepted':
        return UserInvitationStatus.accepted;
      case 'expired':
        return UserInvitationStatus.expired;
      default:
        return UserInvitationStatus.pending;
    }
  }
}

enum DiscountType {
  percent,
  fixed;

  static DiscountType fromString(String value) {
    return DiscountType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DiscountType.percent,
    );
  }
}

enum TicketInvitationStatus {
  pending,
  assigned,
  cancelled;

  static TicketInvitationStatus fromString(String value) {
    return TicketInvitationStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TicketInvitationStatus.pending,
    );
  }
}

enum TicketTransferStatus {
  pending,
  completed,
  cancelled;

  static TicketTransferStatus fromString(String value) {
    return TicketTransferStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TicketTransferStatus.pending,
    );
  }
}
