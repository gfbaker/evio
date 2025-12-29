// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ticket_tier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TicketTier _$TicketTierFromJson(Map<String, dynamic> json) {
  return _TicketTier.fromJson(json);
}

/// @nodoc
mixin _$TicketTier {
  String get id => throw _privateConstructorUsedError;
  String get ticketCategoryId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  int get price => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;
  int get soldCount => throw _privateConstructorUsedError;
  int get orderIndex => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  DateTime? get saleStartsAt => throw _privateConstructorUsedError;
  DateTime? get saleEndsAt => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this TicketTier to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TicketTier
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TicketTierCopyWith<TicketTier> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TicketTierCopyWith<$Res> {
  factory $TicketTierCopyWith(
    TicketTier value,
    $Res Function(TicketTier) then,
  ) = _$TicketTierCopyWithImpl<$Res, TicketTier>;
  @useResult
  $Res call({
    String id,
    String ticketCategoryId,
    String name,
    String? description,
    int price,
    int quantity,
    int soldCount,
    int orderIndex,
    bool isActive,
    DateTime? saleStartsAt,
    DateTime? saleEndsAt,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$TicketTierCopyWithImpl<$Res, $Val extends TicketTier>
    implements $TicketTierCopyWith<$Res> {
  _$TicketTierCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TicketTier
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ticketCategoryId = null,
    Object? name = null,
    Object? description = freezed,
    Object? price = null,
    Object? quantity = null,
    Object? soldCount = null,
    Object? orderIndex = null,
    Object? isActive = null,
    Object? saleStartsAt = freezed,
    Object? saleEndsAt = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            ticketCategoryId: null == ticketCategoryId
                ? _value.ticketCategoryId
                : ticketCategoryId // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            price: null == price
                ? _value.price
                : price // ignore: cast_nullable_to_non_nullable
                      as int,
            quantity: null == quantity
                ? _value.quantity
                : quantity // ignore: cast_nullable_to_non_nullable
                      as int,
            soldCount: null == soldCount
                ? _value.soldCount
                : soldCount // ignore: cast_nullable_to_non_nullable
                      as int,
            orderIndex: null == orderIndex
                ? _value.orderIndex
                : orderIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
            saleStartsAt: freezed == saleStartsAt
                ? _value.saleStartsAt
                : saleStartsAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            saleEndsAt: freezed == saleEndsAt
                ? _value.saleEndsAt
                : saleEndsAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TicketTierImplCopyWith<$Res>
    implements $TicketTierCopyWith<$Res> {
  factory _$$TicketTierImplCopyWith(
    _$TicketTierImpl value,
    $Res Function(_$TicketTierImpl) then,
  ) = __$$TicketTierImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String ticketCategoryId,
    String name,
    String? description,
    int price,
    int quantity,
    int soldCount,
    int orderIndex,
    bool isActive,
    DateTime? saleStartsAt,
    DateTime? saleEndsAt,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$TicketTierImplCopyWithImpl<$Res>
    extends _$TicketTierCopyWithImpl<$Res, _$TicketTierImpl>
    implements _$$TicketTierImplCopyWith<$Res> {
  __$$TicketTierImplCopyWithImpl(
    _$TicketTierImpl _value,
    $Res Function(_$TicketTierImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TicketTier
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ticketCategoryId = null,
    Object? name = null,
    Object? description = freezed,
    Object? price = null,
    Object? quantity = null,
    Object? soldCount = null,
    Object? orderIndex = null,
    Object? isActive = null,
    Object? saleStartsAt = freezed,
    Object? saleEndsAt = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$TicketTierImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        ticketCategoryId: null == ticketCategoryId
            ? _value.ticketCategoryId
            : ticketCategoryId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        price: null == price
            ? _value.price
            : price // ignore: cast_nullable_to_non_nullable
                  as int,
        quantity: null == quantity
            ? _value.quantity
            : quantity // ignore: cast_nullable_to_non_nullable
                  as int,
        soldCount: null == soldCount
            ? _value.soldCount
            : soldCount // ignore: cast_nullable_to_non_nullable
                  as int,
        orderIndex: null == orderIndex
            ? _value.orderIndex
            : orderIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
        saleStartsAt: freezed == saleStartsAt
            ? _value.saleStartsAt
            : saleStartsAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        saleEndsAt: freezed == saleEndsAt
            ? _value.saleEndsAt
            : saleEndsAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TicketTierImpl implements _TicketTier {
  const _$TicketTierImpl({
    required this.id,
    required this.ticketCategoryId,
    required this.name,
    this.description,
    required this.price,
    required this.quantity,
    this.soldCount = 0,
    required this.orderIndex,
    this.isActive = true,
    this.saleStartsAt,
    this.saleEndsAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory _$TicketTierImpl.fromJson(Map<String, dynamic> json) =>
      _$$TicketTierImplFromJson(json);

  @override
  final String id;
  @override
  final String ticketCategoryId;
  @override
  final String name;
  @override
  final String? description;
  @override
  final int price;
  @override
  final int quantity;
  @override
  @JsonKey()
  final int soldCount;
  @override
  final int orderIndex;
  @override
  @JsonKey()
  final bool isActive;
  @override
  final DateTime? saleStartsAt;
  @override
  final DateTime? saleEndsAt;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'TicketTier(id: $id, ticketCategoryId: $ticketCategoryId, name: $name, description: $description, price: $price, quantity: $quantity, soldCount: $soldCount, orderIndex: $orderIndex, isActive: $isActive, saleStartsAt: $saleStartsAt, saleEndsAt: $saleEndsAt, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TicketTierImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.ticketCategoryId, ticketCategoryId) ||
                other.ticketCategoryId == ticketCategoryId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.soldCount, soldCount) ||
                other.soldCount == soldCount) &&
            (identical(other.orderIndex, orderIndex) ||
                other.orderIndex == orderIndex) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.saleStartsAt, saleStartsAt) ||
                other.saleStartsAt == saleStartsAt) &&
            (identical(other.saleEndsAt, saleEndsAt) ||
                other.saleEndsAt == saleEndsAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    ticketCategoryId,
    name,
    description,
    price,
    quantity,
    soldCount,
    orderIndex,
    isActive,
    saleStartsAt,
    saleEndsAt,
    createdAt,
    updatedAt,
  );

  /// Create a copy of TicketTier
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TicketTierImplCopyWith<_$TicketTierImpl> get copyWith =>
      __$$TicketTierImplCopyWithImpl<_$TicketTierImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TicketTierImplToJson(this);
  }
}

abstract class _TicketTier implements TicketTier {
  const factory _TicketTier({
    required final String id,
    required final String ticketCategoryId,
    required final String name,
    final String? description,
    required final int price,
    required final int quantity,
    final int soldCount,
    required final int orderIndex,
    final bool isActive,
    final DateTime? saleStartsAt,
    final DateTime? saleEndsAt,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$TicketTierImpl;

  factory _TicketTier.fromJson(Map<String, dynamic> json) =
      _$TicketTierImpl.fromJson;

  @override
  String get id;
  @override
  String get ticketCategoryId;
  @override
  String get name;
  @override
  String? get description;
  @override
  int get price;
  @override
  int get quantity;
  @override
  int get soldCount;
  @override
  int get orderIndex;
  @override
  bool get isActive;
  @override
  DateTime? get saleStartsAt;
  @override
  DateTime? get saleEndsAt;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of TicketTier
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TicketTierImplCopyWith<_$TicketTierImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
