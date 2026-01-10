import '../constants/enums.dart';

class User {
  final String id;
  final String authProviderId;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? dni; // Solo puede ser establecido una vez
  final DateTime? birthDate; // Solo puede ser establecido una vez
  final String? gender; // 'male', 'female', 'other', 'prefer_not_to_say'
  final String? phone;
  final UserRole role;
  final String? avatarUrl;
  final bool isActive;
  final String? producerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.authProviderId,
    required this.email,
    this.firstName,
    this.lastName,
    this.dni,
    this.birthDate,
    this.gender,
    this.phone,
    this.role = UserRole.fan,
    this.avatarUrl,
    this.isActive = true,
    this.producerId,
    this.createdAt,
    this.updatedAt,
  });

  String get fullName {
    if (firstName == null && lastName == null) return email;
    return [firstName, lastName].whereType<String>().join(' ');
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isCollaborator => role == UserRole.collaborator;

  bool get hasCompleteProfile =>
      firstName != null &&
      firstName!.isNotEmpty &&
      lastName != null &&
      lastName!.isNotEmpty;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      authProviderId: json['auth_provider_id'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      dni: json['dni'] as String?,
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'] as String)
          : null,
      gender: json['gender'] as String?,
      phone: json['phone'] as String?,
      role: UserRole.fromString(json['role'] as String? ?? 'fan'),
      avatarUrl: json['avatar_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      producerId: json['producer_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auth_provider_id': authProviderId,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'dni': dni,
      'birth_date': birthDate?.toIso8601String().split('T')[0], // Solo fecha YYYY-MM-DD
      'gender': gender,
      'phone': phone,
      'role': role.name,
      'avatar_url': avatarUrl,
      'is_active': isActive,
      'producer_id': producerId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? authProviderId,
    String? email,
    String? firstName,
    String? lastName,
    String? dni,
    DateTime? birthDate,
    String? gender,
    String? phone,
    UserRole? role,
    String? avatarUrl,
    bool? isActive,
    String? producerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      authProviderId: authProviderId ?? this.authProviderId,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dni: dni ?? this.dni,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
      producerId: producerId ?? this.producerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
