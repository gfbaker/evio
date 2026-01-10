# PROVIDERS - RIVERPOD

Patrones y estructura de providers en Evio Club.

**Stack:** Riverpod 2.6.1 + Supabase

---

## 📐 ARQUITECTURA

```
UI (screens/widgets)
    ↓ watch/read
PROVIDERS (Riverpod)
    ↓ llama
REPOSITORIES (evio_core)
    ↓ query
SUPABASE
```

---

## 🔑 TIPOS DE PROVIDERS

### FutureProvider (datos async)

```dart
// Para datos que se cargan una vez
final eventDetailProvider = FutureProvider.family<Event, String>((ref, eventId) async {
  final repo = ref.watch(eventRepositoryProvider);
  return repo.getEventById(eventId);
});

// Uso en UI
final eventAsync = ref.watch(eventDetailProvider(eventId));
return eventAsync.when(
  data: (event) => EventDetail(event: event),
  loading: () => LoadingWidget(),
  error: (e, st) => ErrorWidget(e),
);
```

### StateNotifierProvider (estado mutable)

```dart
// Para estado que cambia con acciones del usuario
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState.empty());
  
  void addItem(String tierId, int quantity, int price) {
    state = state.copyWith(
      items: [...state.items, CartItem(tierId, quantity, price)],
    );
  }
  
  void clear() => state = CartState.empty();
}
```

### StreamProvider (datos en tiempo real)

```dart
// Para suscripciones realtime
final ticketsStreamProvider = StreamProvider<List<Ticket>>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return Stream.value([]);
  
  return supabase
    .from('tickets')
    .stream(primaryKey: ['id'])
    .eq('owner_id', userId)
    .map((data) => data.map(Ticket.fromJson).toList());
});
```

---

## 📦 PROVIDERS POR MÓDULO

### Auth (evio_admin & evio_fan)

```dart
// Estado de autenticación
final authStateProvider = StreamProvider<AuthState>((ref) {
  return supabase.auth.onAuthStateChange;
});

// Usuario actual (con datos de public.users)
final currentUserProvider = FutureProvider<User?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final authUser = authState.value?.session?.user;
  if (authUser == null) return null;
  
  final repo = ref.watch(userRepositoryProvider);
  return repo.getUserByAuthId(authUser.id);
});

// Notifier para acciones de auth
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
```

### Events (evio_admin)

```dart
// Lista de eventos del productor
final eventsProvider = FutureProvider<List<Event>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user?.producerId == null) return [];
  
  final repo = ref.watch(eventRepositoryProvider);
  return repo.getEventsByProducer(user!.producerId!);
});

// Evento específico
final eventDetailProvider = FutureProvider.family<Event, String>((ref, id) async {
  final repo = ref.watch(eventRepositoryProvider);
  return repo.getEventById(id);
});

// Stats de evento
final eventStatsProvider = FutureProvider.family<EventStats, String>((ref, id) async {
  final repo = ref.watch(eventRepositoryProvider);
  return repo.getEventStats(id);
});

// Form state para crear/editar
final eventFormProvider = ChangeNotifierProvider<EventFormNotifier>((ref) {
  return EventFormNotifier();
});
```

### Events (evio_fan)

```dart
// Eventos publicados
final publishedEventsProvider = FutureProvider<List<Event>>((ref) async {
  final repo = ref.watch(eventRepositoryProvider);
  return repo.getPublishedEvents();
});

// Eventos destacados
final featuredEventsProvider = FutureProvider<List<Event>>((ref) async {
  final repo = ref.watch(eventRepositoryProvider);
  return repo.getFeaturedEvents();
});

// Búsqueda
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Event>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  
  final repo = ref.watch(eventRepositoryProvider);
  return repo.searchEvents(query);
});
```

### Tickets (evio_fan)

```dart
// Categorías con tiers de un evento
final ticketCategoriesProvider = FutureProvider.family<List<TicketCategory>, String>((ref, eventId) async {
  final repo = ref.watch(ticketRepositoryProvider);
  return repo.getCategoriesWithTiers(eventId);
});

// Tickets del usuario
final userTicketsProvider = FutureProvider<List<Ticket>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];
  
  final repo = ref.watch(ticketRepositoryProvider);
  return repo.getTicketsByUser(user.id);
});
```

### Cart & Checkout (evio_fan)

```dart
// Estado del carrito
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});

// Checkout
final checkoutProvider = StateNotifierProvider<CheckoutNotifier, CheckoutState>((ref) {
  return CheckoutNotifier(ref);
});
```

---

## 🔄 INVALIDACIÓN Y REFRESH

### Invalidar después de mutación

```dart
// Después de crear evento
await repo.createEvent(event);
ref.invalidate(eventsProvider);  // Refetch lista

// Después de comprar tickets
await repo.createOrder(order);
ref.invalidate(userTicketsProvider);
ref.invalidate(ticketCategoriesProvider(eventId));
```

### Refresh manual

```dart
// Pull to refresh
RefreshIndicator(
  onRefresh: () => ref.refresh(eventsProvider.future),
  child: EventList(),
)
```

---

## ⚠️ PATRONES IMPORTANTES

### Family providers con autoDispose

```dart
// Se dispone cuando nadie lo observa
final eventDetailProvider = FutureProvider.autoDispose.family<Event, String>((ref, id) async {
  // Mantener vivo por 30 segundos después de dejar la pantalla
  ref.keepAlive();
  final timer = Timer(Duration(seconds: 30), () => ref.invalidateSelf());
  ref.onDispose(() => timer.cancel());
  
  return ref.watch(eventRepositoryProvider).getEventById(id);
});
```

### Dependencias entre providers

```dart
// eventsProvider depende de currentUserProvider
final eventsProvider = FutureProvider<List<Event>>((ref) async {
  // Esto hace que eventsProvider se recalcule cuando currentUserProvider cambie
  final user = await ref.watch(currentUserProvider.future);
  if (user?.producerId == null) return [];
  
  return ref.watch(eventRepositoryProvider).getEventsByProducer(user!.producerId!);
});
```

### Optimistic updates

```dart
class EventsNotifier extends StateNotifier<AsyncValue<List<Event>>> {
  EventsNotifier(this.ref) : super(const AsyncValue.loading());
  final Ref ref;
  
  Future<void> deleteEvent(String eventId) async {
    final currentEvents = state.value ?? [];
    
    // Optimistic: remover inmediatamente
    state = AsyncValue.data(
      currentEvents.where((e) => e.id != eventId).toList(),
    );
    
    try {
      await ref.read(eventRepositoryProvider).deleteEvent(eventId);
    } catch (e) {
      // Rollback si falla
      state = AsyncValue.data(currentEvents);
      rethrow;
    }
  }
}
```

---

## 📍 UBICACIÓN DE ARCHIVOS

```
apps/evio_admin/lib/providers/
├── auth_provider.dart
├── event_providers.dart
├── settings_provider.dart
└── stats_provider.dart

apps/evio_fan/lib/providers/
├── auth_provider.dart
├── event_provider.dart
├── ticket_provider.dart
├── cart_provider.dart
└── checkout_provider.dart
```

---

## 🚫 ANTI-PATTERNS

```dart
// ❌ MAL: Usar ref.read en build
Widget build(context, ref) {
  final events = ref.read(eventsProvider);  // No reactivo!
}

// ✅ BIEN: Usar ref.watch en build
Widget build(context, ref) {
  final events = ref.watch(eventsProvider);  // Reactivo
}

// ❌ MAL: Crear provider dentro de widget
final myProvider = Provider((ref) => ...);  // Se recrea cada rebuild!

// ✅ BIEN: Providers como top-level
final myProvider = Provider((ref) => ...);  // Fuera de cualquier clase/función
```
