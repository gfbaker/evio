import 'package:flutter/material.dart';
import 'package:evio_core/evio_core.dart';

/// Estado vacío minimalista
class NotificationEmptyState extends StatelessWidget {
  const NotificationEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(EvioSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo EVIO grande
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: EvioFanColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  'E',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: EvioFanColors.primary,
                    height: 1,
                  ),
                ),
              ),
            ),
            SizedBox(height: EvioSpacing.xl),
            Text(
              'Sin notificaciones',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: EvioFanColors.foreground,
              ),
            ),
            SizedBox(height: EvioSpacing.xs),
            Text(
              'Las novedades de tus eventos\naparecerán acá',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: EvioFanColors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
