# MODELOS - EVIO CORE

Todos los modelos están en `packages/evio_core/lib/models/`

---

## Event

**Tabla:** `events`  
**Representa:** Un evento de música electrónica

```dart
class Event {
  // IDs
  final String id;               // UUID
  final String producerId;       // FK a producers
  
  // Básico
  final String title;            // "Nina Kraviz en Buenos Aires"
  final String slug;             // "nina-kraviz-buenos-aires"
  final String mainArtist;       // "Nina Kraviz"
  final List<LineupArtist> lineup; // [LineupArtist, ...]
  
  // Fecha/Hora
  final DateTime startDatetime;  // 2025-01-15 23:00:00
  final DateTime? endDatetime;   // Opcional
  
  // Ubicación
  final String venueName;        // "Groove"
  final String address;          // "Av. Costanera 5001"
  final String city;             // "Buenos Aires"
  final double? lat;             // -34.5678
  final double? lng;             // -58.4321
  
  // Info adicional
  final String? genre;           // "Techno"
  final String? description;     // Descripción larga
  final String? organizerName;   // "Evio Club"
  final List<String>? features;  // ["Open Bar", "VIP Area"]
  final String? imageUrl;        // URL del poster
  
  // Estado
  final EventStatus status;      // draft, upcoming, cancelled
  final bool isPublished;        // false = no visible en fan app
  final int? totalCapacity;      // 500 personas
  
  // Timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Getters computados
  bool get isPast;               // startDatetime < now
  bool get isOngoing;            // now entre start y end
  int get soldCount;             // TODO: implementar con JOIN
  int? get minPrice;             // TODO: implementar
  int? get maxPrice;             // TODO: implementar
}
```

### EventStatus (Enum)

```dart
enum EventStatus {
  draft,      // Borrador (sin validar)
  upcoming,   // Próximo (validado, puede publicarse)
  cancelled;  // Cancelado
  
  String get displayName {
    switch (this) {
      case draft: return 'Borrador';
      case upcoming: return 'Próximo';
      case cancelled: return 'Cancelado';
    }
  }
}
```

---

## TicketType (Tandas)

**Tabla:** `ticket_types`  
**Representa:** Una tanda de tickets con precio/cantidad específicos

```dart
class TicketType {
  final String id;               // UUID
  final String eventId;          // FK a events
  
  // Info
  final String name;             // "Early Bird"
  final int price;               // 5000 (centavos = $50.00)
  
  // Cantidades
  final int totalQuantity;       // 100 tickets en esta tanda
  final int soldQuantity;        // 35 vendidos
  
  // Límites
  final int? maxPerPurchase;     // 4 tickets por compra (opcional)
  
  // Fechas de venta
  final DateTime? saleStartAt;   // Inicio venta (opcional)
  final DateTime? saleEndAt;     // Fin venta (opcional)
  
  // Estado
  final bool isActive;           // true = se puede vender
  final int? sortOrder;          // Orden de display
  
  // Timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Getters computados
  int get availableQuantity => totalQuantity - soldQuantity;
  bool get isSoldOut => soldQuantity >= totalQuantity;
  bool get isLowStock => availableQuantity <= 10 && !isSoldOut;
}
```

---

## Ticket (Entradas individuales)

**Tabla:** `tickets`  
**Representa:** Una entrada única comprada por un fan

```dart
class Ticket {
  final String id;               // UUID
  final String eventId;          // FK a events
  final String ticketTypeId;     // FK a ticket_types
  final String ownerId;          // FK a users (fan)
  
  // QR
  final String qrSecret;         // UUID único para validar
  
  // Estado
  final TicketStatus status;     // valid, used, cancelled
  final DateTime? usedAt;        // Timestamp cuando se usó
  
  // Timestamps
  final DateTime? createdAt;
}

enum TicketStatus {
  valid,      // No usado, válido
  used,       // Ya usado en puerta
  cancelled;  // Cancelado (refund)
}
```

---

## Order (Órdenes de compra)

**Tabla:** `orders`  
**Representa:** Una compra de tickets

```dart
class Order {
  final String id;               // UUID
  final String userId;           // FK a users (fan)
  final String eventId;          // FK a events
  
  // Items (tickets comprados)
  final List<OrderItem> items;   // [OrderItem, ...]
  
  // Pago
  final OrderStatus status;      // pending, paid, failed
  final int totalAmount;         // 15000 centavos = $150.00
  final String? paymentId;       // ID de MercadoPago
  
  // Timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

enum OrderStatus {
  pending,    // Esperando pago
  paid,       // Pagado exitosamente
  failed;     // Pago falló
}
```

### OrderItem

**Tabla:** `order_items`  
**Representa:** Un item dentro de una orden

```dart
class OrderItem {
  final String id;               // UUID
  final String orderId;          // FK a orders
  final String ticketTypeId;     // FK a ticket_types
  final int quantity;            // 2 tickets
  final int price;               // 5000 centavos (precio al momento de compra)
  
  int get subtotal => quantity * price;
}
```

---

## User

**Tabla:** `users`  
**Representa:** Usuario (fan o productor)

```dart
class User {
  final String id;               // UUID
  final String authProviderId;   // Supabase auth.uid()
  
  // Info personal
  final String? firstName;       // "Guillermo"
  final String? lastName;        // "Baker"
  final String email;            // "g.baker@gmail.com"
  final String? phone;           // "+54 9 11 1234-5678"
  final String? avatarUrl;       // URL foto perfil
  
  // Rol
  final UserRole role;           // fan, producer, admin
  
  // Relación con productor
  final String? producerId;      // FK a producers (si es producer/admin)
  
  // Timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

enum UserRole {
  fan,        // Compra tickets
  producer,   // Crea eventos
  admin;      // Gestiona productora
}
```

---

## Producer

**Tabla:** `producers`  
**Representa:** Una productora/organizador de eventos

```dart
class Producer {
  final String id;               // UUID
  final String name;             // "Evio Club"
  final String? email;           // "info@evioclub.com"
  final String? phone;           // "+54 9 11 5678-1234"
  final String? logoUrl;         // URL logo
  final String? description;     // Descripción de la productora
  
  // Timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
```

---

## UserInvitation

**Tabla:** `user_invitations`  
**Representa:** Invitación pendiente para unirse a una productora

```dart
class UserInvitation {
  final String id;               // UUID
  final String producerId;       // FK a producers
  final String email;            // Email del invitado
  final String? firstName;       // Nombre del invitado
  final String? lastName;        // Apellido del invitado
  final UserRole role;           // producer o admin
  final UserInvitationStatus status; // pending, accepted, expired
  final DateTime? expiresAt;     // Fecha de expiración (opcional)
  
  // Timestamps
  final DateTime? createdAt;
}

enum UserInvitationStatus {
  pending,    // Esperando que se registre
  accepted,   // Usuario se registró
  expired;    // Expiró
}
```

**Flujo:**
1. Admin crea invitación en `UsersScreen`
2. Se guarda en `user_invitations` con `status = pending`
3. Usuario se registra con ese email
4. Trigger automático en Supabase:
   - Asocia `user.producer_id = invitation.producer_id`
   - Asigna `user.role = invitation.role`
   - Marca invitación como `accepted`

---

## Coupon

**Tabla:** `coupons`  
**Representa:** Cupón de descuento

```dart
class Coupon {
  final String id;               // UUID
  final String code;             // "PROMO50"
  
  // Descuento (solo uno debe estar presente)
  final int? discountPercent;    // 50 (50% off)
  final int? discountFixed;      // 1000 centavos ($10 off)
  
  // Límites
  final int? maxUses;            // 100 usos máximo
  final int usedCount;           // 35 ya usados
  
  // Validez
  final DateTime? expiresAt;     // Fecha de expiración
  final bool isActive;           // true = se puede usar
  
  // Timestamps
  final DateTime? createdAt;
}
```

---

## LineupArtist

**Tipo:** Helper (no es tabla, se guarda como JSONB en `events.lineup`)

```dart
class LineupArtist {
  final String name;             // "Nina Kraviz"
  final bool isHeadliner;        // true
  
  Map<String, dynamic> toJson() => {
    'name': name,
    'is_headliner': isHeadliner,
  };
  
  factory LineupArtist.fromJson(Map<String, dynamic> json) {
    return LineupArtist(
      name: json['name'],
      isHeadliner: json['is_headliner'] ?? false,
    );
  }
}
```

---

## EventStats

**Tipo:** Calculado (no es tabla, se computa desde `ticket_types` y `tickets`)

```dart
class EventStats {
  final String eventId;
  
  // Ventas
  final int soldCount;           // Total tickets vendidos
  final int totalRevenue;        // Revenue en centavos
  
  // Precios
  final int? minPrice;           // Precio mínimo de tandas
  final int? maxPrice;           // Precio máximo de tandas
  
  // Capacidad
  final int? capacity;           // Capacidad total
  final double? occupancy;       // Porcentaje vendido (0.0-1.0)
}
```

**Cálculo:** Ver `EventRepository.getEventStats(eventId)`

---

## 🔄 RELACIONES

```
Producer
  └─ hasMany Users (via producerId)
  └─ hasMany Events (via producerId)

Event
  ├─ belongsTo Producer
  └─ hasMany TicketTypes
      └─ hasMany Tickets

User (fan)
  └─ hasMany Orders
      ├─ hasMany OrderItems
      └─ hasMany Tickets (generados post-pago)

UserInvitation
  ├─ belongsTo Producer
  └─ belongsToFuture User (via email)
```

---

## 📝 CONVENCIONES

### Fechas
- Siempre `DateTime` en UTC
- Formato DB: `2025-01-15T23:00:00.000Z`
- Display: Formatear con `intl` package

### Precios
- Siempre en **centavos** (int)
- $50.00 = 5000 centavos
- Display: `price / 100` + formato con `intl`

### IDs
- Siempre UUID v4
- Generar con `uuid` package
- Formato: `c0fad1b0-fc1a-4eee-b290-85c647360263`

### Listas
- `lineup`: JSONB array en DB
- `features`: TEXT[] array en DB
- Siempre devolver lista vacía `[]` si es null

### Opcionales
- Usar `?` para campos que pueden ser null
- Validar en `fromJson` con `?.toDouble()`, `?.toString()`
