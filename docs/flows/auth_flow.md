# FLUJO: AUTENTICACIÓN

Sistema de auth para evio_admin y evio_fan.

**Última actualización:** 6 Enero 2026

---

## 📋 OVERVIEW

### evio_admin (Web)
- Login/Register con email + password
- Redirect a dashboard post-auth
- Onboarding para crear productora (si producer_id = null)

### evio_fan (Mobile)
- AuthBottomSheet modal (no interrumpe navegación)
- Redirect configurable post-auth
- Acceso parcial sin auth (Home, Search, Event Detail)

---

## 🔐 ARQUITECTURA

```
Supabase Auth (auth.users)
        ↓
    Trigger: handle_new_user()
        ↓
public.users (con producer_id, role)
        ↓
    App Providers
```

---

## 👤 ROLES

| Rol | App | Permisos |
|-----|-----|----------|
| `fan` | evio_fan | Comprar tickets, ver mis tickets |
| `admin` | evio_admin | CRUD completo, gestión productora |
| `collaborator` | evio_admin | Crear/editar eventos, sin eliminar |

---

## 📱 evio_fan: AuthBottomSheet

Modal que preserva el contexto del usuario:

```dart
class AuthBottomSheet extends ConsumerStatefulWidget {
  final String? redirectTo;  // Ruta post-auth
  final String? message;     // Mensaje contextual
  
  // Ejemplo: "Iniciá sesión para comprar tus tickets"
}
```

### Uso

```dart
// En cualquier pantalla que requiera auth
void _onActionRequiringAuth() {
  final user = ref.read(currentUserProvider);
  
  if (user == null) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AuthBottomSheet(
        redirectTo: '/checkout/${event.id}',
        message: 'Iniciá sesión para continuar con tu compra',
      ),
    );
    return;
  }
  
  // Continuar con la acción
}
```

### Flujo interno

```
┌─────────────────────────────────────┐
│  AuthBottomSheet                    │
│  ─────────────────────────────────  │
│                                     │
│  [Tab: Iniciar sesión | Crear cuenta]
│                                     │
│  ┌─────────────────────────────┐    │
│  │ Email                       │    │
│  └─────────────────────────────┘    │
│  ┌─────────────────────────────┐    │
│  │ Contraseña                  │    │
│  └─────────────────────────────┘    │
│                                     │
│  [    Continuar    ]                │
│                                     │
│  ¿Olvidaste tu contraseña?          │
│                                     │
│  ─────── o continuar con ───────    │
│                                     │
│  [Google]  [Apple]                  │
│                                     │
└─────────────────────────────────────┘
```

### Post-auth redirect

```dart
void _onAuthSuccess() {
  Navigator.pop(context);  // Cerrar bottom sheet
  
  if (widget.redirectTo != null) {
    context.push(widget.redirectTo!);
  }
}
```

---

## 💻 evio_admin: Auth Screens

### Login Screen

```dart
// Ruta: /login
class LoginScreen extends ConsumerStatefulWidget {
  // Email + Password
  // Link a Register
  // Link a Reset Password
  // Redirect a /dashboard post-login
}
```

### Register Screen

```dart
// Ruta: /register
class RegisterScreen extends ConsumerStatefulWidget {
  // Nombre + Apellido + Email + Password
  // Rol automático: admin
  // producer_id: null (completar en onboarding)
}
```

### Onboarding

Si `user.producer_id == null` después de login:

```dart
// Mostrar ProducerOnboardingDialog
- Nombre de la productora
- Logo (opcional)
- Email de contacto

// Al completar:
1. Crear Producer en DB
2. Actualizar user.producer_id
3. Redirect a dashboard
```

---

## 🗄️ BASE DE DATOS

### Trigger: handle_new_user()

Cuando se crea un usuario en `auth.users`:

```sql
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Crear registro en public.users
  INSERT INTO public.users (
    id,
    auth_provider_id,
    email,
    role
  ) VALUES (
    gen_random_uuid(),
    NEW.id::TEXT,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'role', 'fan')
  );
  
  -- Buscar invitación pendiente
  UPDATE user_invitations SET status = 'accepted'
  WHERE email = NEW.email AND status = 'pending';
  
  -- Asociar con productor si hay invitación
  UPDATE public.users SET 
    producer_id = (SELECT producer_id FROM user_invitations WHERE email = NEW.email AND status = 'accepted' LIMIT 1),
    role = (SELECT role FROM user_invitations WHERE email = NEW.email AND status = 'accepted' LIMIT 1)
  WHERE auth_provider_id = NEW.id::TEXT;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 🔄 PROVIDERS

### AuthStateProvider

```dart
final authStateProvider = StreamProvider<AuthState>((ref) {
  return supabase.auth.onAuthStateChange;
});
```

### CurrentUserProvider

```dart
final currentUserProvider = FutureProvider<User?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final session = authState.value?.session;
  
  if (session == null) return null;
  
  // Obtener usuario de public.users
  final data = await supabase
    .from('users')
    .select()
    .eq('auth_provider_id', session.user.id)
    .single();
  
  return User.fromJson(data);
});
```

### AuthNotifier

```dart
class AuthNotifier extends StateNotifier<AuthUIState> {
  Future<void> signIn(String email, String password);
  Future<void> signUp(String email, String password, {String? firstName, String? lastName});
  Future<void> signOut();
  Future<void> resetPassword(String email);
}
```

---

## 🛡️ GUARDS

### evio_admin Router

```dart
GoRouter(
  redirect: (context, state) {
    final isLoggedIn = authState.value?.session != null;
    final isAuthRoute = state.matchedLocation.startsWith('/login') ||
                        state.matchedLocation.startsWith('/register');
    
    if (!isLoggedIn && !isAuthRoute) {
      return '/login';
    }
    
    if (isLoggedIn && isAuthRoute) {
      return '/dashboard';
    }
    
    return null;
  },
)
```

### evio_fan: Tabs protegidos

```dart
// En FanLayout
void _onTabSelected(int index) {
  final user = ref.read(currentUserProvider);
  
  // Tabs 2 (Tickets) y 3 (Profile) requieren auth
  if ((index == 2 || index == 3) && user == null) {
    showModalBottomSheet(
      context: context,
      builder: (_) => AuthBottomSheet(
        message: index == 2 
          ? 'Iniciá sesión para ver tus tickets'
          : 'Iniciá sesión para ver tu perfil',
      ),
    );
    return;
  }
  
  setState(() => _currentIndex = index);
}
```

---

## 📍 ARCHIVOS RELACIONADOS

### evio_admin
```
apps/evio_admin/lib/
├── screens/auth/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   └── reset_password_screen.dart
├── screens/onboarding/
│   └── ...
├── providers/
│   ├── auth_provider.dart
│   └── onboarding_provider.dart
└── config/
    └── router.dart
```

### evio_fan
```
apps/evio_fan/lib/
├── screens/auth/
│   ├── login_screen.dart
│   └── register_screen.dart
├── widgets/auth/
│   └── auth_bottom_sheet.dart
├── providers/
│   └── auth_provider.dart
└── config/
    └── router.dart
```

---

## ⚠️ CONSIDERACIONES

### Persistencia de sesión
- Supabase maneja automáticamente con `SharedPreferences`
- Sesión persiste entre reinicios de app

### Error handling
```dart
try {
  await supabase.auth.signInWithPassword(email: email, password: password);
} on AuthException catch (e) {
  // "Invalid login credentials"
  // "Email not confirmed"
  // etc
}
```

### Deep linking (pendiente)
- Magic links para reset password
- OAuth callbacks (Google, Apple)
