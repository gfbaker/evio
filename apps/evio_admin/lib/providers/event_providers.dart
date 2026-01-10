import 'dart:async';
import 'package:evio_admin/providers/auth_provider.dart';
import 'package:evio_admin/providers/storage_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:evio_core/evio_core.dart';
import '../models/event_form_state.dart';
import '../widgets/event_form/form_poster_card.dart';

// Repository provider (singleton)
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository();
});

// Lista de eventos (con filtros opcionales)
final eventsProvider = FutureProvider.autoDispose
    .family<List<Event>, EventFilters?>((ref, filters) async {
      final repo = ref.watch(eventRepositoryProvider);
      return repo.getAllEvents(
        city: filters?.city,
        genre: filters?.genre,
        isPublished: filters?.isPublished,
      );
    });

// ✅ CORREGIDO: Eventos del productor actual (filtrado por producer_id, no user.id)
final currentUserEventsProvider = FutureProvider.autoDispose<List<Event>>((
  ref,
) async {
  final repo = ref.watch(eventRepositoryProvider);
  final currentUser = await ref.watch(currentUserProvider.future);

  if (currentUser == null || currentUser.producerId == null) return [];

  debugPrint('🔄 Refrescando lista de eventos del usuario...');
  debugPrint('   Producer ID: ${currentUser.producerId}');
  
  final allEvents = await repo.getAllEvents();
  
  // ✅ CRÍTICO: Filtrar por producer_id, NO por user.id
  return allEvents.where((e) => e.producerId == currentUser.producerId).toList();
});

// ⚡ NUEVO: StateNotifier para cache manual y actualizaciones optimistas
class CurrentUserEventsNotifier extends StateNotifier<AsyncValue<List<Event>>> {
  final Ref ref;
  
  CurrentUserEventsNotifier(this.ref) : super(const AsyncLoading()) {
    _load();
  }
  
  Future<void> _load() async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(eventRepositoryProvider);
      final currentUser = await ref.read(currentUserProvider.future);
      
      if (currentUser == null || currentUser.producerId == null) {
        state = const AsyncData([]);
        return;
      }
      
      debugPrint('🔄 Cargando eventos del productor...');
      final allEvents = await repo.getAllEvents();
      final userEvents = allEvents
          .where((e) => e.producerId == currentUser.producerId)
          .toList();
      
      state = AsyncData(userEvents);
      debugPrint('✅ Cargados ${userEvents.length} eventos');
    } catch (e, st) {
      debugPrint('❌ Error cargando eventos: $e');
      state = AsyncError(e, st);
    }
  }
  
  /// Agregar evento sin refetch (optimistic update)
  void addEvent(Event event) {
    state.whenData((events) {
      state = AsyncData([event, ...events]);
      debugPrint('⚡ Evento agregado optimistically: ${event.title}');
    });
  }
  
  /// Actualizar evento existente sin refetch
  void updateEvent(Event updated) {
    state.whenData((events) {
      final newEvents = events.map((e) {
        return e.id == updated.id ? updated : e;
      }).toList();
      state = AsyncData(newEvents);
      debugPrint('⚡ Evento actualizado optimistically: ${updated.title}');
    });
  }
  
  /// Actualizar solo las URLs de imágenes de un evento (sin rebuild completo)
  void updateEventImages(String eventId, {
    String? thumbnailUrl,
    String? imageUrl,
    String? fullImageUrl,
  }) {
    state.whenData((events) {
      final newEvents = events.map((e) {
        if (e.id == eventId) {
          return Event(
            id: e.id,
            producerId: e.producerId,
            title: e.title,
            slug: e.slug,
            mainArtist: e.mainArtist,
            lineup: e.lineup,
            startDatetime: e.startDatetime,
            endDatetime: e.endDatetime,
            venueName: e.venueName,
            address: e.address,
            city: e.city,
            lat: e.lat,
            lng: e.lng,
            genre: e.genre,
            description: e.description,
            organizerName: e.organizerName,
            features: e.features,
            thumbnailUrl: thumbnailUrl ?? e.thumbnailUrl,
            imageUrl: imageUrl ?? e.imageUrl,
            fullImageUrl: fullImageUrl ?? e.fullImageUrl,
            videoUrl: e.videoUrl,
            status: e.status,
            isPublished: e.isPublished,
            totalCapacity: e.totalCapacity,
            showAllTicketTypes: e.showAllTicketTypes,
            createdAt: e.createdAt,
            updatedAt: e.updatedAt,
          );
        }
        return e;
      }).toList();
      state = AsyncData(newEvents);
      debugPrint('⚡ Imágenes actualizadas para evento: $eventId');
    });
  }
  
  /// Eliminar evento sin refetch
  void removeEvent(String eventId) {
    state.whenData((events) {
      final newEvents = events.where((e) => e.id != eventId).toList();
      state = AsyncData(newEvents);
      debugPrint('⚡ Evento eliminado optimistically: $eventId');
    });
  }
  
  /// Refrescar manualmente (para pull-to-refresh)
  Future<void> refresh() => _load();
}

final currentUserEventsNotifierProvider = 
    StateNotifierProvider.autoDispose<CurrentUserEventsNotifier, AsyncValue<List<Event>>>((ref) {
  return CurrentUserEventsNotifier(ref);
});

// Evento individual por ID
final eventDetailProvider = FutureProvider.autoDispose.family<Event?, String>((
  ref,
  eventId,
) async {
  final repo = ref.watch(eventRepositoryProvider);
  return repo.getEventById(eventId);
});

// Filtros model
class EventFilters {
  final String? city;
  final String? genre;
  final bool? isPublished;

  EventFilters({this.city, this.genre, this.isPublished});
}

// ============ EVENT FORM PROVIDER ============

final eventFormNotifierProvider = ChangeNotifierProvider.autoDispose
    .family<EventFormNotifier, String?>((ref, eventId) {
      return EventFormNotifier(ref, eventId);
    });

class EventFormNotifier with ChangeNotifier {
  final Ref _ref;
  final String? _eventId;

  bool _isDisposed = false;
  bool _isSaving = false; // ✅ AGREGADO - Prevenir doble guardado

  EventFormState _state = EventFormState.empty();
  EventFormState get state => _state;

  EventFormNotifier(this._ref, this._eventId) {
    debugPrint('🔧 EventFormNotifier init. eventId: $_eventId');
    if (_eventId != null) {
      _loadEvent(_eventId);
    }
  }

  @override
  void dispose() {
    _isDisposed = true; // ✅ AGREGADO
    debugPrint('🗑️ EventFormNotifier disposed');
    super.dispose();
  }

  void _setState(EventFormState newState) {
    if (_isDisposed) {
      debugPrint('⚠️ Attempted to update disposed provider');
      return;
    }
    
    // ✅ Auto-limpiar errorMessage si el state ahora es válido
    // (excepto si es el estado de saving que tiene su propio manejo)
    final shouldClearError = newState.isValid && 
                              newState.errorMessage != null &&
                              !newState.isSaving;
    
    _state = shouldClearError 
        ? newState.copyWith(errorMessage: null)
        : newState;
        
    notifyListeners();
  }

  Future<void> _loadEvent(String eventId) async {
    debugPrint('📥 Loading event: $eventId');

    try {
      final repo = _ref.read(eventRepositoryProvider);
      final event = await repo.getEventById(eventId);

      if (_isDisposed) return;

      debugPrint('📦 Event loaded: ${event?.title}');

      if (event != null) {
        _setState(EventFormState.fromEvent(event));
        debugPrint('✅ State updated. Title: ${_state.title}');

        // Cargar categorías y tiers
        final categories = await repo.getEventTicketCategories(eventId);

        if (_isDisposed) return;

        _setState(_state.copyWith(ticketCategories: categories));
        debugPrint('✅ Cargadas ${categories.length} categorías con tiers');

        // Descargar imagen croppeada si existe
        if (event.imageUrl != null && event.imageUrl!.isNotEmpty) {
          try {
            debugPrint('🖼️ Descargando imagen desde: ${event.imageUrl}');
            final uri = Uri.parse(event.imageUrl!);
            // Extraer path después de /storage/v1/object/public/events/
            final fullPath = uri.path;
            final pathAfterBucket = fullPath.split('/public/events/').last;
            
            debugPrint('📁 Path para download: $pathAfterBucket');
            
            final imageBytes = await Supabase.instance.client.storage
                .from('events')
                .download(pathAfterBucket);

            if (_isDisposed) return;
            
            _setState(_state.copyWith(imageBytes: imageBytes));
            debugPrint('✅ Imagen cargada: ${imageBytes.length} bytes');
          } catch (e) {
            debugPrint('⚠️ Error descargando imagen: $e');
          }
        }

        // Descargar imagen completa si existe
        if (event.fullImageUrl != null && event.fullImageUrl!.isNotEmpty) {
          try {
            debugPrint('🖼️ Descargando imagen completa desde: ${event.fullImageUrl}');
            final uri = Uri.parse(event.fullImageUrl!);
            final fullPath = uri.path;
            final pathAfterBucket = fullPath.split('/public/events/').last;
            
            debugPrint('📁 Path para download: $pathAfterBucket');
            
            final fullImageBytes = await Supabase.instance.client.storage
                .from('events')
                .download(pathAfterBucket);

            if (_isDisposed) return;
            
            _setState(_state.copyWith(fullImageBytes: fullImageBytes));
            debugPrint('✅ Imagen completa cargada: ${fullImageBytes.length} bytes');
          } catch (e) {
            debugPrint('⚠️ Error descargando imagen completa: $e');
          }
        }
      }
    } catch (e) {
      if (_isDisposed) return;
      debugPrint('❌ Error loading event: $e');
      _setState(_state.copyWith(errorMessage: 'Error al cargar evento: $e'));
    }
  }

  // Setters
  void setTitle(String value) {
    if (_isDisposed) return; // ✅ CHECK
    _setState(_state.copyWith(title: value));
  }

  void setMainArtist(String value) {
    if (_isDisposed) return; // ✅ CHECK
    _setState(_state.copyWith(mainArtist: value));
  }

  void setGenre(String? value) {
    if (_isDisposed) return; // ✅ CHECK
    _setState(_state.copyWith(genre: value));
  }

  void setDescription(String? value) {
    if (_isDisposed) return; // ✅ CHECK
    _setState(_state.copyWith(description: value));
  }

  void setOrganizerName(String? value) {
    if (_isDisposed) return; // ✅ CHECK
    _setState(_state.copyWith(organizerName: value));
  }

  void setTotalCapacity(int? value) {
    if (_isDisposed) return; // ✅ CHECK
    _setState(_state.copyWith(totalCapacity: value));
  }

  void setStatus(EventStatus value) {
    if (_isDisposed) return;
    final shouldPublish = value == EventStatus.upcoming;
    _setState(_state.copyWith(
      status: value,
      isPublished: shouldPublish,
    ));
    debugPrint('📝 Status changed: $value → isPublished: $shouldPublish');
  }

  void setShowAllTicketTypes(bool value) {
    if (_isDisposed) return;
    _setState(_state.copyWith(showAllTicketTypes: value));
  }

  void setStartDatetime(DateTime value) {
    if (_isDisposed) return; // ✅ CHECK
    _setState(_state.copyWith(startDatetime: value));
  }

  void setEndDatetime(DateTime value) {
    if (_isDisposed) return; // ✅ CHECK
    _setState(_state.copyWith(endDatetime: value));
  }

  void setLocation({
    required String venueName,
    required String address,
    required String city,
    double? lat,
    double? lng,
  }) {
    if (_isDisposed) return; // ✅ CHECK
    _setState(
      _state.copyWith(
        venueName: venueName,
        address: address,
        city: city,
        lat: lat,
        lng: lng,
      ),
    );
  }

  void addArtist(String name, {bool isHeadliner = false, String? imageUrl}) {
    if (_isDisposed) return; // ✅ CHECK
    final newArtist = LineupArtist(name: name, isHeadliner: isHeadliner, imageUrl: imageUrl);
    final updatedLineup = [..._state.lineup, newArtist];
    _setState(_state.copyWith(lineup: updatedLineup));
  }

  void removeArtist(int index) {
    if (_isDisposed) return; // ✅ CHECK
    final newLineup = List<LineupArtist>.from(_state.lineup)..removeAt(index);
    _setState(_state.copyWith(lineup: newLineup));
  }

  void toggleHeadliner(int index) {
    if (_isDisposed) return; // ✅ CHECK
    final newLineup = List<LineupArtist>.from(_state.lineup);
    newLineup[index] = newLineup[index].copyWith(
      isHeadliner: !newLineup[index].isHeadliner,
    );
    _setState(_state.copyWith(lineup: newLineup));
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // CATEGORÍAS Y TIERS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void addCategory({
    required String name,
    String? description,
    int? maxPerPurchase,
  }) {
    if (_isDisposed) return;
    
    final newCategory = TicketCategory(
      id: 'temp_${const Uuid().v4()}',
      eventId: '',
      name: name,
      description: description,
      maxPerPurchase: maxPerPurchase,
      orderIndex: _state.ticketCategories.length,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tiers: [],
    );
    
    _setState(_state.copyWith(
      ticketCategories: [..._state.ticketCategories, newCategory],
    ));
  }

  void updateCategory(String categoryId, TicketCategory updated) {
    if (_isDisposed) return;
    
    final categories = _state.ticketCategories.map((cat) {
      return cat.id == categoryId ? updated : cat;
    }).toList();
    
    _setState(_state.copyWith(ticketCategories: categories));
  }

  void removeCategory(String categoryId) {
    if (_isDisposed) return;
    
    _setState(_state.copyWith(
      ticketCategories: _state.ticketCategories
        .where((cat) => cat.id != categoryId)
        .toList(),
    ));
  }

  void reorderCategories(int oldIndex, int newIndex) {
    if (_isDisposed) return;
    
    final categories = List<TicketCategory>.from(_state.ticketCategories);
    if (oldIndex >= categories.length || newIndex > categories.length) return;
    
    // ✅ FIX: ReorderableListView ya ajusta newIndex correctamente
    // Solo necesitamos remover e insertar
    final category = categories.removeAt(oldIndex);
    
    // Ajustar newIndex después de removeAt si es necesario
    final adjustedIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    categories.insert(adjustedIndex, category);
    
    // Actualizar orderIndex
    final reordered = categories.asMap().entries.map((entry) {
      return entry.value.copyWith(orderIndex: entry.key);
    }).toList();
    
    _setState(_state.copyWith(ticketCategories: reordered));
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // TIERS (tandas de precio)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void addTier(
    String categoryId, {
    required String name,
    required int price,
    required int quantity,
    String? description,
  }) {
    if (_isDisposed) return;
    
    final categories = _state.ticketCategories.map((cat) {
      if (cat.id == categoryId) {
        // ✅ Validar nombre duplicado
        final existingNames = cat.tiers
            .map((t) => t.name.toLowerCase().trim())
            .toSet();
        
        String finalName = name;
        if (existingNames.contains(name.toLowerCase().trim())) {
          debugPrint('⚠️ Tier con nombre "$name" ya existe en esta categoría');
          // Agregar sufijo numérico
          int counter = 2;
          String uniqueName = '$name ($counter)';
          while (existingNames.contains(uniqueName.toLowerCase().trim())) {
            counter++;
            uniqueName = '$name ($counter)';
          }
          debugPrint('✅ Renombrando a: $uniqueName');
          finalName = uniqueName;
        }
        
        final newTier = TicketTier(
          id: 'temp_${const Uuid().v4()}',
          ticketCategoryId: categoryId,
          name: finalName,
          description: description,
          price: price,
          quantity: quantity,
          soldCount: 0, // ✅ AGREGADO
          isActive: true, // ✅ AGREGADO
          orderIndex: cat.tiers.length,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        return cat.copyWith(tiers: [...cat.tiers, newTier]);
      }
      return cat;
    }).toList();
    
    _setState(_state.copyWith(ticketCategories: categories));
  }

  void updateTier(String categoryId, String tierId, TicketTier updated) {
    if (_isDisposed) return;
    
    final categories = _state.ticketCategories.map((cat) {
      if (cat.id == categoryId) {
        final tiers = cat.tiers.map((t) {
          return t.id == tierId ? updated : t;
        }).toList();
        return cat.copyWith(tiers: tiers);
      }
      return cat;
    }).toList();
    
    _setState(_state.copyWith(ticketCategories: categories));
  }

  void removeTier(String categoryId, String tierId) {
    if (_isDisposed) return;
    
    final categories = _state.ticketCategories.map((cat) {
      if (cat.id == categoryId) {
        return cat.copyWith(
          tiers: cat.tiers.where((t) => t.id != tierId).toList(),
        );
      }
      return cat;
    }).toList();
    
    _setState(_state.copyWith(ticketCategories: categories));
  }

  void reorderTiers(String categoryId, int oldIndex, int newIndex) {
    if (_isDisposed) return;
    
    final categories = _state.ticketCategories.map((cat) {
      if (cat.id == categoryId) {
        final tiers = List<TicketTier>.from(cat.tiers);
        if (oldIndex >= tiers.length || newIndex > tiers.length) return cat;
        
        // ✅ FIX: Mismo approach que reorderCategories
        final tier = tiers.removeAt(oldIndex);
        
        final adjustedIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
        tiers.insert(adjustedIndex, tier);
        
        // Actualizar orderIndex
        final reordered = tiers.asMap().entries.map((entry) {
          return entry.value.copyWith(orderIndex: entry.key);
        }).toList();
        
        return cat.copyWith(tiers: reordered);
      }
      return cat;
    }).toList();
    
    _setState(_state.copyWith(ticketCategories: categories));
  }

  void toggleTierActive(String categoryId, String tierId) {
    if (_isDisposed) return;
    
    final categories = _state.ticketCategories.map((cat) {
      if (cat.id == categoryId) {
        final tiers = cat.tiers.map((t) {
          if (t.id == tierId) {
            return t.copyWith(isActive: !t.isActive);
          }
          return t;
        }).toList();
        return cat.copyWith(tiers: tiers);
      }
      return cat;
    }).toList();
    
    _setState(_state.copyWith(ticketCategories: categories));
  }

  void setTierActivation(
    String categoryId,
    String tierId, {
    DateTime? saleStartsAt,
    DateTime? saleEndsAt,
  }) {
    if (_isDisposed) return;
    
    final categories = _state.ticketCategories.map((cat) {
      if (cat.id == categoryId) {
        final tiers = cat.tiers.map((t) {
          if (t.id == tierId) {
            return t.copyWith(
              saleStartsAt: saleStartsAt,
              saleEndsAt: saleEndsAt,
            );
          }
          return t;
        }).toList();
        return cat.copyWith(tiers: tiers);
      }
      return cat;
    }).toList();
    
    _setState(_state.copyWith(ticketCategories: categories));
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void toggleFeature(String feature) {
    if (_isDisposed) return; // ✅ CHECK
    final newFeatures = List<String>.from(_state.features);
    if (newFeatures.contains(feature)) {
      newFeatures.remove(feature);
    } else {
      newFeatures.add(feature);
    }
    _setState(_state.copyWith(features: newFeatures));
  }

  void setImageBytes(Uint8List bytes) {
    if (_isDisposed) return; // ✅ CHECK
    debugPrint('🖼️ setImageBytes. Size: ${bytes.length}');
    _setState(_state.copyWith(imageBytes: bytes));
  }

  void setFullImageBytes(Uint8List bytes) {
    if (_isDisposed) return;
    debugPrint('🖼️ setFullImageBytes. Size: ${bytes.length}');
    _setState(_state.copyWith(fullImageBytes: bytes));
  }

  void setImageType(ImageType type) {
    if (_isDisposed) return;
    _setState(_state.copyWith(imageType: type));
  }

  void setVideoUrl(String? url) {
    if (_isDisposed) return;
    _setState(_state.copyWith(videoUrl: url));
  }

  void clearImage() {
    if (_isDisposed) return; // ✅ CHECK
    _setState(_state.copyWith(
      imageBytes: null,
      imageUrl: null,
      fullImageBytes: null,
      fullImageUrl: null,
    ));
  }

  Future<String?> save({required String producerId}) async {
    if (_isDisposed) return null;

    // ✅ Prevenir doble guardado (race condition)
    if (_isSaving) {
      debugPrint('⚠️ Save already in progress, ignoring duplicate call');
      return null;
    }
    _isSaving = true;

    // ✅ Validación: Eventos "Próximo" deben tener tickets configurados
    if (_state.status == EventStatus.upcoming) {
      final hasNewTickets = _state.ticketCategories.isNotEmpty && 
                            _state.ticketCategories.any((cat) => cat.tiers.isNotEmpty);
      
      if (!hasNewTickets) {
        _isSaving = false; // ✅ Limpiar flag
        if (_isDisposed) return null;
        _setState(_state.copyWith(
          errorMessage: 'Los eventos próximos deben tener al menos una categoría con tickets configurados',
        ));
        return null;
      }
    }

    // Validación general
    if (!_state.isValid) {
      final missing = _state.missingFields;
      final message = missing.isEmpty
          ? 'Por favor completa todos los campos requeridos'
          : 'Campos faltantes: ${missing.join(", ")}';

      _isSaving = false; // ✅ Limpiar flag
      if (_isDisposed) return null; // ✅ CHECK
      _setState(_state.copyWith(errorMessage: message));
      return null;
    }

    if (_isDisposed) return null; // ✅ CHECK
    _setState(_state.copyWith(isSaving: true, errorMessage: null));

    try {
      final repo = _ref.read(eventRepositoryProvider);
      String? imageUrl = _state.imageUrl;
      String? fullImageUrl = _state.fullImageUrl;
      final eventId = _eventId ?? const Uuid().v4();
      
      // 🔥 OPTIMIZACIÓN: Detectar si hubo cambio en las imágenes
      // ✅ Si hay imageBytes, SIEMPRE considerarlo como nueva imagen
      final hasNewCroppedImage = _state.imageBytes != null;
      final hasNewFullImage = _state.fullImageBytes != null;
      
      debugPrint('📊 Upload status:');
      debugPrint('   hasNewCroppedImage: $hasNewCroppedImage');
      debugPrint('   hasNewFullImage: $hasNewFullImage');

      // 🔥 PASO 1: GUARDAR EVENTO CON DATOS ACTUALES (URLs anteriores si existen)
      debugPrint('💾 [EventFormNotifier.save] Creating/Updating event');
      debugPrint('   producer_id: $producerId');
      debugPrint('   event_id: $eventId');

      final event = Event(
        id: eventId,
        producerId: producerId,
        title: _state.title,
        slug: _generateSlug(_state.title),
        mainArtist: _state.mainArtist,
        lineup: _state.lineup,
        startDatetime: _state.startDatetime,
        endDatetime:
            _state.endDatetime ?? _state.startDatetime.add(Duration(hours: 6)),
        venueName: _state.venueName,
        address: _state.address,
        city: _state.city,
        lat: _state.lat,
        lng: _state.lng,
        genre: _state.genre,
        description: _state.description,
        organizerName: _state.organizerName,
        features: _state.features,
        imageUrl: imageUrl, // URL anterior o null
        fullImageUrl: fullImageUrl, // URL anterior o null
        videoUrl: _state.videoUrl,
        totalCapacity: _state.totalCapacity,
        status: _state.status,
        isPublished: _state.isPublished,
        showAllTicketTypes: _state.showAllTicketTypes,
      );

      final savedEvent = _eventId == null
          ? await repo.createEvent(event)
          : await repo.updateEvent(event);

      if (_isDisposed) return savedEvent.id;

      // PASO 2: GUARDADO DE CATEGORÍAS Y TIERS
      if (_state.ticketCategories.isNotEmpty) {
        debugPrint('💾 Guardando ${_state.ticketCategories.length} categorías...');
        
        final categoriesWithIds = _state.ticketCategories.map((cat) {
          final categoryId = cat.id.startsWith('temp_') 
              ? const Uuid().v4() 
              : cat.id;
          
          debugPrint('  📁 Categoría "${cat.name}" (${cat.tiers.length} tiers)');
          debugPrint('     ID: ${cat.id} → $categoryId');
          
          final tiersWithIds = cat.tiers.map((tier) {
            final tierId = tier.id.startsWith('temp_')
                ? const Uuid().v4()
                : tier.id;
            
            debugPrint('     🎫 Tier "${tier.name}"');
            debugPrint('        ID: ${tier.id} → $tierId');
            
            return tier.copyWith(
              id: tierId,
              ticketCategoryId: categoryId,
            );
          }).toList();
          
          return cat.copyWith(
            id: categoryId,
            eventId: savedEvent.id,
            tiers: tiersWithIds,
          );
        }).toList();
        
        debugPrint('  🚀 Llamando a repo.saveTicketCategories()...');
        await repo.saveTicketCategories(savedEvent.id, categoriesWithIds);
        debugPrint('  ✅ Categorías guardadas');
      }

      // PASO 3: SUBIR IMÁGENES (si hay nuevas) - ✅ CON AWAIT
      if (hasNewCroppedImage || hasNewFullImage) {
        debugPrint('📤 Subiendo imágenes (esperando...)...');
        await _uploadImages(eventId, hasNewCroppedImage, hasNewFullImage);
        debugPrint('✅ Imágenes subidas correctamente');
      }

      if (_isDisposed) {
        _isSaving = false;
        return savedEvent.id;
      }
      
      // PASO 4: OBTENER EVENTO ACTUALIZADO (con URLs de imágenes)
      final finalEvent = hasNewCroppedImage || hasNewFullImage
        ? await repo.getEventById(savedEvent.id) ?? savedEvent
        : savedEvent;

      // PASO 5: ACTUALIZAR CACHE OPTIMISTICALLY (con URLs finales)
      _ref.read(currentUserEventsNotifierProvider.notifier).addEvent(finalEvent);
      debugPrint('⚡ Evento agregado al cache con URLs finales');

      if (_isDisposed) {
        _isSaving = false;
        return savedEvent.id;
      }

      _setState(_state.copyWith(isSaving: false));
      _isSaving = false;

      return savedEvent.id;
    } catch (e) {
      debugPrint('❌ Error al guardar: $e');
      _isSaving = false;
      if (_isDisposed) return null;
      _setState(
        _state.copyWith(isSaving: false, errorMessage: 'Error al guardar: $e'),
      );
      return null;
    }
  }
  
  // 🔥 Upload de imágenes con thumbnails automáticos
  Future<void> _uploadImages(
    String eventId,
    bool uploadCropped,
    bool uploadFull,
  ) async {
    try {
      final storageService = _ref.read(storageServiceProvider);
      
      if (_state.imageBytes != null) {
        debugPrint('📤 Procesando y subiendo imágenes con thumbnails...');
        
        final urls = await storageService.uploadEventImage(
          eventId: eventId,
          imageBytes: _state.imageBytes!,
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('Timeout al subir imágenes');
          },
        );
        
        debugPrint('✅ Imágenes subidas:');
        debugPrint('   thumbnail: ${urls.thumbnailUrl}');
        debugPrint('   medium: ${urls.imageUrl}');
        debugPrint('   full: ${urls.fullImageUrl}');
        
        // Actualizar evento en DB con las 3 URLs
        final repo = _ref.read(eventRepositoryProvider);
        final event = await repo.getEventById(eventId);
        
        if (event == null) return;
        
        final updatedEvent = Event(
          id: event.id,
          producerId: event.producerId,
          title: event.title,
          slug: event.slug,
          mainArtist: event.mainArtist,
          lineup: event.lineup,
          startDatetime: event.startDatetime,
          endDatetime: event.endDatetime,
          venueName: event.venueName,
          address: event.address,
          city: event.city,
          lat: event.lat,
          lng: event.lng,
          genre: event.genre,
          description: event.description,
          organizerName: event.organizerName,
          features: event.features,
          thumbnailUrl: urls.thumbnailUrl,
          imageUrl: urls.imageUrl,
          fullImageUrl: urls.fullImageUrl,
          videoUrl: event.videoUrl,
          status: event.status,
          isPublished: event.isPublished,
          totalCapacity: event.totalCapacity,
          showAllTicketTypes: event.showAllTicketTypes,
          createdAt: event.createdAt,
          updatedAt: DateTime.now(),
        );
        
        await repo.updateEvent(updatedEvent);
        debugPrint('✅ URLs actualizadas en DB');
      }
    } catch (e) {
      debugPrint('❌ Error subiendo imágenes: $e');
      rethrow; // Propagar error para que save() lo maneje
    }
  }

  String _generateSlug(String title) {
    final slug = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');

    final uniqueSuffix = const Uuid().v4().substring(0, 6);
    return '$slug-$uniqueSuffix';
  }
}

// ============ DELETE EVENT ACTION ============

final deleteEventProvider = FutureProvider.autoDispose.family<void, String>((
  ref,
  eventId,
) async {
  debugPrint('🔴 [deleteEventProvider] INICIO - eventId: $eventId');
  
  try {
    final repo = ref.watch(eventRepositoryProvider);
    debugPrint('🔴 [deleteEventProvider] Llamando a repo.deleteEvent()...');
    
    await repo.deleteEvent(eventId);
    
    debugPrint('🔴 [deleteEventProvider] repo.deleteEvent() completado');
    
    // ⚡ Actualizar cache optimistically
    ref.read(currentUserEventsNotifierProvider.notifier).removeEvent(eventId);
    
    debugPrint('✅ [deleteEventProvider] COMPLETADO - Cache actualizado');
  } catch (e, st) {
    debugPrint('❌ [deleteEventProvider] ERROR: $e');
    debugPrint('❌ [deleteEventProvider] Stack: $st');
    rethrow;
  }
});

// ============ EVENT STATS PROVIDER ============

final eventStatsProvider = FutureProvider.autoDispose
    .family<EventStats, String>((ref, eventId) async {
      final repo = ref.watch(eventRepositoryProvider);
      return repo.getEventStats(eventId);
    });

final multipleEventStatsProvider = FutureProvider.autoDispose
    .family<Map<String, EventStats>, String>((ref, eventIdsStr) async {
      // Convertir string a lista
      final eventIds = eventIdsStr
          .split(',')
          .where((id) => id.isNotEmpty)
          .toList();

      if (eventIds.isEmpty) {
        return <String, EventStats>{};
      }

      final repo = ref.watch(eventRepositoryProvider);
      return repo.getMultipleEventStats(eventIds);
    });

// ✅ Provider para cargar categorías/tiers de un evento
final eventTicketCategoriesProvider = FutureProvider.autoDispose
    .family<List<TicketCategory>, String>((ref, eventId) async {
      final repo = ref.watch(eventRepositoryProvider);
      return repo.getEventTicketCategories(eventId);
    });
