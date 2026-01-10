// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_tier.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TicketTierImpl _$$TicketTierImplFromJson(Map<String, dynamic> json) =>
    _$TicketTierImpl(
      id: json['id'] as String,
      ticketCategoryId: json['category_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toInt(),
      quantity: (json['quantity'] as num).toInt(),
      soldCount: (json['sold_count'] as num).toInt(),
      orderIndex: (json['order_index'] as num).toInt(),
      isActive: json['is_active'] as bool,
      saleStartsAt: json['sale_starts_at'] == null
          ? null
          : DateTime.parse(json['sale_starts_at'] as String),
      saleEndsAt: json['sale_ends_at'] == null
          ? null
          : DateTime.parse(json['sale_ends_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$TicketTierImplToJson(_$TicketTierImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'category_id': instance.ticketCategoryId,
      'name': instance.name,
      'description': instance.description,
      'price': instance.price,
      'quantity': instance.quantity,
      'sold_count': instance.soldCount,
      'order_index': instance.orderIndex,
      'is_active': instance.isActive,
      'sale_starts_at': instance.saleStartsAt?.toIso8601String(),
      'sale_ends_at': instance.saleEndsAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
