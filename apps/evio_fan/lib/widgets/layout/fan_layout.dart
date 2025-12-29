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

    return Container(
      decoration: BoxDecoration(
        color: EvioFanColors.surface,
        border: Border(
          top: BorderSide(color: EvioFanColors.border, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isActive: currentLocation == '/home',
                onTap: () => context.go('/home'),
              ),
              _NavItem(
                icon: Icons.search_rounded,
                label: 'Explorar',
                isActive: currentLocation == '/search',
                onTap: () => context.go('/search'),
              ),
              _NavItem(
                icon: Icons.confirmation_number_rounded,
                label: 'Tickets',
                isActive: currentLocation == '/tickets',
                onTap: () {
                  // ✅ Auth guard para Tickets
                  final isAuthenticated = ref.read(isAuthenticatedProvider);

                  if (!isAuthenticated) {
                    AuthBottomSheet.show(context, redirectTo: '/tickets');
                    return;
                  }

                  context.go('/tickets');
                },
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Perfil',
                isActive: currentLocation == '/profile',
                onTap: () {
                  // ✅ Auth guard para Profile
                  final isAuthenticated = ref.read(isAuthenticatedProvider);

                  if (!isAuthenticated) {
                    AuthBottomSheet.show(context, redirectTo: '/profile');
                    return;
                  }

                  context.go('/profile');
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
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: EvioSpacing.xs),
          decoration: BoxDecoration(
            color: isActive ? EvioFanColors.activeTab : Colors.transparent,
            borderRadius: BorderRadius.circular(EvioRadius.button),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: EvioSpacing.iconSize,
                color: isActive
                    ? EvioFanColors.activeTabForeground
                    : EvioFanColors.inactiveTab,
              ),
              SizedBox(height: EvioSpacing.xxs),
              Text(
                label,
                style: EvioTypography.labelSmall.copyWith(
                  color: isActive
                      ? EvioFanColors.activeTabForeground
                      : EvioFanColors.inactiveTab,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
