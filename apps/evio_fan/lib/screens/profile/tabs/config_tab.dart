import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:evio_core/evio_core.dart';
import '../widgets/config_option_tile.dart';

/// Tab de configuración del perfil
class ConfigTab extends ConsumerWidget {
  final User user;

  const ConfigTab({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(EvioSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConfigOptionTile(
            icon: Icons.confirmation_number_outlined,
            title: 'Mis entradas',
            subtitle: 'Ver todas tus entradas',
            onTap: () => context.go('/tickets'),
          ),

          SizedBox(height: EvioSpacing.md),

          ConfigOptionTile(
            icon: Icons.person_outline,
            title: 'Editar perfil',
            subtitle: 'Nombre, email, teléfono, DNI',
            onTap: () => context.push('/profile/edit'),
          ),

          SizedBox(height: EvioSpacing.md),

          ConfigOptionTile(
            icon: Icons.help_outline,
            title: 'Ayuda y soporte',
            subtitle: 'Centro de ayuda',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Próximamente')),
              );
            },
          ),

          SizedBox(height: EvioSpacing.xl),

          // Cerrar sesión
          ConfigOptionTile(
            icon: Icons.logout,
            title: 'Cerrar sesión',
            isDestructive: true,
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      final authRepo = AuthRepository();
      
      await authRepo.signOut().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Timeout al cerrar sesión'),
      );

      if (!context.mounted) return;

      context.go('/home');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesión cerrada'),
          backgroundColor: EvioFanColors.primary,
        ),
      );
    } on TimeoutException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: tiempo de espera agotado'),
          backgroundColor: EvioFanColors.error,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error en logout: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cerrar sesión: $e'),
          backgroundColor: EvioFanColors.error,
        ),
      );
    }
  }
}
