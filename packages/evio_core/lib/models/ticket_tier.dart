import 'package:freezed_annotation/freezed_annotation.dart';

part 'ticket_tier.freezed.dart';
part 'ticket_tier.g.dart';

@freezed
class TicketTier with _$TicketTier {
  const factory TicketTier({
    required String id,
    required String ticketCategoryId,
    required String name,
    String? description,
    required int price,
    required int quantity,
    @Default(0) int soldCount,
    required int orderIndex,
    @Default(true) bool isActive,
    DateTime? saleStartsAt,
    DateTime? saleEndsAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _TicketTier;

  factory TicketTier.fromJson(Map<String, dynamic> json) =>
      _$TicketTierFromJson(json);
}

enum TierStatus {
  waiting,    // Esperando tier anterior
  scheduled,  // Tiene fecha futura
  active,     // Disponible
  paused,     // Pausada manualmente
  soldOut,    // Agotada
  ended,      // Pasó fecha fin
}
