class TicketType {
  final String id;
  final String eventId;
  final String name;
  final String? description; // ✅ NUEVO: Descripción de la tanda
  final int price; // centavos (ej: 2500 = €25.00)
  final int totalQuantity;
  final int soldQuantity;
  final int? maxPerPurchase;
  final int? displayOrder; // ✅ NUEVO: Orden de visualización
  final DateTime? saleStartAt;
  final DateTime? saleEndAt;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TicketType({
    required this.id,
    required this.eventId,
    required this.name,
    this.description,
    required this.price,
    required this.totalQuantity,
    this.soldQuantity = 0,
    this.maxPerPurchase,
    this.displayOrder,
    this.saleStartAt,
    this.saleEndAt,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  int get availableQuantity => totalQuantity - soldQuantity;
  bool get isSoldOut => soldQuantity >= totalQuantity;
  bool get isLowStock => availableQuantity > 0 && availableQuantity <= 10;

  bool get isOnSale {
    final now = DateTime.now();
    if (!isActive) return false;
    if (saleStartAt != null && now.isBefore(saleStartAt!)) return false;
    if (saleEndAt != null && now.isAfter(saleEndAt!)) return false;
    return !isSoldOut;
  }

  factory TicketType.fromJson(Map<String, dynamic> json) {
    return TicketType(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: json['price'] as int,
      totalQuantity: json['total_quantity'] as int,
      soldQuantity: json['sold_quantity'] as int? ?? 0,
      maxPerPurchase: json['max_per_purchase'],
      displayOrder: json['display_order'] as int?,
      saleStartAt: json['sale_start_at'] != null
          ? DateTime.parse(json['sale_start_at'] as String)
          : null,
      saleEndAt: json['sale_end_at'] != null
          ? DateTime.parse(json['sale_end_at'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
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
      'event_id': eventId,
      'name': name,
      'description': description,
      'price': price,
      'total_quantity': totalQuantity,
      'sold_quantity': soldQuantity,
      'max_per_purchase': maxPerPurchase,
      'display_order': displayOrder,
      'sale_start_at': saleStartAt?.toIso8601String(),
      'sale_end_at': saleEndAt?.toIso8601String(),
      'is_active': isActive,
    };
  }

  TicketType copyWith({
    String? id,
    String? eventId,
    String? name,
    String? description,
    int? price,
    int? totalQuantity,
    int? soldQuantity,
    int? maxPerPurchase,
    int? displayOrder,
    DateTime? saleStartAt,
    DateTime? saleEndAt,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TicketType(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      soldQuantity: soldQuantity ?? this.soldQuantity,
      maxPerPurchase: maxPerPurchase ?? this.maxPerPurchase,
      displayOrder: displayOrder ?? this.displayOrder,
      saleStartAt: saleStartAt ?? this.saleStartAt,
      saleEndAt: saleEndAt ?? this.saleEndAt,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
