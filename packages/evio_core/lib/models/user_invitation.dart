import 'package:evio_core/constants/enums.dart';

class UserInvitation {
  final String id; // ← AGREGAR
  final String producerId;
  final String? invitedBy;
  final String? firstName;
  final String? lastName;
  final String email;
  final UserRole role;
  final UserInvitationStatus status;
  final String? token;
  final DateTime? expiresAt;
  final DateTime createdAt;

  const UserInvitation({
    required this.id, // ← AGREGAR
    required this.producerId,
    this.invitedBy,
    this.firstName,
    this.lastName,
    required this.email,
    required this.role,
    required this.status,
    this.token,
    this.expiresAt,
    required this.createdAt,
  });

  String get fullName {
    if (firstName == null && lastName == null) return email;
    return [firstName, lastName].whereType<String>().join(' ');
  }

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isPending => status == UserInvitationStatus.pending;

  factory UserInvitation.fromJson(Map<String, dynamic> json) {
    return UserInvitation(
      id: json['id'] as String, // ← AGREGAR
      producerId: json['producer_id'] as String,
      invitedBy: json['invited_by'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      email: json['email'] as String,
      role: UserRole.fromString(json['role'] as String? ?? 'collaborator'),
      status: UserInvitationStatus.fromString(json['status'] as String),
      token: json['token'] as String?,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'producer_id': producerId,
      'invited_by': invitedBy,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'role': role.name,
      'status': status.value,
      'token': token,
      'expires_at': expiresAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };

    // Solo incluir id si no está vacío
    if (id.isNotEmpty) {
      map['id'] = id;
    }

    return map;
  }

  UserInvitation copyWith({
    String? id, // ← AGREGAR
    String? producerId,
    String? invitedBy,
    String? firstName,
    String? lastName,
    String? email,
    UserRole? role,
    UserInvitationStatus? status,
    String? token,
    DateTime? expiresAt,
    DateTime? createdAt,
  }) {
    return UserInvitation(
      id: id ?? this.id, // ← AGREGAR
      producerId: producerId ?? this.producerId,
      invitedBy: invitedBy ?? this.invitedBy,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      token: token ?? this.token,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
