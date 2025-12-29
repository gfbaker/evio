import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ currentAuthUserProvider retorna User? directamente, no AsyncValue
    final currentUser = ref.watch(currentAuthUserProvider);

    return Scaffold(
      backgroundColor: EvioFanColors.background,
      appBar: AppBar(
        backgroundColor: EvioFanColors.background,
        elevation: 0,
        title: Text(
          'Perfil',
          style: EvioTypography.h3.copyWith(color: EvioFanColors.foreground),
        ),
      ),
      body: currentUser == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_off_outlined,
                    size: 64,
                    color: EvioFanColors.mutedForeground,
                  ),
                  SizedBox(height: EvioSpacing.lg),
                  Text(
                    'No hay sesión activa',
                    style: EvioTypography.h4.copyWith(
                      color: EvioFanColors.foreground,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(EvioSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: EvioFanColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        size: 40,
                        color: EvioFanColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(height: EvioSpacing.lg),

                  // Email
                  Center(
                    child: Text(
                      currentUser.email ?? 'Sin email',
                      style: EvioTypography.h4.copyWith(
                        color: EvioFanColors.foreground,
                      ),
                    ),
                  ),
                  SizedBox(height: EvioSpacing.xl),

                  // Opciones
                  _buildOption(
                    context,
                    icon: Icons.edit_outlined,
                    title: 'Editar perfil',
                    onTap: () {
                      // TODO: Implementar edición de perfil
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Próximamente')),
                      );
                    },
                  ),
                  _buildOption(
                    context,
                    icon: Icons.notifications_outlined,
                    title: 'Notificaciones',
                    onTap: () {
                      // TODO: Implementar configuración de notificaciones
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Próximamente')),
                      );
                    },
                  ),
                  _buildOption(
                    context,
                    icon: Icons.help_outline,
                    title: 'Ayuda',
                    onTap: () {
                      // TODO: Implementar ayuda
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Próximamente')),
                      );
                    },
                  ),
                  _buildOption(
                    context,
                    icon: Icons.logout,
                    title: 'Cerrar sesión',
                    onTap: () async {
                      final authRepo = AuthRepository();
                      await authRepo.signOut();

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sesión cerrada'),
                            backgroundColor: EvioFanColors.primary,
                          ),
                        );
                      }
                    },
                    isDestructive: true,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: EvioSpacing.md,
          horizontal: EvioSpacing.lg,
        ),
        margin: EdgeInsets.only(bottom: EvioSpacing.sm),
        decoration: BoxDecoration(
          color: EvioFanColors.surface,
          borderRadius: BorderRadius.circular(EvioRadius.card),
          border: Border.all(color: EvioFanColors.border),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive
                  ? EvioFanColors.error
                  : EvioFanColors.foreground,
              size: EvioSpacing.iconM,
            ),
            SizedBox(width: EvioSpacing.md),
            Expanded(
              child: Text(
                title,
                style: EvioTypography.bodyLarge.copyWith(
                  color: isDestructive
                      ? EvioFanColors.error
                      : EvioFanColors.foreground,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: EvioFanColors.mutedForeground,
              size: EvioSpacing.iconM,
            ),
          ],
        ),
      ),
    );
  }
}
