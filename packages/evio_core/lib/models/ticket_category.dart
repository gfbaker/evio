import 'package:freezed_annotation/freezed_annotation.dart';
import 'ticket_tier.dart';

part 'ticket_category.freezed.dart';
part 'ticket_category.g.dart';

@freezed
class TicketCategory with _$TicketCategory {
  const factory TicketCategory({
    required String id,
    required String eventId,
    required String name,
    String? description,
    int? maxPerPurchase,
    required int orderIndex,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default([]) List<TicketTier> tiers,
  }) = _TicketCategory;

  factory TicketCategory.fromJson(Map<String, dynamic> json) =>
      _$TicketCategoryFromJson(json);
}
