class Coupon {
  final String id;
  final String? eventId;
  final String code;
  final String discountType; // 'percent' o 'fixed'
  final int discountValue;
  final int? maxUses;
  final int usedCount;
  final int? minAmount;
  final DateTime? expiresAt;
  final bool isActive;
  final DateTime createdAt;

  Coupon({
    required this.id,
    this.eventId,
    required this.code,
    required this.discountType,
    required this.discountValue,
    this.maxUses,
    required this.usedCount,
    this.minAmount,
    this.expiresAt,
    required this.isActive,
    required this.createdAt,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id'] as String,
      eventId: json['event_id'] as String?,
      code: json['code'] as String,
      discountType: json['discount_type'] as String,
      discountValue: json['discount_value'] as int,
      maxUses: json['max_uses'] as int?,
      usedCount: json['used_count'] as int? ?? 0,
      minAmount: json['min_amount'] as int?,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'code': code.toUpperCase(),
      'discount_type': discountType,
      'discount_value': discountValue,
      'max_uses': maxUses,
      'used_count': usedCount,
      'min_amount': minAmount,
      'expires_at': expiresAt?.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Coupon copyWith({
    String? id,
    String? eventId,
    String? code,
    String? discountType,
    int? discountValue,
    int? maxUses,
    int? usedCount,
    int? minAmount,
    DateTime? expiresAt,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Coupon(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      code: code ?? this.code,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      maxUses: maxUses ?? this.maxUses,
      usedCount: usedCount ?? this.usedCount,
      minAmount: minAmount ?? this.minAmount,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Helper para mostrar el descuento
  String get discountDisplay {
    if (discountType == 'percent') {
      return '$discountValue%';
    } else {
      return '\$${discountValue / 100}';
    }
  }

  /// Verificar si está expirado
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Verificar si está agotado
  bool get isExhausted {
    if (maxUses == null) return false;
    return usedCount >= maxUses!;
  }

  /// Verificar si está disponible
  bool get isAvailable {
    return isActive && !isExpired && !isExhausted;
  }
}
