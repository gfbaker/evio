import 'package:flutter/material.dart';
import 'package:evio_core/evio_core.dart';

/// Tile reutilizable para opciones de configuración
class ConfigOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const ConfigOptionTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(EvioRadius.card),
      child: Container(
        padding: EdgeInsets.all(EvioSpacing.md),
        decoration: BoxDecoration(
          color: EvioFanColors.surface,
          borderRadius: BorderRadius.circular(EvioRadius.card),
          border: Border.all(color: EvioFanColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(EvioSpacing.sm),
              decoration: BoxDecoration(
                color: isDestructive
                    ? EvioFanColors.error.withValues(alpha: 0.1)
                    : EvioFanColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(EvioRadius.button),
              ),
              child: Icon(
                icon,
                color: isDestructive ? EvioFanColors.error : EvioFanColors.primary,
                size: 22,
              ),
            ),
            SizedBox(width: EvioSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: EvioTypography.bodyLarge.copyWith(
                      color: isDestructive
                          ? EvioFanColors.error
                          : EvioFanColors.foreground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: EvioTypography.bodySmall.copyWith(
                        color: EvioFanColors.mutedForeground,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: EvioFanColors.mutedForeground,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
