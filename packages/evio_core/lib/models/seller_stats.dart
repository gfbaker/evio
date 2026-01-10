class SellerStats {
  final String sellerId;
  final String sellerName;
  final String sellerEmail;
  final int totalOrders;
  final int totalTickets;
  final int totalRevenue;

  const SellerStats({
    required this.sellerId,
    required this.sellerName,
    required this.sellerEmail,
    required this.totalOrders,
    required this.totalTickets,
    required this.totalRevenue,
  });

  factory SellerStats.fromJson(Map<String, dynamic> json) {
    return SellerStats(
      sellerId: json['seller_id'] as String? ?? '',
      sellerName: json['seller_name'] as String? ?? 'Unknown',
      sellerEmail: json['seller_email'] as String? ?? '',
      totalOrders: (json['total_orders'] as num?)?.toInt() ?? 0,
      totalTickets: (json['total_tickets'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seller_id': sellerId,
      'seller_name': sellerName,
      'seller_email': sellerEmail,
      'total_orders': totalOrders,
      'total_tickets': totalTickets,
      'total_revenue': totalRevenue,
    };
  }
}

class DirectSalesStats {
  final int totalOrders;
  final int totalTickets;
  final int totalRevenue;

  const DirectSalesStats({
    required this.totalOrders,
    required this.totalTickets,
    required this.totalRevenue,
  });

  factory DirectSalesStats.fromJson(Map<String, dynamic> json) {
    return DirectSalesStats(
      totalOrders: (json['total_orders'] as num?)?.toInt() ?? 0,
      totalTickets: (json['total_tickets'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_orders': totalOrders,
      'total_tickets': totalTickets,
      'total_revenue': totalRevenue,
    };
  }
}
