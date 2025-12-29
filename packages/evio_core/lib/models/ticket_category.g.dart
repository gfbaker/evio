// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TicketCategoryImpl _$$TicketCategoryImplFromJson(Map<String, dynamic> json) =>
    _$TicketCategoryImpl(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      maxPerPurchase: (json['maxPerPurchase'] as num?)?.toInt(),
      orderIndex: (json['orderIndex'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      tiers:
          (json['tiers'] as List<dynamic>?)
              ?.map((e) => TicketTier.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$TicketCategoryImplToJson(
  _$TicketCategoryImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'eventId': instance.eventId,
  'name': instance.name,
  'description': instance.description,
  'maxPerPurchase': instance.maxPerPurchase,
  'orderIndex': instance.orderIndex,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'tiers': instance.tiers,
};
