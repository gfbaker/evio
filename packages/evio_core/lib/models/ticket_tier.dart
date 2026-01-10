import 'package:freezed_annotation/freezed_annotation.dart';

part 'ticket_tier.freezed.dart';
part 'ticket_tier.g.dart';

@freezed
class TicketTier with _$TicketTier {
  const TicketTier._(); // ✅ Constructor privado para getters

  const factory TicketTier({
    required String id,
    @JsonKey(name: 'category_id') required String ticketCategoryId,
    required String name,
    String? description,
    required int price,
    required int quantity,
    @JsonKey(name: 'sold_count') required int soldCount,
    @JsonKey(name: 'order_index') required int orderIndex,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'sale_starts_at') DateTime? saleStartsAt,
    @JsonKey(name: 'sale_ends_at') DateTime? saleEndsAt,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _TicketTier;

  factory TicketTier.fromJson(Map<String, dynamic> json) =>
      _$TicketTierFromJson(json);

  // ✅ Getters calculados
  int get availableQuantity => quantity - soldCount;
  bool get isSoldOut => soldCount >= quantity;
  bool get isLowStock => availableQuantity > 0 && availableQuantity <= 10;
}

enum TierStatus {
  waiting,    // Esperando tier anterior
  scheduled,  // Tiene fecha futura
  active,     // Disponible
  paused,     // Pausada manualmente
  soldOut,    // Agotada
  ended,      // Pasó fecha fin
}
