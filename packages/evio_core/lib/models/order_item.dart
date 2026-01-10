/// Item de una orden (para checkout)
class OrderItem {
  final String tierId;
  final int quantity;
  final int unitPrice;

  OrderItem({
    required this.tierId,
    required this.quantity,
    required this.unitPrice,
  });

  Map<String, dynamic> toJson() {
    return {
      'tier_id': tierId,
      'quantity': quantity,
      'unit_price': unitPrice,
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      tierId: json['tier_id'] as String,
      quantity: json['quantity'] as int,
      unitPrice: json['unit_price'] as int,
    );
  }
}
