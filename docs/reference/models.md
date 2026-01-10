# MODELOS - EVIO CORE

Todos los modelos están en `packages/evio_core/lib/models/`

**Última actualización:** 6 Enero 2026 | **Schema:** V2

---

## Event

**Tabla:** `events`

```dart
class Event {
  final String id;
  final String producerId;
  
  // Básico
  final String title;
  final String slug;
  final String mainArtist;
  final List<LineupArtist> lineup;  // [{name, is_headliner, image_url}]
  
  // Fecha/Hora
  final DateTime startDatetime;
  final DateTime? endDatetime;
  
  // Ubicación
  final String venueName;
  final String address;
  final String city;
  final double? lat;
  final double? lng;
  
  // Info
  final String? genre;
  final String? description;
  final String? organizerName;
  final List<String>? features;
  
  // Imágenes (sistema de thumbnails)
  final String? imageUrl;        // Croppeada (cuadrada, cards)
  final String? thumbnailUrl;    // 300x300 (listas)
  final String? fullImageUrl;    // Original (hero)
  final String? videoUrl;        // YouTube/Vimeo
  
  // Estado
  final EventStatus status;      // draft, upcoming, cancelled
  final bool isPublished;
  final int? totalCapacity;
  final bool showAllTicketTypes; // Mostrar tandas inactivas en fan
  
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Getters
  bool get isPast;
  bool get isOngoing;
}

enum EventStatus { draft, upcoming, cancelled }
```

---

## TicketCategory (Freezed)

**Tabla:** `ticket_categories`  
Categorías de tickets (General, VIP, Mesa, etc).

```dart
@freezed
class TicketCategory with _$TicketCategory {
  const factory TicketCategory({
    required String id,
    required String eventId,
    required String name,
    String? description,
    int? maxPerPurchase,
    required int orderIndex,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default([]) List<TicketTier> tiers,  // Cargados con JOIN
  }) = _TicketCategory;
}
```

---

## TicketTier (Freezed)

**Tabla:** `ticket_tiers`  
Tandas dentro de cada categoría (Early Bird, Regular, etc).

```dart
@freezed
class TicketTier with _$TicketTier {
  const factory TicketTier({
    required String id,
    @JsonKey(name: 'category_id') required String ticketCategoryId,
    required String name,
    String? description,
    required int price,              // Centavos
    required int quantity,           // Stock total
    @JsonKey(name: 'sold_count') required int soldCount,
    @JsonKey(name: 'order_index') required int orderIndex,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'sale_starts_at') DateTime? saleStartsAt,
    @JsonKey(name: 'sale_ends_at') DateTime? saleEndsAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _TicketTier;
  
  // Getters
  int get availableQuantity => quantity - soldCount;
  bool get isSoldOut => soldCount >= quantity;
  bool get isLowStock => availableQuantity > 0 && availableQuantity <= 10;
}

enum TierStatus {
  waiting,    // Esperando tier anterior
  scheduled,  // Tiene fecha futura
  active,     // Disponible para compra
  paused,     // Pausada manualmente (is_active = false)
  soldOut,    // Agotada
  ended,      // Pasó fecha fin
}
```

**Relación:** `Event` → `TicketCategory` → `TicketTier`

---

## Ticket

**Tabla:** `tickets`  
Entrada individual con QR.

```dart
class Ticket {
  final String id;
  final String eventId;
  final String tierId;           // FK a ticket_tiers
  final String? orderId;
  final String ownerId;
  final String? originalOwnerId; // Para transferencias
  
  final String qrSecret;         // UUID único
  final TicketStatus status;
  final bool isInvitation;
  final bool transferAllowed;
  final int transferCount;       // Max 3
  
  final DateTime? usedAt;
  final String? usedByDni;
  final DateTime? createdAt;
  
  // Relaciones (JOINs)
  final Event? event;
  final TicketTier? tier;
  
  // Getters
  bool get isUsable => status == TicketStatus.valid;
  bool get canTransfer => transferAllowed && isUsable && transferCount < 3;
  String get qrData => '$id|$qrSecret';
}

enum TicketStatus { valid, used, cancelled, expired }
```

---

## Order

**Tabla:** `orders`

```dart
class Order {
  final String id;
  final String userId;
  final String eventId;
  
  final OrderStatus status;
  final int totalAmount;         // Centavos
  final String currency;         // 'ARS'
  final String? paymentProvider; // 'mercadopago', 'mock'
  final String? paymentId;
  final String? couponId;
  final int discountAmount;
  
  final DateTime? createdAt;
  final DateTime? paidAt;
  final DateTime? updatedAt;
  
  final List<OrderItem> items;
  
  // Getters
  bool get isPaid => status == OrderStatus.paid;
  int get subtotal => totalAmount + discountAmount;
  int get totalTickets => items.fold(0, (sum, i) => sum + i.quantity);
}

enum OrderStatus { pending, paid, failed, refunded, cancelled }
```

---

## OrderItem

**Tabla:** `order_items`

```dart
class OrderItem {
  final String tierId;    // FK a ticket_tiers (NO ticket_types)
  final int quantity;
  final int unitPrice;    // Precio al momento de compra
}
```

---

## User

**Tabla:** `users`

```dart
class User {
  final String id;
  final String authProviderId;   // Supabase auth.uid()
  
  final String? firstName;
  final String? lastName;
  final String email;
  final String? phone;
  final String? avatarUrl;
  
  final UserRole role;
  final String? producerId;      // FK a producers
  
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

enum UserRole {
  fan,          // Compra tickets (evio_fan)
  admin,        // Dueño productora, CRUD completo (evio_admin)
  collaborator, // Miembro equipo, permisos limitados (evio_admin)
}
```

---

## Producer

**Tabla:** `producers`

```dart
class Producer {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? logoUrl;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
```

---

## UserInvitation

**Tabla:** `user_invitations`

```dart
class UserInvitation {
  final String id;
  final String producerId;
  final String email;
  final String? firstName;
  final String? lastName;
  final UserRole role;           // admin o collaborator
  final UserInvitationStatus status;
  final DateTime? expiresAt;
  final DateTime? createdAt;
}

enum UserInvitationStatus { pending, accepted, expired }
```

---

## Coupon

**Tabla:** `coupons`

```dart
class Coupon {
  final String id;
  final String code;
  final DiscountType discountType;  // percent o fixed
  final int discountValue;          // 50 = 50% o 5000 = $50
  final int? maxUses;
  final int usedCount;
  final DateTime? expiresAt;
  final bool isActive;
  final DateTime? createdAt;
}

enum DiscountType { percent, fixed }
```

---

## LineupArtist

**Helper** (JSONB en `events.lineup`)

```dart
class LineupArtist {
  final String name;
  final bool isHeadliner;
  final String? imageUrl;  // Spotify/custom
}
```

---

## EventStats

**Calculado** (no es tabla)

```dart
class EventStats {
  final String eventId;
  final int soldCount;
  final int totalRevenue;
  final int? minPrice;
  final int? maxPrice;
  final int? capacity;
  final double? occupancy;
}
```

---

## 📐 DIAGRAMA DE RELACIONES

```
Producer
    │
    ├── Users (producer_id)
    │
    └── Events (producer_id)
            │
            ├── TicketCategories (event_id)
            │        │
            │        └── TicketTiers (category_id)
            │                 │
            │                 ├── Tickets (tier_id)
            │                 │
            │                 └── OrderItems (tier_id)
            │
            └── Orders (event_id)
                    │
                    ├── OrderItems (order_id)
                    │
                    └── Tickets (order_id)
```

---

## 📝 CONVENCIONES

| Tipo | Formato | Ejemplo |
|------|---------|---------|
| **IDs** | UUID v4 | `c0fad1b0-fc1a-4eee-b290-85c647360263` |
| **Precios** | Centavos (int) | `5000` = $50.00 |
| **Fechas** | DateTime UTC | `2026-01-15T23:00:00.000Z` |
| **Listas** | `[]` si null | `lineup ?? []` |
| **Enums** | snake_case en DB | `sold_out` → `TierStatus.soldOut` |

### JsonKey para snake_case

```dart
@JsonKey(name: 'sold_count') required int soldCount,
@JsonKey(name: 'is_active') required bool isActive,
```

---

## 📍 UBICACIÓN DE ARCHIVOS

```
packages/evio_core/lib/models/
├── event.dart
├── event_stats.dart
├── event_status.dart
├── lineup_artist.dart
├── ticket_category.dart      # Freezed
├── ticket_category.freezed.dart
├── ticket_category.g.dart
├── ticket_tier.dart          # Freezed
├── ticket_tier.freezed.dart
├── ticket_tier.g.dart
├── ticket.dart
├── order.dart
├── order_item.dart
├── user.dart
├── producer.dart
├── user_invitation.dart
└── coupon.dart
```
