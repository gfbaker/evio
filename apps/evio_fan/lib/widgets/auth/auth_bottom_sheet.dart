import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:evio_core/evio_core.dart';

class AuthBottomSheet extends StatelessWidget {
  final String redirectTo;

  const AuthBottomSheet({super.key, required this.redirectTo});

  static Future<void> show(BuildContext context, {required String redirectTo}) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AuthBottomSheet(redirectTo: redirectTo),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(EvioSpacing.lg),
      decoration: BoxDecoration(
        color: EvioFanColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(EvioRadius.card),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle visual
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: EvioFanColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: EvioSpacing.lg),

            // Icon
            Container(
              padding: EdgeInsets.all(EvioSpacing.md),
              decoration: BoxDecoration(
                color: EvioFanColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                size: 48,
                color: EvioFanColors.primary,
              ),
            ),
            SizedBox(height: EvioSpacing.lg),

            // Title
            Text(
              'Necesitás una cuenta',
              style: EvioTypography.h3.copyWith(
                color: EvioFanColors.foreground,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: EvioSpacing.sm),

            // Subtitle - Genérico
            Text(
              'Ingresá o creá una cuenta para continuar',
              style: EvioTypography.bodyMedium.copyWith(
                color: EvioFanColors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: EvioSpacing.xl),

            // Botón Ingresar
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // ✅ Pasar redirectTo como query parameter
                  context.push('/auth/login?redirect=$redirectTo');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: EvioFanColors.primary,
                  foregroundColor: EvioFanColors.primaryForeground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(EvioRadius.button),
                  ),
                ),
                child: Text('Ingresar', style: EvioTypography.button),
              ),
            ),
            SizedBox(height: EvioSpacing.sm),

            // Botón Crear cuenta
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // ✅ Pasar redirectTo como query parameter
                  context.push('/auth/register?redirect=$redirectTo');
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: EvioFanColors.border),
                  foregroundColor: EvioFanColors.foreground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(EvioRadius.button),
                  ),
                ),
                child: Text('Crear cuenta', style: EvioTypography.button),
              ),
            ),
            SizedBox(height: EvioSpacing.sm),

            // Botón Cancelar
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Ahora no',
                style: EvioTypography.labelMedium.copyWith(
                  color: EvioFanColors.mutedForeground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
