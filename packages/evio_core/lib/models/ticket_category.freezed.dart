// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ticket_category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TicketCategory _$TicketCategoryFromJson(Map<String, dynamic> json) {
  return _TicketCategory.fromJson(json);
}

/// @nodoc
mixin _$TicketCategory {
  String get id => throw _privateConstructorUsedError;
  String get eventId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  int? get maxPerPurchase => throw _privateConstructorUsedError;
  int get orderIndex => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  List<TicketTier> get tiers => throw _privateConstructorUsedError;

  /// Serializes this TicketCategory to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TicketCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TicketCategoryCopyWith<TicketCategory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TicketCategoryCopyWith<$Res> {
  factory $TicketCategoryCopyWith(
    TicketCategory value,
    $Res Function(TicketCategory) then,
  ) = _$TicketCategoryCopyWithImpl<$Res, TicketCategory>;
  @useResult
  $Res call({
    String id,
    String eventId,
    String name,
    String? description,
    int? maxPerPurchase,
    int orderIndex,
    DateTime createdAt,
    DateTime updatedAt,
    List<TicketTier> tiers,
  });
}

/// @nodoc
class _$TicketCategoryCopyWithImpl<$Res, $Val extends TicketCategory>
    implements $TicketCategoryCopyWith<$Res> {
  _$TicketCategoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TicketCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? eventId = null,
    Object? name = null,
    Object? description = freezed,
    Object? maxPerPurchase = freezed,
    Object? orderIndex = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? tiers = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            eventId: null == eventId
                ? _value.eventId
                : eventId // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            maxPerPurchase: freezed == maxPerPurchase
                ? _value.maxPerPurchase
                : maxPerPurchase // ignore: cast_nullable_to_non_nullable
                      as int?,
            orderIndex: null == orderIndex
                ? _value.orderIndex
                : orderIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            tiers: null == tiers
                ? _value.tiers
                : tiers // ignore: cast_nullable_to_non_nullable
                      as List<TicketTier>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TicketCategoryImplCopyWith<$Res>
    implements $TicketCategoryCopyWith<$Res> {
  factory _$$TicketCategoryImplCopyWith(
    _$TicketCategoryImpl value,
    $Res Function(_$TicketCategoryImpl) then,
  ) = __$$TicketCategoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String eventId,
    String name,
    String? description,
    int? maxPerPurchase,
    int orderIndex,
    DateTime createdAt,
    DateTime updatedAt,
    List<TicketTier> tiers,
  });
}

/// @nodoc
class __$$TicketCategoryImplCopyWithImpl<$Res>
    extends _$TicketCategoryCopyWithImpl<$Res, _$TicketCategoryImpl>
    implements _$$TicketCategoryImplCopyWith<$Res> {
  __$$TicketCategoryImplCopyWithImpl(
    _$TicketCategoryImpl _value,
    $Res Function(_$TicketCategoryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TicketCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? eventId = null,
    Object? name = null,
    Object? description = freezed,
    Object? maxPerPurchase = freezed,
    Object? orderIndex = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? tiers = null,
  }) {
    return _then(
      _$TicketCategoryImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        eventId: null == eventId
            ? _value.eventId
            : eventId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        maxPerPurchase: freezed == maxPerPurchase
            ? _value.maxPerPurchase
            : maxPerPurchase // ignore: cast_nullable_to_non_nullable
                  as int?,
        orderIndex: null == orderIndex
            ? _value.orderIndex
            : orderIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        tiers: null == tiers
            ? _value._tiers
            : tiers // ignore: cast_nullable_to_non_nullable
                  as List<TicketTier>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TicketCategoryImpl implements _TicketCategory {
  const _$TicketCategoryImpl({
    required this.id,
    required this.eventId,
    required this.name,
    this.description,
    this.maxPerPurchase,
    required this.orderIndex,
    required this.createdAt,
    required this.updatedAt,
    final List<TicketTier> tiers = const [],
  }) : _tiers = tiers;

  factory _$TicketCategoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$TicketCategoryImplFromJson(json);

  @override
  final String id;
  @override
  final String eventId;
  @override
  final String name;
  @override
  final String? description;
  @override
  final int? maxPerPurchase;
  @override
  final int orderIndex;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  final List<TicketTier> _tiers;
  @override
  @JsonKey()
  List<TicketTier> get tiers {
    if (_tiers is EqualUnmodifiableListView) return _tiers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tiers);
  }

  @override
  String toString() {
    return 'TicketCategory(id: $id, eventId: $eventId, name: $name, description: $description, maxPerPurchase: $maxPerPurchase, orderIndex: $orderIndex, createdAt: $createdAt, updatedAt: $updatedAt, tiers: $tiers)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TicketCategoryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.eventId, eventId) || other.eventId == eventId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.maxPerPurchase, maxPerPurchase) ||
                other.maxPerPurchase == maxPerPurchase) &&
            (identical(other.orderIndex, orderIndex) ||
                other.orderIndex == orderIndex) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            const DeepCollectionEquality().equals(other._tiers, _tiers));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    eventId,
    name,
    description,
    maxPerPurchase,
    orderIndex,
    createdAt,
    updatedAt,
    const DeepCollectionEquality().hash(_tiers),
  );

  /// Create a copy of TicketCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TicketCategoryImplCopyWith<_$TicketCategoryImpl> get copyWith =>
      __$$TicketCategoryImplCopyWithImpl<_$TicketCategoryImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$TicketCategoryImplToJson(this);
  }
}

abstract class _TicketCategory implements TicketCategory {
  const factory _TicketCategory({
    required final String id,
    required final String eventId,
    required final String name,
    final String? description,
    final int? maxPerPurchase,
    required final int orderIndex,
    required final DateTime createdAt,
    required final DateTime updatedAt,
    final List<TicketTier> tiers,
  }) = _$TicketCategoryImpl;

  factory _TicketCategory.fromJson(Map<String, dynamic> json) =
      _$TicketCategoryImpl.fromJson;

  @override
  String get id;
  @override
  String get eventId;
  @override
  String get name;
  @override
  String? get description;
  @override
  int? get maxPerPurchase;
  @override
  int get orderIndex;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  List<TicketTier> get tiers;

  /// Create a copy of TicketCategory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TicketCategoryImplCopyWith<_$TicketCategoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
