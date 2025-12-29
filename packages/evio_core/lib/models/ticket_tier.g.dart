// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_tier.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TicketTierImpl _$$TicketTierImplFromJson(Map<String, dynamic> json) =>
    _$TicketTierImpl(
      id: json['id'] as String,
      ticketCategoryId: json['ticketCategoryId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toInt(),
      quantity: (json['quantity'] as num).toInt(),
      soldCount: (json['soldCount'] as num?)?.toInt() ?? 0,
      orderIndex: (json['orderIndex'] as num).toInt(),
      isActive: json['isActive'] as bool? ?? true,
      saleStartsAt: json['saleStartsAt'] == null
          ? null
          : DateTime.parse(json['saleStartsAt'] as String),
      saleEndsAt: json['saleEndsAt'] == null
          ? null
          : DateTime.parse(json['saleEndsAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$TicketTierImplToJson(_$TicketTierImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ticketCategoryId': instance.ticketCategoryId,
      'name': instance.name,
      'description': instance.description,
      'price': instance.price,
      'quantity': instance.quantity,
      'soldCount': instance.soldCount,
      'orderIndex': instance.orderIndex,
      'isActive': instance.isActive,
      'saleStartsAt': instance.saleStartsAt?.toIso8601String(),
      'saleEndsAt': instance.saleEndsAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
