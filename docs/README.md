ok# EVIO CLUB - DOCUMENTACIÓN PRINCIPAL

**Stack:** Flutter + Riverpod 2.6.1 + Supabase (dev) → AWS (prod)  
**Arquitectura:** Clean Architecture (UI → Providers → Repositories → DB)

---

## 📦 ESTRUCTURA MONOREPO

```
evio/
├── packages/evio_core/       # Shared: models, repos, theme
├── apps/evio_admin/          # Web dashboard (productores)
└── apps/evio_fan/            # Mobile app (fans)
```

**Dependencies:** Dart pub workspaces con `path:`

```yaml
dependencies:
  evio_core:
    path: ../../packages/evio_core
```

---

## 🎨 DESIGN SYSTEM - TOKENS OBLIGATORIOS

### ❌ NUNCA HARDCODEAR

```dart
// ❌ MAL
Container(
  padding: EdgeInsets.all(32),
  decoration: BoxDecoration(
    color: Color(0xFFFFFFFF),
    borderRadius: BorderRadius.circular(12),
  ),
  child: Text('Hola', style: TextStyle(fontSize: 24)),
)

// ✅ BIEN
Container(
  padding: EdgeInsets.all(EvioSpacing.xl),
  decoration: BoxDecoration(
    color: EvioLightColors.card,
    borderRadius: BorderRadius.circular(EvioRadius.card),
  ),
  child: Text('Hola', style: EvioTypography.h1),
)
```

### Tokens Disponibles

| Token | Uso |
|-------|-----|
| **Colors** | `EvioLightColors.*` (admin), `EvioFanColors.*` (fan) |
| **Spacing** | `xxs(4), xs(8), sm(12), md(16), lg(24), xl(32), xxl(48)` |
| **Radius** | `button(10), card(12), input(10)` |
| **Typography** | `h1, h2, h3, h4, body*, label*, button, caption` |

**Import obligatorio:**
```dart
import 'package:evio_core/evio_core.dart';
```

📖 **Detalle completo:** `view docs/architecture/design_system.md`

---

## 🛡️ CÓDIGO "A PRUEBA DE BOMBAS" (OBLIGATORIO)

**REGLA CRÍTICA:** Todo StatefulWidget DEBE seguir este patrón.

```dart
class MyScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends ConsumerState<MyScreen> {
  bool _isDisposed = false;
  Timer? _timer;
  final _controller = ScrollController();
  
  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }
  
  Future<void> _load() async {
    if (_isDisposed) return;  // ✅ Check ANTES de async
    
    final data = await getData().timeout(Duration(seconds: 10));
    
    if (_isDisposed || !mounted) return;  // ✅ Check ANTES de setState
    setState(() => _data = data);
  }
}
```

### Checklist:
- ✅ Flag `_isDisposed`
- ✅ Listeners removidos en `dispose()`
- ✅ Timers/Streams cancelados
- ✅ Controllers dispuestos
- ✅ Check `_isDisposed` antes de async
- ✅ Check `mounted` antes de `setState()`
- ✅ Timeout en operaciones async (10-15s)

---

## 📁 ARQUITECTURA

```
UI (screens + widgets)
    ↓ usa
PROVIDERS (Riverpod)
    ↓ llama
REPOSITORIES (evio_core)
    ↓ habla con
SUPABASE / AWS
```

**Ejemplo:**
```dart
// 1. Repository (evio_core)
abstract class EventRepository {
  Future<List<Event>> getEvents();
}

// 2. Provider (app)
final eventsProvider = FutureProvider<List<Event>>((ref) async {
  final repo = ref.watch(eventRepositoryProvider);
  return repo.getEvents();
});

// 3. UI (app)
class DashboardScreen extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);
    return eventsAsync.when(
      data: (events) => EventGrid(events: events),
      loading: () => CircularProgressIndicator(),
      error: (e, st) => Text('Error: $e'),
    );
  }
}
```

📖 **Detalle completo:** `view docs/architecture/providers.md`

---

## 🗄️ BASE DE DATOS

**Tablas principales:**
- `users` - Usuarios (fans + productores)
- `producers` - Productoras/Organizadores
- `events` - Eventos
- `ticket_types` - Tandas de tickets
- `tickets` - Entradas individuales
- `orders` - Órdenes de compra
- `coupons` - Cupones de descuento

📖 **Schema completo + RLS:** `view docs/architecture/database.md`

---

## 📚 DOCUMENTACIÓN EXTENDIDA

**Usa `view docs/[ruta]` para acceder a:**

### Flujos
- `flows/event_creation.md` - Crear evento (Admin)
- `flows/checkout_flow.md` - Compra de tickets (Fan)
- `flows/auth_flow.md` - Autenticación completa

### Arquitectura
- `architecture/design_system.md` - Tokens + Themes detallados
- `architecture/database.md` - Schema + Migrations + RLS
- `architecture/providers.md` - Patrones Riverpod

### Referencia
- `reference/models.md` - Todos los modelos (Event, TicketType, etc)
- `reference/widgets.md` - Widgets reutilizables

---

## 🎯 ESTADO ACTUAL

| Módulo | Progreso | Estado |
|--------|----------|--------|
| **evio_core** | 95% | ✅ Design system, models, repos completos |
| **evio_admin** | 90% | ✅ Auth, CRUD eventos, settings, stats |
| **evio_fan** | 30% | 🚧 Home + Event Detail completos, checkout en progreso |

---

## 🔑 CONVENCIONES

### Git Commits
```bash
feat(admin): agregar stats con datos reales
fix(core): corregir validación de maxPerPurchase
refactor(fan): migrar hardcoded colors a tokens
```

### Orden de Imports
```dart
// 1. Dart core
import 'dart:async';

// 2. Flutter
import 'package:flutter/material.dart';

// 3. External packages
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 4. evio_core (SIEMPRE primero)
import 'package:evio_core/evio_core.dart';

// 5. Relative imports
import '../../widgets/stat_card.dart';
```

---

## ⚠️ ISSUES CONOCIDOS

1. **Checkout flow incompleto** (evio_fan) - En progreso
2. **Image upload temporal** - Solo guarda bytes en memoria
3. **MapPicker es mock** - 3 ubicaciones hardcodeadas
4. **Getters pendientes:** `Event.soldCount`, `minPrice`, `maxPrice`

---

## 🚀 PRÓXIMOS PASOS

1. **Completar checkout** (evio_fan) - Integrar con orders
2. **Image upload** - Supabase Storage
3. **Google Maps** - Reemplazar MapPickerDialog mock
4. **Statistics** - Implementar getters con JOINs reales

---

**Última actualización:** 22 Diciembre 2025  
**Versión:** 2.0
