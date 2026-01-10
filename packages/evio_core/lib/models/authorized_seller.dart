class AuthorizedSeller {
  final String id;
  final String producerId;
  final String userId;
  final double commissionPercentage;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AuthorizedSeller({
    required this.id,
    required this.producerId,
    required this.userId,
    required this.commissionPercentage,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AuthorizedSeller.fromJson(Map<String, dynamic> json) {
    return AuthorizedSeller(
      id: json['id'] as String,
      producerId: json['producer_id'] as String,
      userId: json['user_id'] as String,
      commissionPercentage: (json['commission_percentage'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'producer_id': producerId,
      'user_id': userId,
      'commission_percentage': commissionPercentage,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  AuthorizedSeller copyWith({
    String? id,
    String? producerId,
    String? userId,
    double? commissionPercentage,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AuthorizedSeller(
      id: id ?? this.id,
      producerId: producerId ?? this.producerId,
      userId: userId ?? this.userId,
      commissionPercentage: commissionPercentage ?? this.commissionPercentage,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
