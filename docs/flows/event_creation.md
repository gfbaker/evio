# FLUJO: CREACIÓN DE EVENTOS (evio_admin)

## 📋 OVERVIEW

**Ruta:** `/events/new` o `/events/:id/edit`  
**Componente:** `EventFormScreen`  
**Provider:** `eventFormProvider` (ChangeNotifierProvider)  
**Estado:** `EventFormState` (modelo con validación condicional)

---

## 🎯 FLUJO COMPLETO

```
Usuario entra a /events/new
    ↓
EventFormScreen se monta
    ↓
Inicializa eventFormProvider (estado vacío o carga evento existente)
    ↓
Usuario completa 6 cards del formulario:
    1. Detalles (título, artista, género, organizador, descripción)
    2. Ubicación (fecha, hora, venue, ciudad, mapa)
    3. Line-up (DJs con toggle headliner)
    4. Categorías y Tandas (categorías con tiers: precio, cantidad, fechas)
    5. Features (tags seleccionables)
    6. Imagen (upload + crop)
    ↓
Live Preview actualiza en tiempo real
    ↓
Usuario presiona "Crear Evento" o "Guardar Cambios"
    ↓
Validación condicional por status:
    - draft: Sin validación (siempre válido)
    - upcoming: Requiere TODOS los campos
    - cancelled: Solo requiere título
    ↓
Si válido → Provider llama repository
    ↓
Repository guarda en Supabase (events + ticket_categories + ticket_tiers)
    ↓
Navegación automática a /events/:id
```

---

## 🗂️ ESTRUCTURA DE ARCHIVOS

### EventFormScreen
```dart
// apps/evio_admin/lib/screens/events/event_form_screen.dart
class EventFormScreen extends ConsumerStatefulWidget {
  final String? eventId; // null = crear, !null = editar
  
  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  bool _isDisposed = false;
  final _scrollController = ScrollController();
  
  @override
  void dispose() {
    _isDisposed = true;
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(eventFormProvider.notifier);
    final state = ref.watch(eventFormProvider);
    
    return Scaffold(
      body: Row(
        children: [
          // Formulario (60%)
          Expanded(
            flex: 3,
            child: _buildForm(state, notifier),
          ),
          
          // Preview (40%)
          Expanded(
            flex: 2,
            child: LivePreviewCard(state: state),
          ),
        ],
      ),
    );
  }
}
```

### EventFormState (Modelo con validación)
```dart
// apps/evio_admin/lib/models/event_form_state.dart
class EventFormState {
  final String title;
  final String mainArtist;
  final String? genre;
  final String? organizerName;
  final String? description;
  final DateTime? startDate;
  final TimeOfDay? startTime;
  final String venueName;
  final String city;
  final String address;
  final double? lat;
  final double? lng;
  final List<LineupArtist> lineup;
  final List<TicketTypeFormData> ticketTypes;
  final List<String> features;
  final Uint8List? imageBytes;
  final String? imageUrl;
  final EventStatus status;
  
  // VALIDACIÓN CONDICIONAL
  bool get isValid {
    if (status == EventStatus.draft) return true;
    
    if (status == EventStatus.upcoming) {
      return title.isNotEmpty &&
             mainArtist.isNotEmpty &&
             venueName.isNotEmpty &&
             lineup.isNotEmpty &&
             ticketTypes.isNotEmpty &&
             (imageBytes != null || imageUrl != null);
    }
    
    return title.isNotEmpty; // cancelled
  }
  
  List<String> get missingFields {
    if (status == EventStatus.draft) return [];
    
    List<String> missing = [];
    if (title.isEmpty) missing.add('Título');
    if (mainArtist.isEmpty) missing.add('Artista Principal');
    // ... resto de campos
    return missing;
  }
}
```

### EventFormNotifier (Provider)
```dart
// apps/evio_admin/lib/providers/event_providers.dart
class EventFormNotifier extends ChangeNotifier {
  EventFormState _state = EventFormState.empty();
  bool _isDisposed = false;
  
  EventFormState get state => _state;
  
  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
  
  void updateTitle(String value) {
    if (_isDisposed) return;
    _state = _state.copyWith(title: value);
    notifyListeners();
  }
  
  void addTicketType(TicketTypeFormData ticket) {
    if (_isDisposed) return;
    _state = _state.copyWith(
      ticketTypes: [..._state.ticketTypes, ticket],
    );
    notifyListeners();
  }
  
  Future<void> saveEvent(WidgetRef ref) async {
    if (_isDisposed || !_state.isValid) return;
    
    final repo = ref.read(eventRepositoryProvider);
    
    // Crear evento
    final event = Event(
      id: _state.id ?? uuid.v4(),
      title: _state.title,
      mainArtist: _state.mainArtist,
      // ... resto de campos
    );
    
    if (_state.id == null) {
      await repo.createEvent(event);
    } else {
      await repo.updateEvent(event);
    }
    
    // Crear/actualizar ticket types
    for (final ticket in _state.ticketTypes) {
      await repo.createOrUpdateTicketType(ticket.toTicketType(event.id));
    }
  }
}

final eventFormProvider = ChangeNotifierProvider<EventFormNotifier>((ref) {
  return EventFormNotifier();
});
```

---

## 🎴 CARDS DEL FORMULARIO

### 1. FormDetailsCard
**Campos:**
- Título (TextField)
- Artista Principal (TextField)
- Género (Dropdown: Techno, House, Trance, etc)
- Organizador (TextField)
- Descripción (TextArea, 5 líneas)

### 2. FormLocationCard
**Campos:**
- Fecha (DatePicker)
- Hora (TimePicker)
- Venue (TextField)
- Ciudad (TextField)
- Dirección (TextField)
- Mapa (MapPickerDialog - actualmente mock)

### 3. FormLineupCard
**Campos:**
- Lista dinámica de artistas
- Cada artista: nombre + toggle "Headliner"
- Botón "Agregar Artista"
- Botón "Eliminar" por artista

### 4. FormCapacityPricingCard
**Campos:**
- Lista dinámica de tandas
- Cada tanda:
  - Nombre (TextField)
  - Precio (TextField numérico, en centavos)
  - Cantidad (TextField numérico)
  - Max por persona (TextField numérico, opcional)
- Botón "Agregar Tanda"
- Botón "Eliminar" por tanda

### 5. FormFeaturesCard
**Campos:**
- Grid de chips seleccionables:
  - Open Bar
  - Food Court
  - VIP Area
  - Parking
  - Outdoor
  - 21+
  - All Ages
  - Merchandise

### 6. FormPosterCard
**Campos:**
- Botón "Seleccionar Imagen"
- Preview de imagen seleccionada
- Crop automático con ImageCropperDialog

---

## 🖼️ LIVE PREVIEW

**Componente:** `LivePreviewCard`  
**Ubicación:** Columna derecha (40% del ancho)  
**Reactivo:** Se actualiza con cada cambio en `eventFormProvider`

**Muestra:**
- Imagen del poster (o placeholder)
- Título + Artista
- Fecha + Hora
- Ubicación (venue + ciudad)
- Line-up (lista de DJs)
- Features (chips)
- Tandas (lista con precios)

---

## 🔧 VALIDACIONES

### Por Status

| Status | Campos Requeridos |
|--------|-------------------|
| `draft` | Ninguno (siempre válido) |
| `upcoming` | Todos excepto `organizerName`, `description`, `genre` |
| `cancelled` | Solo `title` |

### Validaciones Adicionales

```dart
// Precio > 0
if (ticketType.price <= 0) {
  return 'El precio debe ser mayor a 0';
}

// Cantidad > 0
if (ticketType.totalQuantity <= 0) {
  return 'La cantidad debe ser mayor a 0';
}

// Max por persona <= cantidad total
if (ticketType.maxPerPurchase > ticketType.totalQuantity) {
  return 'El máximo por persona no puede superar la cantidad total';
}

// Fecha en el futuro (solo si status = upcoming)
if (status == EventStatus.upcoming && startDate.isBefore(DateTime.now())) {
  return 'La fecha debe ser en el futuro';
}
```

---

## 💾 GUARDADO EN DB

### Transacción

```dart
Future<void> saveEvent() async {
  // 1. Upload imagen (genera thumbnails automáticos)
  final imageUrls = await storageService.uploadEventImage(eventId, imageBytes);
  
  // 2. Guardar evento
  await _client.from('events').upsert({
    ...event.toJson(),
    'image_url': imageUrls.medium,
    'thumbnail_url': imageUrls.thumb,
    'full_image_url': imageUrls.full,
  });
  
  // 3. Guardar categorías y tiers
  for (final category in categories) {
    await _client.from('ticket_categories').upsert(category.toJson());
    for (final tier in category.tiers) {
      await _client.from('ticket_tiers').upsert(tier.toJson());
    }
  }
}
```

### Sistema de Imágenes

Al subir imagen, `StorageService` genera automáticamente:
- `thumbnail_url` - 300x300 (listas, cards pequeñas)
- `image_url` - 600x600 (cards, previews)
- `full_image_url` - Original optimizado (hero sections)

### Campos en DB

```sql
INSERT INTO events (
  id, producer_id, title, slug, main_artist, lineup,
  start_datetime, end_datetime, venue_name, address, city,
  lat, lng, genre, description, organizer_name, features,
  image_url, thumbnail_url, full_image_url,
  status, is_published, total_capacity, show_all_ticket_types
) VALUES (...);

INSERT INTO ticket_categories (
  id, event_id, name, description, max_per_purchase, order_index
) VALUES (...);

INSERT INTO ticket_tiers (
  id, category_id, name, price, quantity, sold_count,
  is_active, sale_starts_at, sale_ends_at, order_index
) VALUES (...);
```

---

## 🐛 ISSUES CONOCIDOS

1. **MapPickerDialog es mock** - 3 ubicaciones hardcodeadas
2. **Slug generation** - Actualmente manual, debería ser auto-generado

---

## 🚀 MEJORAS PENDIENTES

- [ ] Google Maps integration real
- [ ] Auto-generar slug desde título
- [ ] Drag & drop para reordenar lineup
- [ ] Validación de fechas solapadas (mismo venue)
