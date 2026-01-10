# ESTRUCTURA DEL PROYECTO

Árbol completo de archivos del monorepo Evio.

**Última actualización:** 6 Enero 2026

---

## 📦 MONOREPO

```
evio/
├── packages/evio_core/       # Shared: models, repos, theme, services
├── apps/evio_admin/          # Web dashboard (productores)
├── apps/evio_fan/            # Mobile app (fans)
└── pubspec.yaml              # Workspace config
```

---

## packages/evio_core/

```
packages/evio_core/lib/
├── evio_core.dart              # Export principal
│
├── config/
│   └── supabase_config.dart
│
├── constants/
│   ├── app_constants.dart
│   └── enums.dart              # UserRole, TicketStatus, OrderStatus, etc
│
├── exceptions/
│   └── ...
│
├── models/
│   ├── event.dart
│   ├── event_stats.dart
│   ├── event_status.dart
│   ├── lineup_artist.dart
│   ├── ticket_category.dart       # Freezed
│   ├── ticket_category.freezed.dart
│   ├── ticket_category.g.dart
│   ├── ticket_tier.dart           # Freezed
│   ├── ticket_tier.freezed.dart
│   ├── ticket_tier.g.dart
│   ├── ticket.dart
│   ├── order.dart
│   ├── order_item.dart
│   ├── user.dart
│   ├── producer.dart
│   ├── user_invitation.dart
│   └── coupon.dart
│
├── repositories/
│   ├── auth_repository.dart
│   ├── event_repository.dart
│   ├── ticket_repository.dart
│   ├── order_repository.dart
│   ├── user_repository.dart
│   ├── producer_repository.dart
│   └── coupon_repository.dart
│
├── services/
│   ├── supabase_service.dart      # Singleton client
│   ├── storage_service.dart       # Supabase Storage (imágenes)
│   ├── image_processor.dart       # Thumbnails 300/600/full
│   ├── spotify_service.dart       # Artist images
│   └── youtube_service.dart       # Video embeds
│
├── theme/
│   ├── evio_theme.dart
│   ├── theme.dart
│   └── tokens/
│       ├── colors.dart            # EvioLightColors, EvioFanColors
│       ├── spacing.dart           # EvioSpacing
│       ├── radius.dart            # EvioRadius
│       ├── typography.dart        # EvioTypography
│       └── gradients.dart
│
└── utils/
    ├── currency_formatter.dart
    └── progress_color.dart
```

---

## apps/evio_admin/

```
apps/evio_admin/lib/
├── main.dart
│
├── config/
│   └── router.dart                # GoRouter + ShellRoute
│
├── models/
│   └── event_form_state.dart
│
├── providers/
│   ├── auth_provider.dart
│   ├── event_providers.dart       # Events + form + stats
│   ├── onboarding_provider.dart
│   ├── settings_provider.dart
│   ├── storage_provider.dart      # Image upload
│   └── spotify_provider.dart
│
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   └── reset_password_screen.dart
│   │
│   ├── dashboard/
│   │   └── dashboard_screen.dart
│   │
│   ├── events/
│   │   ├── event_list_screen.dart
│   │   ├── event_detail_screen.dart
│   │   └── event_form_screen.dart
│   │
│   ├── onboarding/
│   │   └── ...
│   │
│   ├── settings/
│   │   ├── settings_screen.dart
│   │   ├── profile_screen.dart
│   │   ├── company_screen.dart
│   │   └── users_screen.dart
│   │
│   └── statistics/
│       └── statistics_screen.dart
│
└── widgets/
    ├── common/
    │   ├── custom_dropdown.dart
    │   ├── date_picker_field.dart
    │   ├── time_picker_field.dart
    │   ├── floating_snackbar.dart
    │   ├── form_card.dart
    │   ├── label_input.dart
    │   └── stat_card.dart
    │
    ├── event_form/
    │   ├── form_details_card.dart
    │   ├── form_location_card.dart
    │   ├── form_lineup_card.dart
    │   ├── form_capacity_pricing_card.dart
    │   ├── form_features_card.dart
    │   ├── form_poster_card.dart
    │   ├── form_header.dart
    │   ├── live_preview_card.dart
    │   ├── image_cropper_dialog.dart
    │   └── map_picker_dialog.dart
    │
    ├── events/
    │   ├── event_card.dart
    │   └── event_list_item.dart
    │
    └── layout/
        ├── admin_layout.dart
        └── admin_sidebar.dart
```

---

## apps/evio_fan/

```
apps/evio_fan/lib/
├── main.dart
│
├── config/
│   └── router.dart                # GoRouter + bottom nav
│
├── providers/
│   ├── auth_provider.dart
│   ├── event_provider.dart
│   ├── ticket_provider.dart
│   ├── order_provider.dart
│   ├── checkout_provider.dart
│   ├── search_providers.dart
│   ├── location_provider.dart
│   ├── spotify_provider.dart
│   └── youtube_provider.dart
│
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   │
│   ├── splash/
│   │   └── ...
│   │
│   ├── home/
│   │   ├── home_screen.dart
│   │   └── widgets/
│   │       ├── home_app_bar.dart
│   │       ├── hero_event_section.dart
│   │       ├── featured_carousel.dart
│   │       └── upcoming_events_list.dart
│   │
│   ├── event_detail/
│   │   ├── event_detail_screen.dart
│   │   └── widgets/
│   │       ├── event_hero_section.dart
│   │       ├── event_content_section.dart
│   │       ├── event_lineup.dart
│   │       ├── tickets_section.dart
│   │       ├── ticket_card.dart
│   │       ├── quantity_selector.dart
│   │       └── bottom_purchase_cta.dart
│   │
│   ├── checkout/
│   │   └── checkout_screen.dart
│   │
│   ├── search/
│   │   └── search_screen.dart
│   │
│   ├── tickets/
│   │   ├── tickets_screen.dart
│   │   └── ticket_detail_screen.dart    # QR + diseño custom
│   │
│   └── profile/
│       └── profile_screen.dart
│
└── widgets/
    ├── auth/
    │   └── auth_bottom_sheet.dart      # Login/Register modal
    │
    ├── layout/
    │   └── fan_layout.dart             # Bottom nav
    │
    ├── shimmer/
    │   └── ...
    │
    ├── cached_event_image.dart         # Con thumbnails
    └── ticket_card.dart
```

---

## 📊 RESUMEN

| Módulo | Estado | Descripción |
|--------|--------|-------------|
| **evio_core** | 95% ✅ | Models, repos, services, theme completos |
| **evio_admin** | 90% ✅ | Auth, CRUD eventos, settings, stats, image upload |
| **evio_fan** | 75% ✅ | Home, Detail, Checkout, Tickets (QR), Auth flow |

---

## 🔑 ARCHIVOS CLAVE

### evio_core
- `models/ticket_category.dart` - Categorías (Freezed)
- `models/ticket_tier.dart` - Tandas (Freezed)
- `services/storage_service.dart` - Upload + thumbnails
- `theme/tokens/colors.dart` - Design system

### evio_admin
- `screens/events/event_form_screen.dart` - Crear/editar
- `providers/event_providers.dart` - State management
- `widgets/layout/admin_layout.dart` - Shell con sidebar

### evio_fan
- `screens/tickets/ticket_detail_screen.dart` - QR + diseño custom
- `screens/checkout/checkout_screen.dart` - Flow de compra
- `widgets/auth/auth_bottom_sheet.dart` - Auth modal
- `widgets/cached_event_image.dart` - Imágenes optimizadas
