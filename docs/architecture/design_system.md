# DESIGN SYSTEM - EVIO CLUB

## 🎨 PRINCIPIO FUNDAMENTAL

**❌ NUNCA HARDCODEAR valores de diseño**

Todo color, spacing, radius y typography DEBE venir de tokens centralizados en `evio_core`.

---

## 📦 IMPORT OBLIGATORIO

```dart
import 'package:evio_core/evio_core.dart';
```

Este import da acceso a:
- `EvioLightColors` (admin)
- `EvioFanColors` (fan)
- `EvioSpacing`
- `EvioRadius`
- `EvioTypography`

---

## 🎨 COLORES

### EvioLightColors (Admin - Tema Claro)

```dart
// Backgrounds
EvioLightColors.background     // #FFFFFF
EvioLightColors.surface        // #F3F3F5
EvioLightColors.surfaceVariant // #ECECF0

// Primary
EvioLightColors.primary           // #030213 (casi negro)
EvioLightColors.primaryForeground // #FBFBFB (casi blanco)

// Text
EvioLightColors.textPrimary    // #252525
EvioLightColors.textSecondary  // #717182
EvioLightColors.textTertiary   // #9CA3AF

// Borders
EvioLightColors.border         // #EBEBEB
EvioLightColors.borderSubtle   // rgba(0,0,0,0.05)

// Semantic
EvioLightColors.success     // #22C55E (verde)
EvioLightColors.warning     // #FBBF24 (amarillo)
EvioLightColors.error       // #D4183D (rojo)
EvioLightColors.info        // #3B82F6 (azul)

// Card
EvioLightColors.card           // #FFFFFF
EvioLightColors.cardForeground // #030213

// Sidebar (Admin específico)
EvioLightColors.sidebar        // #FBFBFB
EvioLightColors.sidebarAccent  // #F8F8F8 (hover)
EvioLightColors.sidebarBorder  // #EBEBEB

// Progress bars (dinámico según porcentaje)
EvioLightColors.progressLow    // #10B981 (0-39%)
EvioLightColors.progressMedium // #3B82F6 (40-69%)
EvioLightColors.progressHigh   // #F59E0B (70-89%)
EvioLightColors.progressFull   // #EF4444 (90-100%)

// Status badges
EvioLightColors.statusUpcoming  // #3B82F6 (azul)
EvioLightColors.statusOngoing   // #10B981 (verde)
EvioLightColors.statusCompleted // #6B7280 (gris)
EvioLightColors.statusCancelled // #EF4444 (rojo)

// Revenue
EvioLightColors.revenuePositive // #16A34A (verde oscuro)
EvioLightColors.revenuePending  // #EA580C (naranja)
```

### EvioFanColors (Fan - Tema Oscuro + Amarillo)

```dart
// Primary - Amarillo dorado (acento principal)
EvioFanColors.primary           // #FFC107
EvioFanColors.primaryForeground // #000000

// Backgrounds
EvioFanColors.background      // #0A0A0A (negro profundo)
EvioFanColors.surface         // #1E1E1E (cards/modals)
EvioFanColors.surfaceVariant  // #2C2C2C (elevated)

// Text
EvioFanColors.foreground       // #FFFFFF
EvioFanColors.mutedForeground  // #9E9E9E
EvioFanColors.textTertiary     // #6B7280

// Borders
EvioFanColors.border       // #3A3A3A
EvioFanColors.borderSubtle // #2C2C2C

// Accent - Dorado para badges/highlights
EvioFanColors.accent           // #FFD700
EvioFanColors.accentForeground // #000000

// Semantic
EvioFanColors.success     // #32D74B
EvioFanColors.warning     // #FFD60A
EvioFanColors.error       // #FF453A
EvioFanColors.info        // #0A84FF

// Card
EvioFanColors.card           // #1E1E1E
EvioFanColors.cardForeground // #FFFFFF

// Bottom Nav
EvioFanColors.activeTab           // #FFC107 (amarillo)
EvioFanColors.activeTabForeground // #000000
EvioFanColors.inactiveTab         // #9E9E9E
```

---

## 📏 SPACING

```dart
EvioSpacing.xxs  // 4px
EvioSpacing.xs   // 8px
EvioSpacing.sm   // 12px
EvioSpacing.md   // 16px
EvioSpacing.lg   // 24px
EvioSpacing.xl   // 32px
EvioSpacing.xxl  // 48px

// Layout específicos
EvioSpacing.buttonHeight   // 44px
EvioSpacing.sidebarWidth   // 256px

// Icons
EvioSpacing.iconXS  // 12px
EvioSpacing.iconS   // 16px
EvioSpacing.iconM   // 20px
EvioSpacing.iconL   // 24px
EvioSpacing.iconXL  // 32px
```

### Uso Común

```dart
// Padding
padding: EdgeInsets.all(EvioSpacing.md)
padding: EdgeInsets.symmetric(
  horizontal: EvioSpacing.lg,
  vertical: EvioSpacing.sm,
)

// Gap (Column/Row)
Column(
  children: [
    Widget1(),
    SizedBox(height: EvioSpacing.lg),
    Widget2(),
  ],
)

// Margins
margin: EdgeInsets.only(bottom: EvioSpacing.xl)
```

---

## 🔘 RADIUS

```dart
EvioRadius.button  // 10px
EvioRadius.card    // 12px
EvioRadius.input   // 10px
```

### Uso

```dart
// Botones
decoration: BoxDecoration(
  borderRadius: BorderRadius.circular(EvioRadius.button),
)

// Cards
decoration: BoxDecoration(
  borderRadius: BorderRadius.circular(EvioRadius.card),
)

// Inputs
decoration: BoxDecoration(
  borderRadius: BorderRadius.circular(EvioRadius.input),
)
```

---

## 📝 TYPOGRAPHY

```dart
// Headings
EvioTypography.h1  // 32px, bold
EvioTypography.h2  // 24px, bold
EvioTypography.h3  // 20px, semibold
EvioTypography.h4  // 18px, semibold

// Body
EvioTypography.bodyLarge   // 16px, regular
EvioTypography.bodyMedium  // 14px, regular
EvioTypography.bodySmall   // 12px, regular

// Label
EvioTypography.labelLarge   // 14px, medium
EvioTypography.labelMedium  // 12px, medium
EvioTypography.labelSmall   // 11px, medium

// Otros
EvioTypography.button  // 14px, semibold
EvioTypography.caption // 12px, regular
```

### Uso

```dart
Text(
  'Título Principal',
  style: EvioTypography.h1,
)

Text(
  'Descripción del evento',
  style: EvioTypography.bodyMedium.copyWith(
    color: EvioLightColors.textSecondary,
  ),
)

ElevatedButton(
  child: Text('Comprar', style: EvioTypography.button),
)
```

---

## 🎭 THEMES

### Admin Theme (Light)

```dart
// apps/evio_admin/lib/main.dart
MaterialApp.router(
  theme: ThemeData(
    colorScheme: ColorScheme.light(
      primary: EvioLightColors.primary,
      surface: EvioLightColors.surface,
      error: EvioLightColors.error,
    ),
    scaffoldBackgroundColor: EvioLightColors.background,
    // ...resto de configuración
  ),
)
```

### Fan Theme (Dark + Yellow Accent)

```dart
// apps/evio_fan/lib/main.dart
MaterialApp.router(
  theme: ThemeData(
    colorScheme: ColorScheme.dark(
      primary: EvioFanColors.primary,
      surface: EvioFanColors.surface,
      background: EvioFanColors.background,
    ),
    scaffoldBackgroundColor: EvioFanColors.background,
    // ...resto de configuración
  ),
)
```

---

## ✅ EJEMPLOS COMPLETOS

### Card con Tokens

```dart
Container(
  padding: EdgeInsets.all(EvioSpacing.lg),
  decoration: BoxDecoration(
    color: EvioLightColors.card,
    borderRadius: BorderRadius.circular(EvioRadius.card),
    border: Border.all(
      color: EvioLightColors.border,
      width: 1,
    ),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Título', style: EvioTypography.h3),
      SizedBox(height: EvioSpacing.sm),
      Text(
        'Descripción',
        style: EvioTypography.bodyMedium.copyWith(
          color: EvioLightColors.textSecondary,
        ),
      ),
    ],
  ),
)
```

### Button con Tokens

```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: EvioLightColors.primary,
    foregroundColor: EvioLightColors.primaryForeground,
    padding: EdgeInsets.symmetric(
      horizontal: EvioSpacing.lg,
      vertical: EvioSpacing.md,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(EvioRadius.button),
    ),
    minimumSize: Size.fromHeight(EvioSpacing.buttonHeight),
  ),
  onPressed: () {},
  child: Text('Crear Evento', style: EvioTypography.button),
)
```

### Input con Tokens

```dart
TextFormField(
  decoration: InputDecoration(
    filled: true,
    fillColor: EvioLightColors.inputBackground,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(EvioRadius.input),
      borderSide: BorderSide(color: EvioLightColors.border),
    ),
    contentPadding: EdgeInsets.symmetric(
      horizontal: EvioSpacing.md,
      vertical: EvioSpacing.sm,
    ),
  ),
  style: EvioTypography.bodyMedium,
)
```

---

## 🚫 ANTI-PATTERNS

### ❌ NO HACER

```dart
// Hardcoded colors
Container(color: Color(0xFFFFFFFF))
Container(color: Colors.white)

// Hardcoded spacing
Padding(padding: EdgeInsets.all(16))
SizedBox(height: 24)

// Hardcoded radius
BorderRadius.circular(12)

// Hardcoded typography
TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
```

### ✅ SÍ HACER

```dart
// Tokens everywhere
Container(color: EvioLightColors.card)
Padding(padding: EdgeInsets.all(EvioSpacing.md))
BorderRadius.circular(EvioRadius.card)
Text('Hola', style: EvioTypography.bodyMedium)
```

---

## 🔄 ACTUALIZAR TOKENS

Si necesitas agregar un nuevo color, spacing o estilo:

1. **Editar el archivo de tokens:**
   ```dart
   // packages/evio_core/lib/theme/tokens/colors.dart
   abstract class EvioLightColors {
     static const Color myNewColor = Color(0xFF123456);
   }
   ```

2. **Exportar en evio_core.dart:**
   ```dart
   export 'theme/tokens/colors.dart';
   ```

3. **Usar en apps:**
   ```dart
   Container(color: EvioLightColors.myNewColor)
   ```

**NUNCA** agregues tokens específicos de una app en evio_core. Solo tokens compartibles.

---

## 📍 UBICACIÓN DE ARCHIVOS

```
packages/evio_core/lib/theme/
├── tokens/
│   ├── colors.dart      # EvioLightColors, EvioDarkColors, EvioFanColors
│   ├── spacing.dart     # EvioSpacing
│   ├── radius.dart      # EvioRadius
│   ├── typography.dart  # EvioTypography
│   └── gradients.dart   # EvioGradients (opcional)
├── evio_theme.dart      # ThemeData completo
└── theme.dart           # Re-exports
```

---

## 🎯 RESUMEN

1. **SIEMPRE** importar `evio_core`
2. **NUNCA** hardcodear valores de diseño
3. **USAR** tokens para: colors, spacing, radius, typography
4. **VALIDAR** antes de commit: buscar `Color(0x`, `EdgeInsets.all(`, `BorderRadius.circular(`
