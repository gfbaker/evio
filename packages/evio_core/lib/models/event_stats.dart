class EventStats {
  final String eventId;
  final int soldCount;
  final int totalCapacity;
  final int? minPrice;
  final int? maxPrice;
  final int currentRevenue; // En centavos
  final int potentialRevenue; // En centavos
  final int occupancyPercent; // 0-100

  EventStats({
    required this.eventId,
    required this.soldCount,
    required this.totalCapacity,
    this.minPrice,
    this.maxPrice,
    required this.currentRevenue,
    required this.potentialRevenue,
    required this.occupancyPercent,
  });

  factory EventStats.empty(String eventId) {
    return EventStats(
      eventId: eventId,
      soldCount: 0,
      totalCapacity: 0,
      minPrice: null,
      maxPrice: null,
      currentRevenue: 0,
      potentialRevenue: 0,
      occupancyPercent: 0,
    );
  }

  int get availableCount => totalCapacity - soldCount;
  int get remainingRevenue => potentialRevenue - currentRevenue;

  double get avgPrice {
    if (soldCount == 0) return 0;
    return currentRevenue / soldCount;
  }
}
