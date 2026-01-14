import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:evio_core/evio_core.dart';
import '../../providers/auth_provider.dart';
import '../auth/auth_bottom_sheet.dart';

class FanLayout extends StatelessWidget {
  final Widget child;

  const FanLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EvioFanColors.background,
      extendBody: true, // ✅ Permite que el body se extienda debajo del navbar
      body: child,
      bottomNavigationBar: const _FanBottomNav(),
    );
  }
}

// ✅ Convertir a ConsumerWidget para acceder a ref
class _FanBottomNav extends ConsumerWidget {
  const _FanBottomNav();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocation = GoRouterState.of(context).uri.path;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: EvioSpacing.lg,
          right: EvioSpacing.lg,
          bottom: EvioSpacing.md,
        ),
        child: Container(
          height: 68,
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: EvioFanColors.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(EvioRadius.button + 6),
            border: Border.all(
              color: EvioFanColors.border.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isActive: currentLocation == '/home',
                onTap: () {
                  if (!context.mounted) return;
                  context.go('/home');
                },
              ),
              _NavItem(
                icon: Icons.search_rounded,
                label: 'Explorar',
                isActive: currentLocation == '/search',
                onTap: () {
                  if (!context.mounted) return;
                  context.go('/search');
                },
              ),
              _NavItem(
                icon: Icons.confirmation_number_rounded,
                label: 'Tickets',
                isActive: currentLocation == '/tickets',
                onTap: () {
                  if (!context.mounted) return;
                  
                  // ✅ Auth guard para Tickets con try-catch
                  try {
                    final isAuthenticated = ref.read(isAuthenticatedProvider);

                    if (!isAuthenticated) {
                      AuthBottomSheet.show(context, redirectTo: '/tickets');
                      return;
                    }

                    context.go('/tickets');
                  } catch (e) {
                    debugPrint('❌ Error en navegación a Tickets: $e');
                    // Fallback: intentar navegar igual
                    context.go('/tickets');
                  }
                },
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Perfil',
                isActive: currentLocation == '/profile',
                onTap: () {
                  if (!context.mounted) return;
                  
                  // ✅ Auth guard para Profile con try-catch
                  try {
                    final isAuthenticated = ref.read(isAuthenticatedProvider);

                    if (!isAuthenticated) {
                      AuthBottomSheet.show(context, redirectTo: '/profile');
                      return;
                    }

                    context.go('/profile');
                  } catch (e) {
                    debugPrint('❌ Error en navegación a Profile: $e');
                    // Fallback: intentar navegar igual
                    context.go('/profile');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: EdgeInsets.symmetric(horizontal: 2), // Separación entre items
          decoration: BoxDecoration(
            color: isActive 
                ? EvioFanColors.muted.withValues(alpha: 0.4) // Gris mate transparente
                : Colors.transparent,
            borderRadius: BorderRadius.circular(EvioRadius.button),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isActive
                      ? EvioFanColors.primary // Amarillo cuando está activo
                      : EvioFanColors.mutedForeground, // Gris cuando no está activo
                ),
                SizedBox(height: 4),
                Text(
                  label,
                  style: EvioTypography.labelSmall.copyWith(
                    color: isActive
                        ? EvioFanColors.primary // Amarillo cuando está activo
                        : EvioFanColors.mutedForeground, // Gris cuando no está activo
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
