# FLUJO: CHECKOUT (evio_fan)

Compra de tickets desde selección hasta generación de QR.

**Última actualización:** 6 Enero 2026

---

## 📋 OVERVIEW

```
EventDetailScreen (seleccionar tickets)
    ↓
AuthBottomSheet (si no autenticado)
    ↓
CheckoutScreen (confirmar compra)
    ↓
create_order_safe() RPC (atómico)
    ↓
TicketDetailScreen (ver QR)
```

---

## 🎯 FLUJO DETALLADO

### 1. Selección de tickets (EventDetailScreen)

```dart
// Usuario selecciona cantidad por tier
final cartProvider = StateNotifierProvider<CartNotifier, CartState>(...);

// CartState
class CartState {
  final String? eventId;
  final Map<String, int> quantities;  // tierId → quantity
  final Map<String, int> prices;      // tierId → unitPrice
  
  int get totalAmount => quantities.entries.fold(0, (sum, e) => 
    sum + (e.value * (prices[e.key] ?? 0)));
  
  int get totalTickets => quantities.values.fold(0, (a, b) => a + b);
}
```

### 2. Verificación de auth

```dart
// En BottomPurchaseCTA
void _onPurchasePressed() {
  final user = ref.read(currentUserProvider);
  
  if (user == null) {
    // Mostrar AuthBottomSheet con redirect a checkout
    showModalBottomSheet(
      context: context,
      builder: (_) => AuthBottomSheet(
        redirectTo: '/checkout/${event.id}',
      ),
    );
    return;
  }
  
  // Usuario autenticado → ir a checkout
  context.push('/checkout/${event.id}');
}
```

### 3. AuthBottomSheet

Modal que permite login/register sin perder el contexto:

```dart
class AuthBottomSheet extends ConsumerWidget {
  final String? redirectTo;
  
  // Tabs: Login | Crear cuenta
  // Post-auth: Navigator.pop() + GoRouter.push(redirectTo)
}
```

### 4. CheckoutScreen

```dart
// Muestra resumen de compra
- Event info (imagen, título, fecha)
- Lista de items seleccionados
- Subtotal / Descuento / Total
- Botón "Confirmar compra"

// Providers
final checkoutProvider = StateNotifierProvider<CheckoutNotifier, CheckoutState>(...);

class CheckoutState {
  final bool isLoading;
  final String? error;
  final Order? completedOrder;
}
```

### 5. Proceso de compra (atómico)

```dart
Future<void> confirmPurchase() async {
  state = state.copyWith(isLoading: true, error: null);
  
  try {
    // Llamar RPC atómico
    final orderId = await supabase.rpc('create_order_safe', params: {
      'p_user_id': userId,
      'p_event_id': eventId,
      'p_items': items.map((i) => {
        'tier_id': i.tierId,
        'quantity': i.quantity,
        'unit_price': i.unitPrice,
      }).toList(),
      'p_total_amount': totalAmount,
    });
    
    // Obtener orden completa
    final order = await orderRepository.getOrderById(orderId);
    
    state = state.copyWith(
      isLoading: false,
      completedOrder: order,
    );
  } catch (e) {
    state = state.copyWith(isLoading: false, error: e.toString());
  }
}
```

### 6. RPC `create_order_safe`

Función SQL que hace todo atómicamente:

```sql
-- 1. Validar disponibilidad (FOR UPDATE lock)
-- 2. Crear order
-- 3. Crear order_items
-- 4. Crear tickets con QR único
-- 5. Trigger actualiza sold_count en ticket_tiers
```

Ver `docs/architecture/database.md` para código completo.

### 7. Success → Ver tickets

```dart
// Después de compra exitosa
showDialog(
  context: context,
  builder: (_) => AlertDialog(
    title: Text('¡Compra exitosa!'),
    content: Text('Tus tickets están listos'),
    actions: [
      TextButton(
        onPressed: () {
          Navigator.pop(context);
          context.go('/tickets');  // Ir a mis tickets
        },
        child: Text('Ver mis tickets'),
      ),
    ],
  ),
);
```

---

## 🎫 GENERACIÓN DE TICKETS

Cada ticket generado tiene:

```dart
Ticket(
  id: uuid(),
  eventId: eventId,
  tierId: tierId,
  orderId: orderId,
  ownerId: userId,
  qrSecret: uuid(),        // Único, para validación
  status: 'valid',
  isInvitation: false,
  transferAllowed: false,
  transferCount: 0,
)
```

El QR codifica: `$ticketId|$qrSecret`

---

## 🖼️ DISEÑO DEL TICKET (TicketDetailScreen)

Ticket con diseño custom:

```
┌─────────────────────────────────────┐
│  🎵  EVIO CLUB                      │
│  ═══════════════════════════════════│
│                                     │
│  [    QR CODE    ]                  │
│  [               ]                  │
│  [               ]                  │
│                                     │
│  ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈│  ← Línea perforada
│                                     │
│  Nina Kraviz                        │
│  Groove - Buenos Aires              │
│  Sábado 15 Enero, 23:00             │
│                                     │
│  General - Early Bird               │
│  Ticket #1 de 2                     │
└─────────────────────────────────────┘
```

Features:
- Fondo topográfico animado
- Brillo automático al 100% al abrir
- Restaura brillo original al salir
- Swipe horizontal entre tickets del mismo evento

---

## ⚠️ VALIDACIONES

### Client-side (antes de checkout)

```dart
// En EventDetailScreen
- Verificar stock disponible
- Verificar max_per_purchase por tier
- Verificar is_active del tier
- Verificar sale_starts_at / sale_ends_at
```

### Server-side (en RPC)

```sql
-- FOR UPDATE lock previene overselling
SELECT (quantity - sold_count) INTO v_available
FROM ticket_tiers WHERE id = v_tier_id FOR UPDATE;

IF v_available < v_quantity THEN
  RAISE EXCEPTION 'Insufficient stock for tier %', v_tier_id;
END IF;
```

---

## 🔄 ESTADOS DEL CHECKOUT

```dart
enum CheckoutStatus {
  idle,           // Inicial
  loading,        // Procesando pago
  success,        // Compra exitosa
  error,          // Error (mostrar mensaje)
  stockError,     // Sin stock (volver a seleccionar)
}
```

---

## 📍 ARCHIVOS RELACIONADOS

```
apps/evio_fan/lib/
├── screens/
│   ├── event_detail/
│   │   └── widgets/
│   │       ├── tickets_section.dart
│   │       ├── quantity_selector.dart
│   │       └── bottom_purchase_cta.dart
│   │
│   ├── checkout/
│   │   └── checkout_screen.dart
│   │
│   └── tickets/
│       ├── tickets_screen.dart
│       └── ticket_detail_screen.dart
│
├── providers/
│   ├── checkout_provider.dart
│   ├── order_provider.dart
│   └── ticket_provider.dart
│
└── widgets/
    └── auth/
        └── auth_bottom_sheet.dart
```

---

## 🚧 PENDIENTE

- [ ] Integrar Mercado Pago (actualmente mock)
- [ ] Apple Wallet passes
- [ ] Transferencia de tickets
- [ ] Cupones de descuento en checkout
