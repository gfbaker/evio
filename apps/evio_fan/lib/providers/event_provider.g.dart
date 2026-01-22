// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$eventInfoHash() => r'7883e095721ca2cf7ff20a251f955071063e84f1';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// ✅ CACHED: Info estática del evento (inmutable)
///
/// Copied from [eventInfo].
@ProviderFor(eventInfo)
const eventInfoProvider = EventInfoFamily();

/// ✅ CACHED: Info estática del evento (inmutable)
///
/// Copied from [eventInfo].
class EventInfoFamily extends Family<AsyncValue<Event?>> {
  /// ✅ CACHED: Info estática del evento (inmutable)
  ///
  /// Copied from [eventInfo].
  const EventInfoFamily();

  /// ✅ CACHED: Info estática del evento (inmutable)
  ///
  /// Copied from [eventInfo].
  EventInfoProvider call(String eventId) {
    return EventInfoProvider(eventId);
  }

  @override
  EventInfoProvider getProviderOverride(covariant EventInfoProvider provider) {
    return call(provider.eventId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'eventInfoProvider';
}

/// ✅ CACHED: Info estática del evento (inmutable)
///
/// Copied from [eventInfo].
class EventInfoProvider extends FutureProvider<Event?> {
  /// ✅ CACHED: Info estática del evento (inmutable)
  ///
  /// Copied from [eventInfo].
  EventInfoProvider(String eventId)
    : this._internal(
        (ref) => eventInfo(ref as EventInfoRef, eventId),
        from: eventInfoProvider,
        name: r'eventInfoProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$eventInfoHash,
        dependencies: EventInfoFamily._dependencies,
        allTransitiveDependencies: EventInfoFamily._allTransitiveDependencies,
        eventId: eventId,
      );

  EventInfoProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.eventId,
  }) : super.internal();

  final String eventId;

  @override
  Override overrideWith(
    FutureOr<Event?> Function(EventInfoRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: EventInfoProvider._internal(
        (ref) => create(ref as EventInfoRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        eventId: eventId,
      ),
    );
  }

  @override
  FutureProviderElement<Event?> createElement() {
    return _EventInfoProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is EventInfoProvider && other.eventId == eventId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, eventId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin EventInfoRef on FutureProviderRef<Event?> {
  /// The parameter `eventId` of this provider.
  String get eventId;
}

class _EventInfoProviderElement extends FutureProviderElement<Event?>
    with EventInfoRef {
  _EventInfoProviderElement(super.provider);

  @override
  String get eventId => (origin as EventInfoProvider).eventId;
}

String _$eventInfoBySlugHash() => r'607bdbc28a333b6c961767beec68e49f5100fe21';

/// ✅ CACHED: Evento por slug (inmutable)
///
/// Copied from [eventInfoBySlug].
@ProviderFor(eventInfoBySlug)
const eventInfoBySlugProvider = EventInfoBySlugFamily();

/// ✅ CACHED: Evento por slug (inmutable)
///
/// Copied from [eventInfoBySlug].
class EventInfoBySlugFamily extends Family<AsyncValue<Event?>> {
  /// ✅ CACHED: Evento por slug (inmutable)
  ///
  /// Copied from [eventInfoBySlug].
  const EventInfoBySlugFamily();

  /// ✅ CACHED: Evento por slug (inmutable)
  ///
  /// Copied from [eventInfoBySlug].
  EventInfoBySlugProvider call(String slug) {
    return EventInfoBySlugProvider(slug);
  }

  @override
  EventInfoBySlugProvider getProviderOverride(
    covariant EventInfoBySlugProvider provider,
  ) {
    return call(provider.slug);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'eventInfoBySlugProvider';
}

/// ✅ CACHED: Evento por slug (inmutable)
///
/// Copied from [eventInfoBySlug].
class EventInfoBySlugProvider extends FutureProvider<Event?> {
  /// ✅ CACHED: Evento por slug (inmutable)
  ///
  /// Copied from [eventInfoBySlug].
  EventInfoBySlugProvider(String slug)
    : this._internal(
        (ref) => eventInfoBySlug(ref as EventInfoBySlugRef, slug),
        from: eventInfoBySlugProvider,
        name: r'eventInfoBySlugProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$eventInfoBySlugHash,
        dependencies: EventInfoBySlugFamily._dependencies,
        allTransitiveDependencies:
            EventInfoBySlugFamily._allTransitiveDependencies,
        slug: slug,
      );

  EventInfoBySlugProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.slug,
  }) : super.internal();

  final String slug;

  @override
  Override overrideWith(
    FutureOr<Event?> Function(EventInfoBySlugRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: EventInfoBySlugProvider._internal(
        (ref) => create(ref as EventInfoBySlugRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        slug: slug,
      ),
    );
  }

  @override
  FutureProviderElement<Event?> createElement() {
    return _EventInfoBySlugProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is EventInfoBySlugProvider && other.slug == slug;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, slug.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin EventInfoBySlugRef on FutureProviderRef<Event?> {
  /// The parameter `slug` of this provider.
  String get slug;
}

class _EventInfoBySlugProviderElement extends FutureProviderElement<Event?>
    with EventInfoBySlugRef {
  _EventInfoBySlugProviderElement(super.provider);

  @override
  String get slug => (origin as EventInfoBySlugProvider).slug;
}

// ---------------------------------------------------------------------------
// producerInfoProvider
// ---------------------------------------------------------------------------

String _$producerInfoHash() => r'producer_info_hash_placeholder';

/// Provider para obtener info de productora por ID (cached)
///
/// Copied from [producerInfo].
@ProviderFor(producerInfo)
const producerInfoProvider = ProducerInfoFamily();

/// Provider para obtener info de productora por ID (cached)
///
/// Copied from [producerInfo].
class ProducerInfoFamily extends Family<AsyncValue<Producer?>> {
  /// Provider para obtener info de productora por ID (cached)
  ///
  /// Copied from [producerInfo].
  const ProducerInfoFamily();

  /// Provider para obtener info de productora por ID (cached)
  ///
  /// Copied from [producerInfo].
  ProducerInfoProvider call(
    String producerId,
  ) {
    return ProducerInfoProvider(
      producerId,
    );
  }

  @override
  ProducerInfoProvider getProviderOverride(
    covariant ProducerInfoProvider provider,
  ) {
    return call(
      provider.producerId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'producerInfoProvider';
}

/// Provider para obtener info de productora por ID (cached)
///
/// Copied from [producerInfo].
class ProducerInfoProvider extends FutureProvider<Producer?> {
  /// Provider para obtener info de productora por ID (cached)
  ///
  /// Copied from [producerInfo].
  ProducerInfoProvider(
    String producerId,
  ) : this._internal(
          (ref) => producerInfo(
            ref as ProducerInfoRef,
            producerId,
          ),
          from: producerInfoProvider,
          name: r'producerInfoProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$producerInfoHash,
          dependencies: ProducerInfoFamily._dependencies,
          allTransitiveDependencies:
              ProducerInfoFamily._allTransitiveDependencies,
          producerId: producerId,
        );

  ProducerInfoProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.producerId,
  }) : super.internal();

  final String producerId;

  @override
  Override overrideWith(
    FutureOr<Producer?> Function(ProducerInfoRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ProducerInfoProvider._internal(
        (ref) => create(ref as ProducerInfoRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        producerId: producerId,
      ),
    );
  }

  @override
  FutureProviderElement<Producer?> createElement() {
    return _ProducerInfoProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProducerInfoProvider && other.producerId == producerId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, producerId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ProducerInfoRef on FutureProviderRef<Producer?> {
  /// The parameter `producerId` of this provider.
  String get producerId;
}

class _ProducerInfoProviderElement extends FutureProviderElement<Producer?>
    with ProducerInfoRef {
  _ProducerInfoProviderElement(super.provider);

  @override
  String get producerId => (origin as ProducerInfoProvider).producerId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
