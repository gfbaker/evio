/// Item de una orden (para checkout)
class OrderItem {
  final String ticketTypeId;
  final int quantity;
  final int unitPrice;

  OrderItem({
    required this.ticketTypeId,
    required this.quantity,
    required this.unitPrice,
  });

  Map<String, dynamic> toJson() {
    return {
      'ticket_type_id': ticketTypeId,
      'quantity': quantity,
      'unit_price': unitPrice,
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      ticketTypeId: json['ticket_type_id'] as String,
      quantity: json['quantity'] as int,
      unitPrice: json['unit_price'] as int,
    );
  }
}
