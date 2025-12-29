import '../constants/enums.dart';
import 'order_item.dart';

class Order {
  final String id;
  final String userId;
  final String eventId;
  final OrderStatus status;
  final int totalAmount; // centavos
  final String currency;
  final String? paymentProvider;
  final String? paymentId;
  final String? couponId;
  final int discountAmount;
  final DateTime? createdAt;
  final DateTime? paidAt;
  final DateTime? updatedAt;
  final List<OrderItem> items;

  const Order({
    required this.id,
    required this.userId,
    required this.eventId,
    this.status = OrderStatus.pending,
    required this.totalAmount,
    this.currency = 'ARS',
    this.paymentProvider,
    this.paymentId,
    this.couponId,
    this.discountAmount = 0,
    this.createdAt,
    this.paidAt,
    this.updatedAt,
    this.items = const [],
  });

  bool get isPaid => status == OrderStatus.paid;

  bool get isPending => status == OrderStatus.pending;

  int get subtotal => totalAmount + discountAmount;

  int get totalTickets => items.fold(0, (sum, item) => sum + item.quantity);

  String get formattedTotal {
    final pesos = totalAmount ~/ 100;
    return '\$${pesos.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      eventId: json['event_id'] as String,
      status: OrderStatus.fromString(json['status'] as String? ?? 'pending'),
      totalAmount: json['total_amount'] as int,
      currency: json['currency'] as String? ?? 'ARS',
      paymentProvider: json['payment_provider'] as String?,
      paymentId: json['payment_id'] as String?,
      couponId: json['coupon_id'] as String?,
      discountAmount: json['discount_amount'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'event_id': eventId,
      'status': status.name,
      'total_amount': totalAmount,
      'currency': currency,
      'payment_provider': paymentProvider,
      'payment_id': paymentId,
      'coupon_id': couponId,
      'discount_amount': discountAmount,
    };
  }
}
