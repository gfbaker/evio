# ESTRUCTURA DEL PROYECTO

Árbol completo de archivos del monorepo Evio.

---

## 📦 PAQUETES

### packages/evio_core/ (Shared Code)

```
packages/evio_core/
├── lib/
│   ├── evio_core.dart              # Export principal
│   │
│   ├── config/
│   │   └── supabase_config.dart    # Config de Supabase
│   │
│   ├── constants/
│   │   ├── app_constants.dart      # Constantes globales
│   │   ├── enums.dart              # EventStatus, UserRole, etc
│   │   └── error_messages.dart     # Mensajes de error
│   │
│   ├── models/
│   │   ├── event.dart              # ⭐ Modelo principal
│   │   ├── event_stats.dart        # Stats calculados
│   │   ├── event_status.dart       # Enum: draft, upcoming, cancelled
│   │   ├── lineup_artist.dart      # Helper para lineup
│   │   ├── ticket_type.dart        # Tandas de tickets
│   │   ├── ticket.dart             # Entradas individuales
│   │   ├── order.dart              # Órdenes de compra
│   │   ├── order_item.dart         # Items de orden
│   │   ├── user.dart               # Usuarios (fans + productores)
│   │   ├── producer.dart           # Productoras
│   │   ├── user_invitation.dart    # Invitaciones
│   │   └── coupon.dart             # Cupones
│   │
│   ├── repositories/
│   │   ├── event_repository.dart       # CRUD eventos
│   │   ├── ticket_repository.dart      # CRUD tickets
│   │   ├── order_repository.dart       # CRUD orders
│   │   ├── auth_repository.dart        # Auth + session
│   │   ├── producer_repository.dart    # CRUD productoras
│   │   ├── user_repository.dart        # CRUD usuarios
│   │   └── coupon_repository.dart      # CRUD cupones
│   │
│   ├── services/
│   │   └── supabase_service.dart   # Singleton Supabase client
│   │
│   ├── theme/
│   │   ├── evio_theme.dart         # ThemeData completo
│   │   ├── theme.dart              # Re-exports
│   │   └── tokens/
│   │       ├── colors.dart         # EvioLightColors, EvioFanColors
│   │       ├── spacing.dart        # EvioSpacing
│   │       ├── radius.dart         # EvioRadius
│   │       ├── typography.dart     # EvioTypography
│   │       └── gradients.dart      # EvioGradients
│   │
│   └── utils/
│       └── progress_color.dart     # Helper para progress bars
│
├── test/
│   └── evio_core_test.dart
│
├── pubspec.yaml
├── README.md
└── CHANGELOG.md
```

**Dependencies:**
- `flutter`
- `supabase_flutter: ^2.8.4`

---

## 💻 EVIO ADMIN (Web Dashboard)

```
apps/evio_admin/
├── lib/
│   ├── main.dart                   # Entry point
│   │
│   ├── config/
│   │   └── router.dart             # GoRouter + ShellRoute
│   │
│   ├── models/
│   │   └── event_form_state.dart   # Estado del formulario
│   │
│   ├── providers/
│   │   ├── auth_provider.dart          # ⭐ Auth state
│   │   ├── event_providers.dart        # ⭐ Events + form
│   │   └── settings_provider.dart      # Settings state
│   │
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   └── reset_password_screen.dart
│   │   │
│   │   ├── dashboard/
│   │   │   └── dashboard_screen.dart   # ⭐ Main dashboard
│   │   │
│   │   ├── events/
│   │   │   ├── event_list_screen.dart  # Lista de eventos
│   │   │   ├── event_detail_screen.dart # Detalle + editar
│   │   │   └── event_form_screen.dart   # ⭐ Crear/editar
│   │   │
│   │   ├── settings/
│   │   │   ├── settings_screen.dart    # Hub de settings
│   │   │   ├── profile_screen.dart     # Mi perfil
│   │   │   ├── company_screen.dart     # Mi productora
│   │   │   └── users_screen.dart       # Gestión de usuarios
│   │   │
│   │   └── statistics/
│   │       └── statistics_screen.dart  # Stats + gráficos
│   │
│   └── widgets/
│       ├── common/
│       │   ├── custom_dropdown.dart
│       │   ├── date_picker_field.dart
│       │   ├── time_picker_field.dart
│       │   ├── event_card.dart         # Card de evento (grid)
│       │   ├── event_list_item.dart    # Item de evento (lista)
│       │   ├── floating_snackbar.dart  # ⭐ Notificaciones
│       │   ├── form_card.dart          # Card wrapper
│       │   ├── label_input.dart        # Input con label
│       │   ├── simple_input.dart       # Input básico
│       │   └── stat_card.dart          # Card de estadística
│       │
│       ├── event_form/                 # ⭐ Form de eventos
│       │   ├── form_details_card.dart      # Card 1: Detalles
│       │   ├── form_location_card.dart     # Card 2: Ubicación
│       │   ├── form_lineup_card.dart       # Card 3: Line-up
│       │   ├── form_capacity_pricing_card.dart # Card 4: Tandas
│       │   ├── form_features_card.dart     # Card 5: Features
│       │   ├── form_poster_card.dart       # Card 6: Imagen
│       │   ├── form_header.dart            # Header del form
│       │   ├── live_preview_card.dart      # ⭐ Preview en vivo
│       │   ├── image_cropper_dialog.dart   # Dialog crop
│       │   └── map_picker_dialog.dart      # Dialog mapa (mock)
│       │
│       └── layout/
│           ├── admin_layout.dart       # ⭐ Layout base
│           └── admin_sidebar.dart      # ⭐ Sidebar persistente
│
├── web/
│   ├── index.html
│   └── manifest.json
│
├── pubspec.yaml
└── README.md
```

**Dependencies:**
- `flutter`
- `evio_core` (path)
- `flutter_riverpod: ^2.6.1`
- `hooks_riverpod: ^2.6.1`
- `flutter_hooks: ^0.20.0`
- `go_router: ^17.0.0`
- `intl: ^0.19.0`
- `uuid: ^4.0.0`
- `image_picker: ^1.0.4`

**Estado:** ~90% completo
- ✅ Auth completo
- ✅ CRUD eventos completo
- ✅ Dashboard con stats reales
- ✅ Settings + user management
- ⏳ Image upload (temporal)
- ⏳ Google Maps (mock)

---

## 📱 EVIO FAN (Mobile App)

```
apps/evio_fan/
├── lib/
│   ├── main.dart                   # Entry point
│   │
│   ├── config/
│   │   └── router.dart             # GoRouter + bottom nav
│   │
│   ├── providers/
│   │   ├── auth_provider.dart          # Auth state
│   │   ├── event_provider.dart         # Events + detail
│   │   ├── ticket_provider.dart        # Tickets del usuario
│   │   └── order_provider.dart         # Orders + cart
│   │
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   │
│   │   ├── home/
│   │   │   ├── home_screen.dart        # ⭐ Home principal
│   │   │   └── widgets/
│   │   │       ├── home_app_bar.dart
│   │   │       ├── hero_event_section.dart     # Auto-scroll
│   │   │       ├── featured_carousel.dart      # Destacados
│   │   │       └── upcoming_events_list.dart   # Próximos
│   │   │
│   │   ├── event_detail/
│   │   │   ├── event_detail_screen.dart # ⭐ Detalle de evento
│   │   │   └── widgets/
│   │   │       ├── event_hero_section.dart
│   │   │       ├── event_content_section.dart
│   │   │       ├── event_lineup.dart
│   │   │       ├── event_info_row.dart
│   │   │       ├── tickets_section.dart
│   │   │       ├── ticket_card.dart
│   │   │       ├── quantity_selector.dart
│   │   │       └── bottom_purchase_cta.dart    # CTA dinámico
│   │   │
│   │   ├── checkout/
│   │   │   └── checkout_screen.dart     # 🚧 En progreso
│   │   │
│   │   ├── search/
│   │   │   └── search_screen.dart       # ⏳ Pendiente
│   │   │
│   │   ├── tickets/
│   │   │   └── tickets_screen.dart      # ⏳ Pendiente (wallet)
│   │   │
│   │   └── profile/
│   │       └── profile_screen.dart      # ⏳ Pendiente
│   │
│   └── widgets/
│       ├── auth/
│       │   └── auth_bottom_sheet.dart   # Sheet de login/register
│       │
│       └── layout/
│           └── fan_layout.dart          # Layout + bottom nav
│
├── pubspec.yaml
└── README.md
```

**Dependencies:**
- `flutter`
- `evio_core` (path)
- `flutter_riverpod: ^2.6.1`
- `state_notifier: ^1.0.0`
- `go_router: ^17.0.0`
- `intl: ^0.19.0`
- `supabase_flutter: ^2.8.0`

**Estado:** ~30% completo
- ✅ Home screen con eventos reales
- ✅ Event detail completo
- ✅ Bottom navigation
- 🚧 Checkout en progreso
- ⏳ Search
- ⏳ Tickets (wallet)
- ⏳ Profile

---

## 🗂️ ROOT

```
evio/
├── packages/       # Código compartido
├── apps/           # Aplicaciones
├── pubspec.yaml    # Workspace config
└── README.md
```

**pubspec.yaml (root):**
```yaml
name: evio
resolution: workspace

environment:
  sdk: ^3.10.0

workspace:
  - packages/evio_core
  - apps/evio_admin
  - apps/evio_fan
```

---

## 📊 RESUMEN

| Módulo | Archivos .dart | Líneas | Estado |
|--------|---------------|---------|--------|
| **evio_core** | ~30 | ~1,000 | 95% ✅ |
| **evio_admin** | ~80 | ~8,000 | 90% ✅ |
| **evio_fan** | ~40 | ~3,000 | 30% 🚧 |
| **TOTAL** | ~150 | ~12,000 | - |

---

## 🔑 ARCHIVOS CLAVE

### evio_core
1. `models/event.dart` - Modelo principal
2. `theme/tokens/colors.dart` - Design system
3. `repositories/event_repository.dart` - Lógica de negocio

### evio_admin
1. `screens/events/event_form_screen.dart` - Crear/editar eventos
2. `models/event_form_state.dart` - Estado del form
3. `widgets/layout/admin_layout.dart` - Layout base
4. `providers/event_providers.dart` - State management

### evio_fan
1. `screens/home/home_screen.dart` - Home principal
2. `screens/event_detail/event_detail_screen.dart` - Detalle
3. `screens/checkout/checkout_screen.dart` - Checkout (WIP)

---

## 🚀 PRÓXIMOS ARCHIVOS A CREAR

1. `apps/evio_fan/lib/screens/checkout/widgets/` - Widgets de checkout
2. `apps/evio_fan/lib/screens/tickets/widgets/` - QR + wallet
3. `apps/evio_admin/lib/screens/statistics/widgets/` - Gráficos
4. `packages/evio_core/lib/services/image_service.dart` - Upload imágenes
5. `packages/evio_core/lib/services/maps_service.dart` - Google Maps
