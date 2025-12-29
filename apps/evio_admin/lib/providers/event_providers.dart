import 'package:evio_admin/providers/auth_provider.dart';
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

// Eventos del productor actual (sin filtros, solo del usuario logueado)
final currentUserEventsProvider = FutureProvider.autoDispose<List<Event>>((
  ref,
) async {
  final repo = ref.watch(eventRepositoryProvider);
  final currentUser = await ref.watch(currentUserProvider.future);

  if (currentUser == null) return [];

  debugPrint('🔄 Refrescando lista de eventos del usuario...');
  final allEvents = await repo.getAllEvents();
  return allEvents.where((e) => e.producerId == currentUser.id).toList();
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

        // Cargar tickets
        final ticketTypes = await repo.getEventTicketTypes(eventId);

        if (_isDisposed) return;

        _setState(_state.copyWith(ticketTypes: ticketTypes));

        // Cargar categorías y tiers (nuevo sistema)
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

  void addTicketType({
    required String name,
    String? description,
    required int price,
    required int quantity,
    int? maxPerPurchase,
  }) {
    if (_isDisposed) return;
    final newTicket = TicketType(
      id: const Uuid().v4(),
      eventId: _eventId ?? '',
      name: name,
      description: description,
      price: price,
      totalQuantity: quantity,
      maxPerPurchase: maxPerPurchase,
      displayOrder: _state.ticketTypes.length, // ✅ Auto-order
    );
    final updatedTypes = [..._state.ticketTypes, newTicket];
    _setState(_state.copyWith(ticketTypes: updatedTypes));
  }

  void editTicketType({
    required int index,
    required String name,
    String? description,
    required int price,
    required int quantity,
    int? maxPerPurchase,
  }) {
    if (_isDisposed) return;
    final tickets = List<TicketType>.from(_state.ticketTypes);
    tickets[index] = tickets[index].copyWith(
      name: name,
      description: description,
      price: price,
      totalQuantity: quantity,
      maxPerPurchase: maxPerPurchase,
    );
    _setState(_state.copyWith(ticketTypes: tickets));
  }

  void reorderTicketTypes(int oldIndex, int newIndex) {
    if (_isDisposed) return;
    final tickets = List<TicketType>.from(_state.ticketTypes);
    
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    
    final ticket = tickets.removeAt(oldIndex);
    tickets.insert(newIndex, ticket);
    
    // ✅ Actualizar displayOrder
    final reordered = tickets.asMap().entries.map((entry) {
      return entry.value.copyWith(displayOrder: entry.key);
    }).toList();
    
    _setState(_state.copyWith(ticketTypes: reordered));
  }

  void removeTicketType(int index) {
    if (_isDisposed) return;
    final newTypes = List<TicketType>.from(_state.ticketTypes)..removeAt(index);
    _setState(_state.copyWith(ticketTypes: newTypes));
  }

  void toggleTicketTypeActive(int index) {
    if (_isDisposed) return;
    final tickets = List<TicketType>.from(_state.ticketTypes);
    tickets[index] = tickets[index].copyWith(isActive: !tickets[index].isActive);
    _setState(_state.copyWith(ticketTypes: tickets));
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // CATEGORÍAS (nuevo sistema)
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
      final hasLegacyTickets = _state.ticketTypes.isNotEmpty;
      final hasNewTickets = _state.ticketCategories.isNotEmpty && 
                            _state.ticketCategories.any((cat) => cat.tiers.isNotEmpty);
      
      // 🔍 DEBUG
      debugPrint('🔍 DEBUG VALIDACIÓN:');
      debugPrint('  - ticketCategories.length: ${_state.ticketCategories.length}');
      debugPrint('  - ticketTypes.length: ${_state.ticketTypes.length}');
      if (_state.ticketCategories.isNotEmpty) {
        for (var cat in _state.ticketCategories) {
          debugPrint('  - Categoría "${cat.name}": ${cat.tiers.length} tiers');
        }
      }
      debugPrint('  - hasLegacyTickets: $hasLegacyTickets');
      debugPrint('  - hasNewTickets: $hasNewTickets');
      debugPrint('  - state.isValid: ${_state.isValid}');
      
      if (!hasLegacyTickets && !hasNewTickets) {
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

      // 1. SUBIDA DE IMAGEN CROPPEADA (obligatoria)
      if (_state.imageBytes != null) {
        debugPrint('📤 Subiendo imagen croppeada a Supabase Storage...');
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_cropped.jpg';
        final path = 'events/$eventId/$fileName';

        await Supabase.instance.client.storage
            .from('events')
            .uploadBinary(
              path,
              _state.imageBytes!,
              fileOptions: const FileOptions(
                upsert: true,
                contentType: 'image/jpeg',
              ),
            );

        imageUrl = Supabase.instance.client.storage
            .from('events')
            .getPublicUrl(path);
        debugPrint('✅ Imagen croppeada subida: $imageUrl');
      }

      if (_isDisposed) return null; // ✅ CHECK después de async

      // 1.5 SUBIDA DE IMAGEN COMPLETA (opcional)
      if (_state.fullImageBytes != null) {
        debugPrint('📬 Subiendo imagen completa a Supabase Storage...');
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_full.jpg';
        final path = 'events/$eventId/$fileName';

        await Supabase.instance.client.storage
            .from('events')
            .uploadBinary(
              path,
              _state.fullImageBytes!,
              fileOptions: const FileOptions(
                upsert: true,
                contentType: 'image/jpeg',
              ),
            );

        fullImageUrl = Supabase.instance.client.storage
            .from('events')
            .getPublicUrl(path);
        debugPrint('✅ Imagen completa subida: $fullImageUrl');
      }

      if (_isDisposed) return null; // ✅ CHECK después de async

      // 2. CREACIÓN DEL EVENTO
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
        imageUrl: imageUrl,
        fullImageUrl: fullImageUrl,
        videoUrl: _state.videoUrl,
        totalCapacity: _state.totalCapacity,
        status: _state.status,
        isPublished: _state.isPublished,
        showAllTicketTypes: _state.showAllTicketTypes,
      );

      final savedEvent = _eventId == null
          ? await repo.createEvent(event)
          : await repo.updateEvent(event);

      if (_isDisposed) return savedEvent.id; // ✅ CHECK después de async

      // 3. GUARDADO DE CATEGORÍAS Y TIERS (nuevo sistema)
      if (_state.ticketCategories.isNotEmpty) {
        debugPrint('💾 Guardando ${_state.ticketCategories.length} categorías...');
        
        // Asignar IDs reales a categorías y tiers temporales
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
      } else {
        debugPrint('⚠️ No hay categorías para guardar');
      }

      if (_isDisposed) return savedEvent.id;

      // 4. GUARDADO DE TICKETS (sistema legacy - deprecated)
      if (_state.ticketTypes.isNotEmpty) {
        final ticketsWithEventId = _state.ticketTypes
            .map((t) => t.copyWith(eventId: savedEvent.id))
            .toList();
        await repo.saveEventTicketTypes(savedEvent.id, ticketsWithEventId);
      }

      if (_isDisposed) return savedEvent.id; // ✅ CHECK después de async

      // 5. INVALIDAR CACHÉ
      _ref.invalidate(currentUserEventsProvider);
      _ref.invalidate(eventsProvider);
      _ref.invalidate(eventDetailProvider(savedEvent.id));

      if (_isDisposed) {
        _isSaving = false; // ✅ Limpiar flag
        return savedEvent.id;
      }

      _setState(_state.copyWith(isSaving: false));
      _isSaving = false; // ✅ Limpiar flag
      return savedEvent.id;
    } catch (e) {
      debugPrint('❌ Error al guardar: $e');
      _isSaving = false; // ✅ Limpiar flag SIEMPRE
      if (_isDisposed) return null; // ✅ CHECK
      _setState(
        _state.copyWith(isSaving: false, errorMessage: 'Error al guardar: $e'),
      );
      return null;
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
  final repo = ref.watch(eventRepositoryProvider);
  await repo.deleteEvent(eventId);

  // Invalidar cache para refrescar lista
  ref.invalidate(currentUserEventsProvider);
  ref.invalidate(eventsProvider);
});

// ============ TICKET TYPE ACTIONS ============

final createTicketTypeProvider = FutureProvider.autoDispose
    .family<TicketType, CreateTicketTypeParams>((ref, params) async {
      final repo = ref.watch(eventRepositoryProvider);
      final ticketType = await repo.createTicketType(params.ticketType);
      ref.invalidate(eventDetailProvider(params.eventId));
      return ticketType;
    });

final deleteTicketTypeProvider = FutureProvider.autoDispose
    .family<void, DeleteTicketTypeParams>((ref, params) async {
      final repo = ref.watch(eventRepositoryProvider);
      await repo.deleteTicketType(params.ticketTypeId);
      ref.invalidate(eventDetailProvider(params.eventId));
    });

// Params classes
class CreateTicketTypeParams {
  final String eventId;
  final TicketType ticketType;

  CreateTicketTypeParams({required this.eventId, required this.ticketType});
}

class DeleteTicketTypeParams {
  final String eventId;
  final String ticketTypeId;

  DeleteTicketTypeParams({required this.eventId, required this.ticketTypeId});
}
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
